import { badRequest, conflict, notFound } from '../../utils/errors.js';
import { escapeLike } from '../../utils/query.js';
import { todayIn } from '../../utils/time.js';
import { getTask, setSubtaskDone } from '../tasks/tasks.service.js';

/*
 * 1-3-5 planner: each user plans a day as 1 big, 3 medium and 5 small items (positions 1–9).
 * An item is a task assigned to the user, a subtask assigned to them, or a short free text.
 * A task always goes on its assignee's 1-3-5: the assignee adds it, or the project owner (the task owner
 * for tasks without a project) plans it for them ("added by").
 * Tasks: done / time are the planner's own – the task status is never changed.
 * Subtasks: done IS the subtask's done (ticking it here ticks the subtask, and the other way round).
 * Positions are kept 1..n without gaps.
 */

export const SLOTS = 9;

const SELECT = `
  SELECT i.id, i.plan_date, i.position, i.task_id, i.subtask_id, i.title, i.minutes, i.done_at,
         CASE WHEN i.subtask_id IS NOT NULL THEN s.is_done ELSE i.is_done END AS is_done,
         COALESCE(t.id, st.id) AS link_task_id, st.name AS parent_task_name,
         t.status AS task_status, COALESCE(t.priority, st.priority) AS task_priority,
         p.id AS project_id, p.code AS project_code, p.title AS project_title, s.due_date AS subtask_due,
         i.user_id, i.created_by, cu.name AS created_by_name, ou.name AS user_name,
         tc.id AS category_id, tc.name AS category_name
    FROM task_135_items i
    LEFT JOIN users cu ON cu.id = i.created_by
    LEFT JOIN users ou ON ou.id = i.user_id
    LEFT JOIN tasks t ON t.id = i.task_id
    LEFT JOIN task_subtasks s ON s.id = i.subtask_id
    LEFT JOIN tasks st ON st.id = s.task_id
    LEFT JOIN projects p ON p.id = COALESCE(t.project_id, st.project_id)
    LEFT JOIN task_categories tc ON tc.id = COALESCE(t.task_category_id, st.task_category_id)`;

const toDto = (r) => ({
  id: r.id,
  date: r.plan_date,
  position: r.position,
  size: r.position === 1 ? 'big' : r.position <= 4 ? 'medium' : 'small',
  kind: r.subtask_id ? 'subtask' : r.task_id ? 'task' : 'note',
  taskId: r.task_id,
  subtaskId: r.subtask_id,
  linkTaskId: r.link_task_id, // the task page to open (the parent task for a subtask)
  parentTaskName: r.parent_task_name,
  title: r.title,
  minutes: r.minutes,
  isDone: r.is_done,
  doneAt: r.done_at,
  taskStatus: r.task_status,
  taskPriority: r.task_priority,
  projectId: r.project_id,
  categoryId: r.category_id, // the task's category (Project, Personal, Activity …)
  categoryName: r.category_name,
  projectCode: r.project_code,
  projectTitle: r.project_title,
  subtaskDue: r.subtask_due,
  // planned by someone else (the project owner) – null when the user added it
  addedByName: r.created_by && r.created_by !== r.user_id ? r.created_by_name : null,
  userName: r.user_name, // whose 1-3-5 it is
});

const dayOf = (auth, date) => date ?? todayIn(auth.timeZone);

async function dayItems(db, userId, date) {
  const { rows } = await db.query(`${SELECT} WHERE i.user_id = $1 AND i.plan_date = $2 ORDER BY i.position, i.id`, [userId, date]);
  return rows;
}

/** Positions 1..n again after a remove / move. */
async function renumber(client, userId, date) {
  await client.query(
    `UPDATE task_135_items i SET position = x.rn
       FROM (SELECT id, row_number() OVER (ORDER BY position, id) AS rn FROM task_135_items WHERE user_id = $1 AND plan_date = $2) x
      WHERE i.id = x.id AND i.position <> x.rn`,
    [userId, date],
  );
}

