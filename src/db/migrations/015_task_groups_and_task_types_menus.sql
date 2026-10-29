-- "Task Groups & Types" is split into two menus, each with its own screen and permissions:
--   Task Groups  -> /administration/task-groups
--   Task Types   -> /administration/task-types

UPDATE menus SET name = 'Task Groups' WHERE url = '/administration/task-groups';

-- the Task Types menu goes right after Task Groups, in the same module
INSERT INTO menus (name, parent_id, url, icon, display_order, actions)
SELECT 'Task Types', parent_id, '/administration/task-types', 'list-checks', display_order + 1, actions
  FROM menus
 WHERE url = '/administration/task-groups'
   AND NOT EXISTS (SELECT 1 FROM menus WHERE url = '/administration/task-types');

-- roles that could see the combined screen keep both menus; they can be split later on the
-- Roles & Permissions screen
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, t.id, rp.can_view, rp.can_create, rp.can_edit, rp.can_delete, false, rp.can_export
  FROM role_permissions rp
  JOIN menus g ON g.id = rp.menu_id AND g.url = '/administration/task-groups'
  JOIN menus t ON t.url = '/administration/task-types'
ON CONFLICT (role_id, menu_id) DO UPDATE
   SET can_view = role_permissions.can_view OR EXCLUDED.can_view,
       can_create = role_permissions.can_create OR EXCLUDED.can_create,
       can_edit = role_permissions.can_edit OR EXCLUDED.can_edit,
       can_delete = role_permissions.can_delete OR EXCLUDED.can_delete,
       can_export = role_permissions.can_export OR EXCLUDED.can_export;
