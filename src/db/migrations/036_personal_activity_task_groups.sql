-- Task groups / types for the non-project categories (Personal, Activity) and their link to the category.
-- Idempotent: groups, types and links that exist are left as they are.

INSERT INTO task_groups (name) SELECT 'Personal Work' WHERE NOT EXISTS (SELECT 1 FROM task_groups WHERE lower(name) = lower('Personal Work'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Personal Task' FROM task_groups g
 WHERE lower(g.name) = lower('Personal Work') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Personal Task'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Learning & Self-study' FROM task_groups g
 WHERE lower(g.name) = lower('Personal Work') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Learning & Self-study'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Planning & Organising' FROM task_groups g
 WHERE lower(g.name) = lower('Personal Work') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Planning & Organising'));
INSERT INTO task_category_groups (task_category_id, task_group_id) SELECT c.id, g.id FROM task_categories c, task_groups g
 WHERE lower(c.name) = lower('Personal') AND lower(g.name) = lower('Personal Work') ON CONFLICT DO NOTHING;
INSERT INTO task_groups (name) SELECT 'Meetings & Training' WHERE NOT EXISTS (SELECT 1 FROM task_groups WHERE lower(name) = lower('Meetings & Training'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Internal Meeting' FROM task_groups g
 WHERE lower(g.name) = lower('Meetings & Training') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Internal Meeting'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Training / Workshop' FROM task_groups g
 WHERE lower(g.name) = lower('Meetings & Training') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Training / Workshop'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Interview' FROM task_groups g
 WHERE lower(g.name) = lower('Meetings & Training') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Interview'));
INSERT INTO task_category_groups (task_category_id, task_group_id) SELECT c.id, g.id FROM task_categories c, task_groups g
 WHERE lower(c.name) = lower('Activity') AND lower(g.name) = lower('Meetings & Training') ON CONFLICT DO NOTHING;
INSERT INTO task_groups (name) SELECT 'Office Activities' WHERE NOT EXISTS (SELECT 1 FROM task_groups WHERE lower(name) = lower('Office Activities'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Administration' FROM task_groups g
 WHERE lower(g.name) = lower('Office Activities') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Administration'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Team Event' FROM task_groups g
 WHERE lower(g.name) = lower('Office Activities') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Team Event'));
INSERT INTO task_types (task_group_id, name) SELECT g.id, 'Support to Colleagues' FROM task_groups g
 WHERE lower(g.name) = lower('Office Activities') AND NOT EXISTS (SELECT 1 FROM task_types t WHERE t.task_group_id = g.id AND lower(t.name) = lower('Support to Colleagues'));
INSERT INTO task_category_groups (task_category_id, task_group_id) SELECT c.id, g.id FROM task_categories c, task_groups g
 WHERE lower(c.name) = lower('Activity') AND lower(g.name) = lower('Office Activities') ON CONFLICT DO NOTHING;
