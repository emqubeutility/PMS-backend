-- Finer access per role inside a screen: which project tabs a role sees / edits and which fields of the
-- Project tab it sees / edits. A missing row means 'edit' (today's behaviour), so nothing changes until
-- a rule is set on Roles & Permissions.
--   scope 'project_tab'   key: update, project, users, estimate, tasks, commercial, analysis, history
--   scope 'project_field' key: customerId, ownerId, title, … (API field names)

CREATE TABLE role_access_rules (
    role_id bigint NOT NULL,
    scope varchar(30) NOT NULL,
    key varchar(50) NOT NULL,
    access varchar(10) NOT NULL,
    CONSTRAINT pk_role_access_rules PRIMARY KEY (role_id, scope, key),
    CONSTRAINT fk_role_access_rules__role_id FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
    CONSTRAINT ck_role_access_rules__access CHECK (access IN ('hidden', 'view', 'edit'))
);
COMMENT ON TABLE role_access_rules IS 'Per role: project tabs / Project-tab fields as hidden, view or edit (no row = edit)';