async function ownItem(db, auth, id) {
  const { rows } = await db.query(`${SELECT} WHERE i.id = $1 AND i.user_id = $2`, [id, auth.userId]);
  if (!rows[0]) throw notFound('1-3-5 item');
  return rows[0];
}

/** Room on the user's day for one more item, and the task / subtask is not on it yet. */
async function assertRoom(db, userId, date, { taskId = null, subtaskId = null } = {}) {
  const items = await dayItems(db, userId, date);
  if (items.length >= SLOTS) throw badRequest(`The 1-3-5 of ${date} is full (9 items) – move or remove one first`);
  if (taskId && items.some((r) => r.task_id === taskId)) throw conflict(`This task is already on the 1-3-5 of ${date}`);
  if (subtaskId && items.some((r) => r.subtask_id === subtaskId)) throw conflict(`This subtask is already on the 1-3-5 of ${date}`);
  return items.length + 1;
}

/** A subtask assigned to the user (and its parent task). */
async function mySubtask(db, auth, subtaskId) {
  const { rows } = await db.query(`SELECT id, task_id, title, assigned_to, is_done FROM task_subtasks WHERE id = $1`, [subtaskId]);
  const s = rows[0];
  if (!s) throw notFound('Subtask');
  if (s.assigned_to !== auth.userId) throw badRequest('Only subtasks assigned to you can be added to your 1-3-5', [{ field: 'subtaskId', message: 'not assigned to you' }]);
  await getTask(db, auth, s.task_id); // the parent task is visible to the user
  return s;
}

export async function listDay(db, auth, date) {
  const day = dayOf(auth, date);
  return { date: day, today: todayIn(auth.timeZone), slots: SLOTS, items: (await dayItems(db, auth.userId, day)).map(toDto) };
}

/** Picker: open subtasks assigned to me (of tasks that are not completed). */
export async function mySubtasks(db, auth, search) {
  const params = [auth.userId];
  let filter = '';
  if (search?.trim()) {
    params.push(`%${escapeLike(search.trim())}%`);
    filter = `AND (s.title ILIKE $2 OR t.name ILIKE $2 OR p.code ILIKE $2 OR p.title ILIKE $2)`;
  }
  const { rows } = await db.query(
    `SELECT s.id, s.title, s.due_date, t.id AS task_id, t.name AS task_name, t.priority, p.code AS project_code, p.title AS project_title
       FROM task_subtasks s
       JOIN tasks t ON t.id = s.task_id AND t.is_active AND t.status <> 'completed'
       LEFT JOIN projects p ON p.id = t.project_id
      WHERE s.assigned_to = $1 AND NOT s.is_done ${filter}
      ORDER BY s.due_date NULLS LAST, t.name, s.sort_order LIMIT 100`,
    params,
  );
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    dueDate: r.due_date,
    taskId: r.task_id,
    taskName: r.task_name,
    priority: r.priority,
    projectCode: r.project_code,
    projectTitle: r.project_title,
  }));
}

