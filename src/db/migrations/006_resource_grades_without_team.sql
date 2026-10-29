-- Resource grades are no longer per team: one resource grade per grade (Level A, Level B …)
-- with its cost-per-hour history. Rows of the same grade for different teams are merged.

-- the row kept for each grade: the one with the most cost history, then the most users, then the oldest
CREATE TEMP TABLE rg_keep ON COMMIT DROP AS
SELECT rg.id,
       first_value(rg.id) OVER (
         PARTITION BY rg.grade_id
         ORDER BY (SELECT count(*) FROM resource_grade_costs c WHERE c.resource_grade_id = rg.id) DESC,
                  (SELECT count(*) FROM users u WHERE u.resource_grade_id = rg.id) DESC,
                  rg.id
       ) AS keep_id
  FROM resource_grades rg;

-- users of a merged row move to the kept row of the same grade
UPDATE users u SET resource_grade_id = k.keep_id
  FROM rg_keep k
 WHERE u.resource_grade_id = k.id AND k.id <> k.keep_id;

-- merged rows go (their cost history with them: ON DELETE CASCADE)
DELETE FROM resource_grades WHERE id IN (SELECT id FROM rg_keep WHERE id <> keep_id);

ALTER TABLE resource_grades DROP COLUMN team_id;
ALTER TABLE resource_grades ADD CONSTRAINT uq_resource_grades__grade_id UNIQUE (grade_id);
COMMENT ON TABLE resource_grades IS 'Resource grade (lookup GRADE) with its cost-per-hour history';
COMMENT ON TABLE resource_grade_costs IS 'Cost-per-hour history: per currency the periods follow each other without gaps; only the latest may be open (to_date NULL)';
