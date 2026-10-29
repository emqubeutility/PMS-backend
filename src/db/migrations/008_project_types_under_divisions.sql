-- Project types belong to a project division (Web → Website Development, SEO …).
-- Both are managed on one screen: "Business Division" (/administration/project-divisions);
-- the separate Project Types menu goes away.

ALTER TABLE project_types ADD COLUMN project_division_id bigint;

-- 1. the division most of the type's projects use
UPDATE project_types t
   SET project_division_id = pick.project_division_id
  FROM (SELECT DISTINCT ON (p.project_type_id) p.project_type_id, p.project_division_id
          FROM projects p
         GROUP BY p.project_type_id, p.project_division_id
         ORDER BY p.project_type_id, count(*) DESC, p.project_division_id) pick
 WHERE t.id = pick.project_type_id;

-- 2. web-looking names → a division called "Web"
UPDATE project_types t
   SET project_division_id = (SELECT id FROM project_divisions WHERE lower(name) = 'web' ORDER BY id LIMIT 1)
 WHERE t.project_division_id IS NULL
   AND t.name ~* '(web|site|seo|search|social|digital|google|ads|video|content|marketing)';

-- 3. the rest → the first division
UPDATE project_types SET project_division_id = (SELECT id FROM project_divisions ORDER BY id LIMIT 1)
 WHERE project_division_id IS NULL;

ALTER TABLE project_types ADD CONSTRAINT fk_project_types__project_division_id
  FOREIGN KEY (project_division_id) REFERENCES project_divisions (id) ON DELETE RESTRICT;
CREATE INDEX ix_project_types__project_division_id ON project_types (project_division_id);
-- required once every type has one (a database without any division keeps it optional)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM project_types WHERE project_division_id IS NULL) THEN
    ALTER TABLE project_types ALTER COLUMN project_division_id SET NOT NULL;
  END IF;
END $$;
COMMENT ON COLUMN project_types.project_division_id IS 'division the project type belongs to; projects of this type use this division';

-- one menu for both
UPDATE menus SET name = 'Business Division' WHERE url = '/administration/project-divisions';

-- roles keep what they could do on Project Types: merge those rights into the combined screen
INSERT INTO role_permissions (role_id, menu_id, can_view, can_create, can_edit, can_delete, can_approve, can_export)
SELECT rp.role_id, d.id, rp.can_view, rp.can_create, rp.can_edit, rp.can_delete, false, rp.can_export
  FROM role_permissions rp
  JOIN menus t ON t.id = rp.menu_id AND t.url = '/administration/project-types'
  JOIN menus d ON d.url = '/administration/project-divisions'
ON CONFLICT (role_id, menu_id) DO UPDATE
   SET can_view = role_permissions.can_view OR EXCLUDED.can_view,
       can_create = role_permissions.can_create OR EXCLUDED.can_create,
       can_edit = role_permissions.can_edit OR EXCLUDED.can_edit,
       can_delete = role_permissions.can_delete OR EXCLUDED.can_delete,
       can_export = role_permissions.can_export OR EXCLUDED.can_export;

DELETE FROM menus WHERE url = '/administration/project-types';