export async function addItem(db, auth, body) {
  const date = dayOf(auth, body.date);
  let title = body.title?.trim();
  let taskId = null;
  let subtaskId = null;
  let userId = auth.userId; // whose 1-3-5
  if (body.taskId) {
    const task = await getTask(db, auth, body.taskId); // a task the user can see
    if (!task.assignedTo) throw badRequest('Assign the task to someone first', [{ field: 'taskId', message: 'not assigned' }]);
    // the assignee works on it; the project owner (the task owner without a project) plans it for them
    const planner = task.projectId ? task.projectOwnerId : task.ownerId;
    if (task.assignedTo !== auth.userId && planner !== auth.userId) {
      throw badRequest('Only the person the task is assigned to – or the project owner, for them – can add it to a 1-3-5', [{ field: 'taskId', message: 'not your task' }]);
    }
    userId = task.assignedTo;
    title = task.name;
    taskId = task.id;
  } else if (body.subtaskId) {
    const s = await mySubtask(db, auth, body.subtaskId);
    if (s.is_done) throw badRequest('This subtask is already done');
    title = s.title;
    subtaskId = s.id;
  }
  if (!title) throw badRequest('Enter what to do', [{ field: 'title', message: 'is required' }]);
  const position = await assertRoom(db, userId, date, { taskId, subtaskId });
  const { rows } = await db.query(
    `INSERT INTO task_135_items (user_id, plan_date, position, task_id, subtask_id, title, created_by, updated_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $7) RETURNING id`,
    [userId, date, position, taskId, subtaskId, title, auth.userId],
  );
  const { rows: added } = await db.query(`${SELECT} WHERE i.id = $1`, [rows[0].id]);
  return toDto(added[0]);
}

export async function updateItem(db, auth, id, body) {
  const before = await ownItem(db, auth, id);
  const title = body.title !== undefined ? body.title.trim() : before.title;
  if (!title) throw badRequest('Enter what to do', [{ field: 'title', message: 'is required' }]);
  const isDone = body.isDone ?? before.is_done;
  // a subtask's done lives on the subtask itself (same rules as ticking it on the task page)
  if (before.subtask_id && body.isDone !== undefined && body.isDone !== before.is_done) {
    await setSubtaskDone(db, auth, before.link_task_id, before.subtask_id, body.isDone);
  }
  await db.query(
    `UPDATE task_135_items SET title = $2, minutes = $3, is_done = $4,
            done_at = CASE WHEN $4 THEN COALESCE(done_at, now()) END, updated_by = $5
      WHERE id = $1`,
    [id, title, body.minutes ?? before.minutes, isDone, auth.userId],
  );
  return toDto(await ownItem(db, auth, id));
}

/** New order of a day: ids from first (big) to last. */
export async function reorderDay(db, auth, body) {
  const items = await dayItems(db, auth.userId, body.date);
  const ids = items.map((r) => r.id);
  if (ids.length !== body.ids.length || !body.ids.every((x) => ids.includes(x))) {
    throw badRequest('The list changed meanwhile – reload and try again');
  }
  await db.tx(async (client) => {
    for (const [i, id] of body.ids.entries()) await client.query(`UPDATE task_135_items SET position = $2, updated_by = $3 WHERE id = $1`, [id, i + 1, auth.userId]);
  });
  return listDay(db, auth, body.date);
}

/** Move or copy an item to another day (at the end of that day's list). */
export async function moveItem(db, auth, id, body) {
  const item = await ownItem(db, auth, id);
  const from = item.plan_date;
  if (body.date === from) throw badRequest('Pick another day');
  const position = await assertRoom(db, auth.userId, body.date, { taskId: item.task_id, subtaskId: item.subtask_id });
  const newId = await db.tx(async (client) => {
    if (body.mode === 'copy') {
      const { rows } = await client.query(
        `INSERT INTO task_135_items (user_id, plan_date, position, task_id, subtask_id, title, copied_from, created_by, updated_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $1, $1) RETURNING id`,
        [auth.userId, body.date, position, item.task_id, item.subtask_id, item.title, id],
      );
      return rows[0].id;
    }
    await client.query(`UPDATE task_135_items SET plan_date = $2, position = $3, updated_by = $4 WHERE id = $1`, [id, body.date, position, auth.userId]);
    await renumber(client, auth.userId, from);
    return id;
  });
  return toDto(await ownItem(db, auth, newId));
}

export async function removeItem(db, auth, id) {
  const item = await ownItem(db, auth, id);
  await db.tx(async (client) => {
    await client.query(`DELETE FROM task_135_items WHERE id = $1`, [id]);
    await renumber(client, auth.userId, item.plan_date);
  });
}
