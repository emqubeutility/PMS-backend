-- A site has one or more shifts, each with a title ("Morning Shift") and its own timing.
-- The single shift time on sites moves into site_shifts ("General Shift"); users, rosters and
-- attendance point at the site shift.

CREATE TABLE site_shifts (
    id bigint GENERATED ALWAYS AS IDENTITY,
    site_id bigint NOT NULL,
    name varchar(100) NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    late_after_minutes smallint,
    half_day_minutes smallint,
    display_order smallint NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_site_shifts PRIMARY KEY (id),
    CONSTRAINT fk_site_shifts__site_id FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
    CONSTRAINT fk_site_shifts__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_site_shifts__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT uq_site_shifts__site_id_name UNIQUE (site_id, name),
    CONSTRAINT ck_site_shifts__late_after_minutes CHECK (late_after_minutes IS NULL OR late_after_minutes BETWEEN 0 AND 1440),
    CONSTRAINT ck_site_shifts__half_day_minutes CHECK (half_day_minutes IS NULL OR half_day_minutes BETWEEN 0 AND 1440)
);
CREATE INDEX ix_site_shifts__site_id ON site_shifts (site_id);
CREATE TRIGGER trg_site_shifts__updated_at BEFORE UPDATE ON site_shifts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE site_shifts IS 'Shifts of a site (e.g. Morning Shift 09:00–18:00); users work one of their site''s shifts';
COMMENT ON COLUMN site_shifts.late_after_minutes IS 'minutes after the start time before a check-in counts as late';
COMMENT ON COLUMN site_shifts.half_day_minutes IS 'minutes worked below which the day is a half day';

-- the site's current timing becomes its first shift
INSERT INTO site_shifts (site_id, name, start_time, end_time, late_after_minutes, half_day_minutes, display_order)
SELECT id, 'General Shift', start_time, end_time, late_after_minutes, half_day_minutes, 1 FROM sites;

ALTER TABLE sites
    DROP CONSTRAINT IF EXISTS ck_sites__late_after_minutes,
    DROP CONSTRAINT IF EXISTS ck_sites__half_day_minutes,
    DROP COLUMN start_time,
    DROP COLUMN end_time,
    DROP COLUMN late_after_minutes,
    DROP COLUMN half_day_minutes;

-- users: the shift they work (one of their site's shifts)
ALTER TABLE users ADD COLUMN site_shift_id bigint;
UPDATE users u SET site_shift_id = ss.id FROM site_shifts ss WHERE ss.site_id = u.site_id;
ALTER TABLE users ADD CONSTRAINT fk_users__site_shift_id FOREIGN KEY (site_shift_id) REFERENCES site_shifts (id) ON DELETE RESTRICT;
CREATE INDEX ix_users__site_shift_id ON users (site_shift_id);
COMMENT ON COLUMN users.site_shift_id IS 'shift the user works – one of the shifts of users.site_id';

-- rosters / attendance: the shift of the day
ALTER TABLE rosters ADD COLUMN site_shift_id bigint;
UPDATE rosters r SET site_shift_id = ss.id FROM site_shifts ss WHERE ss.site_id = r.site_id;
ALTER TABLE rosters ADD CONSTRAINT fk_rosters__site_shift_id FOREIGN KEY (site_shift_id) REFERENCES site_shifts (id) ON DELETE RESTRICT;
CREATE INDEX ix_rosters__site_shift_id ON rosters (site_shift_id);

ALTER TABLE attendance ADD COLUMN site_shift_id bigint;
UPDATE attendance a SET site_shift_id = ss.id FROM site_shifts ss WHERE ss.site_id = a.site_id;
ALTER TABLE attendance ADD CONSTRAINT fk_attendance__site_shift_id FOREIGN KEY (site_shift_id) REFERENCES site_shifts (id) ON DELETE RESTRICT;
CREATE INDEX ix_attendance__site_shift_id ON attendance (site_shift_id);
