-- Task groups and their task types are managed on one screen: "Task Groups & Types"
-- (/administration/task-groups). The separate Task Types menu goes away.

UPDATE menus SET name = 'Task Groups & Types' WHERE url = '/administration/task-groups';

-- roles keep what they could do on Task Types: merge those rights into the combined screen
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, g.id, rp.can_view, rp.can_create, rp.can_edit, rp.can_delete, false, rp.can_export
  FROM role_permissions rp
  JOIN menus t ON t.id = rp.menu_id AND t.url = '/administration/task-types'
  JOIN menus g ON g.url = '/administration/task-groups'
ON CONFLICT (role_id, menu_id) DO UPDATE
   SET can_view = role_permissions.can_view OR EXCLUDED.can_view,
       can_create = role_permissions.can_create OR EXCLUDED.can_create,
       can_edit = role_permissions.can_edit OR EXCLUDED.can_edit,
       can_delete = role_permissions.can_delete OR EXCLUDED.can_delete,
       can_export = role_permissions.can_export OR EXCLUDED.can_export;

-- the old menu (its role permissions go with it: ON DELETE CASCADE)
DELETE FROM menus WHERE url = '/administration/task-types';
