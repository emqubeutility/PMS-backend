-- The Commercial tab follows Roles & Permissions → Project access only (no more "project manager of
-- the project" condition). To keep who sees it today, every role except Project Manager (and Super
-- Admin, level 0, which always has access) starts with the Commercial tab Hidden.
INSERT INTO role_access_rules (role_id, scope, key, access)
SELECT r.id, 'project_tab', 'commercial', 'hidden'
  FROM roles r
 WHERE r.level > 0 AND r.code <> 'PROJECT_MANAGER'
ON CONFLICT (role_id, scope, key) DO NOTHING;
