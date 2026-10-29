-- One master for where and when people work: the Site Master holds each site's shift time.
-- The shifts table, users.shift_id and the Shift Master screen go away; attendance and rosters
-- point at the site instead of a shift.

ALTER TABLE sites
    ADD COLUMN start_time time,
    ADD COLUMN end_time time,
    ADD COLUMN late_after_minutes smallint,
    ADD COLUMN half_day_minutes smallint;

-- 1. the shift most of the site's users had
UPDATE sites s
   SET start_time = sh.start_time, end_time = sh.end_time,
       late_after_minutes = sh.late_after_minutes, half_day_minutes = sh.half_day_minutes
  FROM (SELECT DISTINCT ON (u.site_id) u.site_id, u.shift_id
          FROM users u
         WHERE u.site_id IS NOT NULL AND u.shift_id IS NOT NULL
         GROUP BY u.site_id, u.shift_id
         ORDER BY u.site_id, count(*) DESC, u.shift_id) pick
  JOIN shifts sh ON sh.id = pick.shift_id
 WHERE s.id = pick.site_id;

-- 2. a shift named after the site ("DXB Shift" → "Emqube DXB", "Mumbai Shift" → "Emqube Mumbai")
UPDATE sites s
   SET start_time = sh.start_time, end_time = sh.end_time,
       late_after_minutes = sh.late_after_minutes, half_day_minutes = sh.half_day_minutes
  FROM shifts sh
 WHERE s.start_time IS NULL
   AND s.name ILIKE '%' || split_part(sh.name, ' ', 1) || '%'
   AND lower(split_part(sh.name, ' ', 1)) <> 'shift';

-- 3. everything else: a normal office day
UPDATE sites SET start_time = '09:00', end_time = '18:00', late_after_minutes = COALESCE(late_after_minutes, 15), half_day_minutes = COALESCE(half_day_minutes, 240)
 WHERE start_time IS NULL;

ALTER TABLE sites ALTER COLUMN start_time SET NOT NULL, ALTER COLUMN end_time SET NOT NULL;
ALTER TABLE sites ADD CONSTRAINT ck_sites__late_after_minutes CHECK (late_after_minutes IS NULL OR late_after_minutes BETWEEN 0 AND 1440);
ALTER TABLE sites ADD CONSTRAINT ck_sites__half_day_minutes CHECK (half_day_minutes IS NULL OR half_day_minutes BETWEEN 0 AND 1440);
COMMENT ON COLUMN sites.start_time IS 'shift start at this site';
COMMENT ON COLUMN sites.end_time IS 'shift end at this site';
COMMENT ON COLUMN sites.late_after_minutes IS 'minutes after the start time before a check-in counts as late';
COMMENT ON COLUMN sites.half_day_minutes IS 'minutes worked below which the day is a half day';

-- attendance / rosters: the site (and so the shift time) instead of a shift
ALTER TABLE attendance ADD COLUMN site_id bigint;
UPDATE attendance a SET site_id = u.site_id FROM users u WHERE u.id = a.user_id;
ALTER TABLE attendance ADD CONSTRAINT fk_attendance__site_id FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE RESTRICT;
CREATE INDEX ix_attendance__site_id ON attendance (site_id);
ALTER TABLE attendance DROP COLUMN shift_id;
COMMENT ON COLUMN attendance.site_id IS 'site worked at; its shift time decides late / half day';

ALTER TABLE rosters ADD COLUMN site_id bigint;
UPDATE rosters r SET site_id = u.site_id FROM users u WHERE u.id = r.user_id;
UPDATE rosters SET site_id = (SELECT id FROM sites ORDER BY id LIMIT 1) WHERE site_id IS NULL;
ALTER TABLE rosters ALTER COLUMN site_id SET NOT NULL;
ALTER TABLE rosters ADD CONSTRAINT fk_rosters__site_id FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE RESTRICT;
CREATE INDEX ix_rosters__site_id ON rosters (site_id);
ALTER TABLE rosters DROP COLUMN shift_id;
COMMENT ON COLUMN rosters.site_id IS 'site (and shift time) of the user on that day';

-- users take their shift time from their site
ALTER TABLE users DROP COLUMN shift_id;

DROP TABLE shifts;

-- the Shift Master screen (role permissions go with it: ON DELETE CASCADE)
DELETE FROM menus WHERE url = '/administration/shifts';
