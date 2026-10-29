-- Task categories become a tab of "Task Groups & Types" and each category gets its task groups.
--   * task_category_groups: the task groups a category can use (none picked = any group)
--   * the separate "Task Category" menu is merged into "Task Groups & Types": a role keeps every action it had on either

CREATE TABLE IF NOT EXISTS task_category_groups (
    task_category_id bigint NOT NULL,
    task_group_id bigint NOT NULL,
    CONSTRAINT pk_task_category_groups PRIMARY KEY (task_category_id, task_group_id),
    CONSTRAINT fk_task_category_groups__task_category_id FOREIGN KEY (task_category_id) REFERENCES task_categories (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_category_groups__task_group_id FOREIGN KEY (task_group_id) REFERENCES task_groups (id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ix_task_category_groups__task_group_id ON task_category_groups (task_group_id);
COMMENT ON TABLE task_category_groups IS 'task groups a task category can use; a category without rows accepts any group';

-- the existing task groups are project work: link them to the project categories
INSERT INTO task_category_groups (task_category_id, task_group_id)
SELECT c.id, g.id FROM task_categories c CROSS JOIN task_groups g WHERE c.is_project
ON CONFLICT DO NOTHING;

-- menu: Task Category -> a tab of Task Groups & Types
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, g.id, rp.can_view, rp.can_create, rp.can_edit, rp.can_delete, false, rp.can_export
  FROM role_permissions rp
  JOIN menus c ON c.id = rp.menu_id AND c.url = '/task-categories'
  JOIN menus g ON g.url = '/administration/task-groups'
ON CONFLICT (role_id, menu_id) DO UPDATE
   SET can_view = role_permissions.can_view OR EXCLUDED.can_view,
       can_create = role_permissions.can_create OR EXCLUDED.can_create,
       can_edit = role_permissions.can_edit OR EXCLUDED.can_edit,
       can_delete = role_permissions.can_delete OR EXCLUDED.can_delete,
       can_export = role_permissions.can_export OR EXCLUDED.can_export;

DELETE FROM role_permissions WHERE menu_id IN (SELECT id FROM menus WHERE url = '/task-categories');
DELETE FROM menus WHERE url = '/task-categories';
