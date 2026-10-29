-- Tasks created from the project plan ("Add tasks from the plan"): one task per planned task group.
-- A task group with such tasks cannot leave the estimate / the plan while they are open, and a new plan
-- period can be applied to their dates.
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS from_plan boolean NOT NULL DEFAULT false;
CREATE INDEX IF NOT EXISTS ix_tasks__plan_group ON tasks (project_id, task_group_id) WHERE from_plan;
COMMENT ON COLUMN tasks.from_plan IS 'created from the project plan (one task per planned task group)';
