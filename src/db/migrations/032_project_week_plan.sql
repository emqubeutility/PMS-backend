-- Project Plan tab: the project owner plans the project's task groups week by week (a plan only –
-- no tasks or time are created). A group can be planned in several weeks, once per week.
CREATE TABLE project_week_plans (
    id bigint GENERATED ALWAYS AS IDENTITY,
    project_id bigint NOT NULL,
    task_group_id bigint NOT NULL,
    week_start date NOT NULL,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_project_week_plans PRIMARY KEY (id),
    CONSTRAINT uq_project_week_plans UNIQUE (project_id, task_group_id, week_start),
    CONSTRAINT ck_project_week_plans__monday CHECK (extract(isodow FROM week_start) = 1),
    CONSTRAINT fk_project_week_plans__project_id FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
    CONSTRAINT fk_project_week_plans__task_group_id FOREIGN KEY (task_group_id) REFERENCES task_groups (id) ON DELETE CASCADE,
    CONSTRAINT fk_project_week_plans__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE INDEX ix_project_week_plans__project_id ON project_week_plans (project_id, week_start);
COMMENT ON TABLE project_week_plans IS 'Plan tab: task groups planned per week (week_start = Monday) – project owner only';
