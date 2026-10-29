-- Task Master: who can see whose tasks and timesheet entries (view only), set per person.
-- One-way: a row (viewer → user) lets the viewer see the user's work, not the other way round.
CREATE TABLE task_access (
    viewer_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_task_access PRIMARY KEY (viewer_id, user_id),
    CONSTRAINT ck_task_access__not_self CHECK (viewer_id <> user_id),
    CONSTRAINT fk_task_access__viewer_id FOREIGN KEY (viewer_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_access__user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_access__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE INDEX ix_task_access__user_id ON task_access (user_id);
COMMENT ON TABLE task_access IS 'Task Master: viewer_id may see the tasks and timesheet entries of user_id (view only)';

-- private categories (Personal): others who can see the person's work only see that there is personal work
ALTER TABLE task_categories ADD COLUMN is_private boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN task_categories.is_private IS 'details of these tasks / time entries are hidden from everyone but the people on the task';
UPDATE task_categories SET is_private = true WHERE lower(name) = 'personal';

-- menu: Administration → Task Master (view / edit)
INSERT INTO menus (name, parent_id, url, display_order, actions)
SELECT 'Task Master', p.id, '/administration/task-master', 10, '{view,edit}'
  FROM menus p WHERE p.name = 'Administration' AND p.parent_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM menus WHERE url = '/administration/task-master');

-- whoever manages roles also manages who sees whose tasks
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, m.id, rp.can_view, false, rp.can_edit, false, false, false
  FROM role_permissions rp
  JOIN menus r ON r.id = rp.menu_id AND r.url = '/administration/roles'
  JOIN menus m ON m.url = '/administration/task-master'
 WHERE rp.can_view
ON CONFLICT (role_id, menu_id) DO NOTHING;
