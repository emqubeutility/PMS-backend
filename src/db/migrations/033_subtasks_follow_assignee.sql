-- Subtasks are no longer assigned separately: the person the task is assigned to does its subtasks.
-- assigned_to stays on task_subtasks (1-3-5, timesheet and "my work" rules read it) and always mirrors the task.
UPDATE task_subtasks s
   SET assigned_to = t.assigned_to
  FROM tasks t
 WHERE t.id = s.task_id AND s.assigned_to IS DISTINCT FROM t.assigned_to;
COMMENT ON COLUMN task_subtasks.assigned_to IS 'always the task''s assignee (subtasks are not assigned separately)';
