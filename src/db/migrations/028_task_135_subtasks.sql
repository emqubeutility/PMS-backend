-- 1-3-5: a subtask assigned to the user can be planned too. Its done flag is the subtask's own
-- (ticking it in 1-3-5 ticks the subtask) – unlike tasks, whose status the planner never changes.

ALTER TABLE task_135_items
    ADD COLUMN subtask_id bigint,
    ADD CONSTRAINT fk_task_135_items__subtask_id FOREIGN KEY (subtask_id) REFERENCES task_subtasks (id) ON DELETE CASCADE,
    ADD CONSTRAINT ck_task_135_items__task_or_subtask CHECK (task_id IS NULL OR subtask_id IS NULL);
CREATE INDEX ix_task_135_items__subtask_id ON task_135_items (subtask_id);
-- a subtask appears at most once on a day
CREATE UNIQUE INDEX uq_task_135_items__user_date_subtask ON task_135_items (user_id, plan_date, subtask_id) WHERE subtask_id IS NOT NULL;
COMMENT ON COLUMN task_135_items.subtask_id IS 'planned subtask (assigned to the user); done = task_subtasks.is_done';
