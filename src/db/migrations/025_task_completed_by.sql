-- Who completed a task (shown on the task details timeline: "Completed 23 Oct, by Subash").
ALTER TABLE tasks
    ADD COLUMN completed_by bigint,
    ADD CONSTRAINT fk_tasks__completed_by FOREIGN KEY (completed_by) REFERENCES users (id) ON DELETE SET NULL;
COMMENT ON COLUMN tasks.completed_by IS 'user who set the status to completed';

-- tasks completed before this column: best guess is the last person who changed them
UPDATE tasks SET completed_by = updated_by WHERE status = 'completed' AND completed_by IS NULL;
