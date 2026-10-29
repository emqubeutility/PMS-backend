-- Parameters in three tables (Administration → Parameters, three tabs):
--   parameter_types      the parameters themselves (COUNTRY, CURRENCY, SKILL …)        → "Parameters" tab
--   lookups              their values (India, AED, Developer …) – lookups.type → code  → "Parameter Values" tab
--   currency_usd_rates   one current USD rate per currency value                        → "USD Rates" tab
-- (lookups.usd_rate moves to currency_usd_rates; v_currency_usd_rates gives code → rate for calculations)

CREATE TABLE parameter_types (
    id bigint GENERATED ALWAYS AS IDENTITY,
    code varchar(50) NOT NULL,
    name varchar(100) NOT NULL,
    description text,
    is_system boolean NOT NULL DEFAULT false,
    display_order int NOT NULL DEFAULT 0,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_parameter_types PRIMARY KEY (id),
    CONSTRAINT uq_parameter_types__code UNIQUE (code),
    CONSTRAINT ck_parameter_types__code CHECK (code ~ '^[A-Z][A-Z0-9_]*$'),
    CONSTRAINT fk_parameter_types__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_parameter_types__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE TRIGGER trg_parameter_types__updated_at BEFORE UPDATE ON parameter_types FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE parameter_types IS 'Parameters (lists of values used in dropdowns); their values are in lookups';
COMMENT ON COLUMN parameter_types.is_system IS 'used by the application – the code cannot change and it cannot be deleted';

-- the ones the application relies on
INSERT INTO parameter_types (code, name, description, is_system, display_order) VALUES
    ('USER_TYPE', 'User Type', 'Kind of user (employee, contractor, customer user …)', true, 1),
    ('COUNTRY', 'Country', 'Countries for customers, teams and sites', true, 2),
    ('CURRENCY', 'Currency', 'Currencies; value = ISO code (INR, AED, USD …). USD rates are on the USD Rates tab', true, 3),
    ('GRADE', 'Grade', 'Resource grade levels (Resource Grade & Cost)', true, 4),
    ('SKILL', 'Skill', 'Skills of users and the skills template tasks need', true, 5),
    ('PROJECT_STAGE', 'Project Stage', 'Managed on Administration → Project Stages', true, 99)
ON CONFLICT (code) DO NOTHING;
-- any other type already in use becomes a (non-system) parameter
INSERT INTO parameter_types (code, name, display_order)
SELECT DISTINCT l.type, initcap(replace(lower(l.type), '_', ' ')), 50
  FROM lookups l
 WHERE l.type ~ '^[A-Z][A-Z0-9_]*$'
ON CONFLICT (code) DO NOTHING;

ALTER TABLE lookups
    ADD CONSTRAINT fk_lookups__type FOREIGN KEY (type) REFERENCES parameter_types (code) ON UPDATE CASCADE ON DELETE RESTRICT;

-- USD rates
CREATE TABLE currency_usd_rates (
    currency_id bigint NOT NULL,
    usd_rate numeric(18,8) NOT NULL,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_currency_usd_rates PRIMARY KEY (currency_id),
    CONSTRAINT ck_currency_usd_rates__rate CHECK (usd_rate > 0),
    CONSTRAINT fk_currency_usd_rates__currency_id FOREIGN KEY (currency_id) REFERENCES lookups (id) ON DELETE CASCADE,
    CONSTRAINT fk_currency_usd_rates__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_currency_usd_rates__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
CREATE TRIGGER trg_currency_usd_rates__updated_at BEFORE UPDATE ON currency_usd_rates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE currency_usd_rates IS 'Current USD rate of each currency: 1 unit of the currency = usd_rate USD';

INSERT INTO currency_usd_rates (currency_id, usd_rate)
SELECT id, usd_rate FROM lookups WHERE type = 'CURRENCY' AND usd_rate IS NOT NULL
ON CONFLICT (currency_id) DO NOTHING;

ALTER TABLE lookups DROP CONSTRAINT IF EXISTS ck_lookups__usd_rate;
ALTER TABLE lookups DROP COLUMN usd_rate;

-- currency code → USD rate (USD is always 1) for the commercial / cost calculations
CREATE VIEW v_currency_usd_rates AS
SELECT l.id AS currency_id,
       upper(trim(l.value)) AS code,
       CASE WHEN upper(trim(l.value)) = 'USD' THEN 1::numeric ELSE r.usd_rate END AS usd_rate
  FROM lookups l
  LEFT JOIN currency_usd_rates r ON r.currency_id = l.id
 WHERE l.type = 'CURRENCY';
COMMENT ON VIEW v_currency_usd_rates IS 'currency code → USD rate (null = not set yet)';
