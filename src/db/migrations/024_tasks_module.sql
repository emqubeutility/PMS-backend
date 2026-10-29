-- Task module: Task menu with two screens
--   Task Category  -> /task-categories  (Project, Personal, Activity …)
--   Task           -> /tasks            (create / list tasks for yourself or others)
-- A task has a category (Project needs a project), owner, assignee, estimate, priority,
-- earliest start / end before (not needed for a continuous task), status, completed date and subtasks.

CREATE TABLE task_categories (
    id bigint GENERATED ALWAYS AS IDENTITY,
    name varchar(100) NOT NULL,
    description text,
    is_project boolean NOT NULL DEFAULT false,
    display_order int NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_task_categories PRIMARY KEY (id),
    CONSTRAINT fk_task_categories__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_task_categories__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX uq_task_categories__name ON task_categories (lower(name));
CREATE TRIGGER trg_task_categories__updated_at BEFORE UPDATE ON task_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE task_categories IS 'Task categories (Project, Personal, Activity …)';
COMMENT ON COLUMN task_categories.is_project IS 'tasks of this category belong to a project';

INSERT INTO task_categories (name, description, is_project, display_order) VALUES
    ('Project', 'Work on a project', true, 1),
    ('Personal', 'Own work, not tied to a project', false, 2),
    ('Activity', 'General / office activities', false, 3);

-- tasks: category, continuous flag, completed date
ALTER TABLE tasks
    ADD COLUMN task_category_id bigint,
    ADD COLUMN is_continuous boolean NOT NULL DEFAULT false,
    ADD COLUMN completed_on date,
    ADD CONSTRAINT fk_tasks__task_category_id FOREIGN KEY (task_category_id) REFERENCES task_categories (id) ON DELETE RESTRICT;
CREATE INDEX ix_tasks__task_category_id ON tasks (task_category_id);
COMMENT ON COLUMN tasks.is_continuous IS 'ongoing task – no earliest start / end before';
COMMENT ON COLUMN tasks.completed_on IS 'date the task was completed';

-- existing (project template) tasks: Project category, new status values
UPDATE tasks SET task_category_id = (SELECT id FROM task_categories WHERE name = 'Project') WHERE project_id IS NOT NULL AND task_category_id IS NULL;
UPDATE tasks SET status = CASE status
    WHEN 'open' THEN 'to_do'
    WHEN 'closed' THEN 'completed'
    WHEN 'done' THEN 'completed'
    WHEN 'on_hold' THEN 'hold'
    ELSE status END;
UPDATE tasks SET status = 'to_do' WHERE status NOT IN ('to_do', 'in_progress', 'completed', 'hold');
UPDATE tasks SET priority = NULL WHERE priority NOT IN ('low', 'medium', 'high', 'urgent');
ALTER TABLE tasks
    ALTER COLUMN status SET DEFAULT 'to_do',
    ADD CONSTRAINT ck_tasks__status CHECK (status IN ('to_do', 'in_progress', 'completed', 'hold')),
    ADD CONSTRAINT ck_tasks__priority CHECK (priority IS NULL OR priority IN ('low', 'medium', 'high', 'urgent'));

-- subtasks: a short checklist of work items, each with its own assignee and due date
CREATE TABLE task_subtasks (
    id bigint GENERATED ALWAYS AS IDENTITY,
    task_id bigint NOT NULL,
    title varchar(300) NOT NULL,
    assigned_to bigint,
    due_date date,
    is_done boolean NOT NULL DEFAULT false,
    sort_order int NOT NULL DEFAULT 0,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_task_subtasks PRIMARY KEY (id),
    CONSTRAINT fk_task_subtasks__task_id FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_subtasks__assigned_to FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_task_subtasks__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_task_subtasks__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE INDEX ix_task_subtasks__task_id ON task_subtasks (task_id);
CREATE INDEX ix_task_subtasks__assigned_to ON task_subtasks (assigned_to);
CREATE TRIGGER trg_task_subtasks__updated_at BEFORE UPDATE ON task_subtasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE task_subtasks IS 'Subtasks of a task (title, assignee, due date)';

-- menu: Task → Task Category, Task (between Projects and Timesheet)
INSERT INTO menus (name, parent_id, icon, display_order)
SELECT 'Task', NULL, 'clipboard-list', 25
 WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = 'Task' AND parent_id IS NULL);

INSERT INTO menus (name, parent_id, url, display_order)
SELECT 'Task Category', p.id, '/task-categories', 1
  FROM menus p WHERE p.name = 'Task' AND p.parent_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM menus WHERE url = '/task-categories');

INSERT INTO menus (name, parent_id, url, display_order)
SELECT 'Task', p.id, '/tasks', 2
  FROM menus p WHERE p.name = 'Task' AND p.parent_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM menus WHERE url = '/tasks');

-- default permissions (change them on Roles & Permissions):
--   Admin: everything; Project Manager: tasks + view categories; Employee: own tasks
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT r.id, m.id, v.can_view, v.can_create, v.can_edit, v.can_delete, false, v.can_export
  FROM (VALUES
          ('ADMIN', '/task-categories', true, true, true, true, true),
          ('ADMIN', '/tasks', true, true, true, true, true),
          ('PROJECT_MANAGER', '/task-categories', true, false, false, false, false),
          ('PROJECT_MANAGER', '/tasks', true, true, true, true, true),
          ('EMPLOYEE', '/tasks', true, true, true, true, false)
       ) AS v(role_code, url, can_view, can_create, can_edit, can_delete, can_export)
  JOIN roles r ON r.code = v.role_code
  JOIN menus m ON m.url = v.url
ON CONFLICT (role_id, menu_id) DO NOTHING;
