-- Skills: the task roles (Parameters → TASK_ROLE, e.g. Developer, Analyst) a user role covers –
-- set on the role (Project Manager, Employee …). A project task keeps the task roles of its template
-- task, so each task can show the project members whose role has the right skill.

CREATE TABLE role_skills (
    role_id bigint NOT NULL,
    skill_id bigint NOT NULL,
    CONSTRAINT pk_role_skills PRIMARY KEY (role_id, skill_id),
    CONSTRAINT fk_role_skills__role_id FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
    CONSTRAINT fk_role_skills__skill_id FOREIGN KEY (skill_id) REFERENCES lookups (id) ON DELETE CASCADE
);
CREATE INDEX ix_role_skills__skill_id ON role_skills (skill_id);
COMMENT ON TABLE role_skills IS 'Skills (TASK_ROLE lookups) of a user role';

CREATE TABLE task_skills (
    task_id bigint NOT NULL,
    skill_id bigint NOT NULL,
    CONSTRAINT pk_task_skills PRIMARY KEY (task_id, skill_id),
    CONSTRAINT fk_task_skills__task_id FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
    CONSTRAINT fk_task_skills__skill_id FOREIGN KEY (skill_id) REFERENCES lookups (id) ON DELETE CASCADE
);
CREATE INDEX ix_task_skills__skill_id ON task_skills (skill_id);
COMMENT ON TABLE task_skills IS 'Skills (TASK_ROLE lookups) a task needs – copied from its template task';

-- existing project tasks: take the roles of the template task with the same title for the project's type
INSERT INTO task_skills (task_id, skill_id)
SELECT DISTINCT t.id, r.role_id
  FROM tasks t
  JOIN projects p ON p.id = t.project_id
  JOIN project_type_task_templates tt ON tt.project_type_id = p.project_type_id AND tt.task_title = t.name
  JOIN project_type_task_template_roles r ON r.task_template_id = tt.id
ON CONFLICT DO NOTHING;
