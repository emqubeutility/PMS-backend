-- 1-3-5 is now a tab on the Task page: hide it from the sidebar.
-- The menu row stays – it carries the 1-3-5 permissions (still set per role on the Roles screen).
UPDATE menus SET is_visible = false, updated_at = now() WHERE url = '/task-135';
