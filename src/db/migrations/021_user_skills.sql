-- Skills move from the role to each user: users with the Employee or Project Manager role pick their own
-- skills (Parameters → SKILL). The skills that were set on those roles are given to their users.

CREATE TABLE user_skills (
    user_id bigint NOT NULL,
    skill_id bigint NOT NULL,
    CONSTRAINT pk_user_skills PRIMARY KEY (user_id, skill_id),
    CONSTRAINT fk_user_skills__user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_skills__skill_id FOREIGN KEY (skill_id) REFERENCES lookups (id) ON DELETE CASCADE
);
CREATE INDEX ix_user_skills__skill_id ON user_skills (skill_id);
COMMENT ON TABLE user_skills IS 'Skills (Parameters → SKILL) of a user – Employee and Project Manager roles only';

INSERT INTO user_skills (user_id, skill_id)
SELECT u.id, rs.skill_id
  FROM users u
  JOIN roles r ON r.id = u.role_id AND r.code IN ('EMPLOYEE', 'PROJECT_MANAGER')
  JOIN role_skills rs ON rs.role_id = r.id
ON CONFLICT DO NOTHING;

DROP TABLE role_skills;
