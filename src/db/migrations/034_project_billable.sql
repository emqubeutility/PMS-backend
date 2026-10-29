-- Billable is set per project: project time inherits it. Personal / Activity time is never billable.
ALTER TABLE projects ADD COLUMN IF NOT EXISTS is_billable boolean NOT NULL DEFAULT true;
COMMENT ON COLUMN projects.is_billable IS 'time logged on the project is billable (timesheets.is_billable copies it when the time is logged)';
