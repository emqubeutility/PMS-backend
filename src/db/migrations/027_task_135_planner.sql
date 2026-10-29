-- 1-3-5 planner (Task → 1-3-5): every user plans each day as 1 big, 3 medium and 5 small items
-- (9 slots). An item is one of their tasks ("Add to 1-3-5" on the task list) or a short free text.
-- Done / time here are the planner's own – they never change the task's status.

CREATE TABLE task_135_items (
    id bigint GENERATED ALWAYS AS IDENTITY,
    user_id bigint NOT NULL,
    plan_date date NOT NULL,
    position smallint NOT NULL,
    task_id bigint,
    title varchar(300) NOT NULL,
    minutes int NOT NULL DEFAULT 0,
    is_done boolean NOT NULL DEFAULT false,
    done_at timestamptz,
    copied_from bigint,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_task_135_items PRIMARY KEY (id),
    CONSTRAINT ck_task_135_items__position CHECK (position BETWEEN 1 AND 9),
    CONSTRAINT ck_task_135_items__minutes CHECK (minutes >= 0 AND minutes <= 1440),
    CONSTRAINT fk_task_135_items__user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_135_items__task_id FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_135_items__copied_from FOREIGN KEY (copied_from) REFERENCES task_135_items (id) ON DELETE SET NULL,
    CONSTRAINT fk_task_135_items__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_task_135_items__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE INDEX ix_task_135_items__user_date ON task_135_items (user_id, plan_date, position);
CREATE INDEX ix_task_135_items__task_id ON task_135_items (task_id);
-- a task appears at most once on a day
CREATE UNIQUE INDEX uq_task_135_items__user_date_task ON task_135_items (user_id, plan_date, task_id) WHERE task_id IS NOT NULL;
CREATE TRIGGER trg_task_135_items__updated_at BEFORE UPDATE ON task_135_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE task_135_items IS '1-3-5 daily planner: slot 1 = big, 2-4 = medium, 5-9 = small';
COMMENT ON COLUMN task_135_items.minutes IS 'time spent on the item that day (planner only)';
COMMENT ON COLUMN task_135_items.is_done IS 'done in the planner – independent of tasks.status';

-- menu: Task → 1-3-5 (after Task Category, Task)
INSERT INTO menus (name, parent_id, url, display_order)
SELECT '1-3-5', p.id, '/task-135', 3
  FROM menus p WHERE p.name = 'Task' AND p.parent_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM menus WHERE url = '/task-135');

-- whoever can use the task list gets the planner
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, m.id, rp.can_view, rp.can_view, rp.can_view, rp.can_view, false, false
  FROM role_permissions rp
  JOIN menus t ON t.id = rp.menu_id AND t.url = '/tasks'
  JOIN menus m ON m.url = '/task-135'
 WHERE rp.can_view
ON CONFLICT (role_id, menu_id) DO NOTHING;
