-- The task roles are maintained as Skills: Parameters → type SKILL (was TASK_ROLE). The ids stay the
-- same, so roles, template tasks and project tasks keep their skills.
UPDATE lookups SET type = 'SKILL' WHERE type = 'TASK_ROLE';
