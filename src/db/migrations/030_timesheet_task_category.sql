-- Timesheet entries get a task category (Project, Personal, Activity …).
-- Project category: project + task group of its estimate + task type, as before.
-- Other categories: no project; task group / type optional.
ALTER TABLE timesheets
    ADD COLUMN task_category_id bigint,
    ADD CONSTRAINT fk_timesheets__task_category_id FOREIGN KEY (task_category_id) REFERENCES task_categories (id) ON DELETE RESTRICT;
CREATE INDEX ix_timesheets__task_category_id ON timesheets (task_category_id);
COMMENT ON COLUMN timesheets.task_category_id IS 'task category of the entry; project categories need a project';

-- existing entries are project time
UPDATE timesheets
   SET task_category_id = (SELECT id FROM task_categories WHERE is_project ORDER BY is_active DESC, display_order, id LIMIT 1)
 WHERE task_category_id IS NULL;

ALTER TABLE timesheets
    ALTER COLUMN project_id DROP NOT NULL,
    ALTER COLUMN task_type_id DROP NOT NULL;
