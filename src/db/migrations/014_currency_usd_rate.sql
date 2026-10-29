-- The USD conversion moves from each resource-grade cost period to the currency itself
-- (Parameters → CURRENCY): 1 unit of the currency = usd_rate USD. Required for currencies.

ALTER TABLE lookups ADD COLUMN usd_rate numeric(18,8);
ALTER TABLE lookups ADD CONSTRAINT ck_lookups__usd_rate CHECK (usd_rate IS NULL OR usd_rate > 0);
COMMENT ON COLUMN lookups.usd_rate IS 'CURRENCY only: 1 unit of the currency = usd_rate USD (1 for USD)';

-- carry over: USD = 1, other currencies take the latest rate used on a resource-grade cost
UPDATE lookups SET usd_rate = 1 WHERE type = 'CURRENCY' AND upper(trim(value)) = 'USD';
UPDATE lookups l
   SET usd_rate = r.usd_rate
  FROM (SELECT DISTINCT ON (trim(currency)) trim(currency) AS currency, usd_rate
          FROM resource_grade_costs WHERE usd_rate IS NOT NULL
         ORDER BY trim(currency), from_date DESC) r
 WHERE l.type = 'CURRENCY' AND upper(trim(l.value)) = r.currency AND l.usd_rate IS NULL;

ALTER TABLE resource_grade_costs DROP CONSTRAINT IF EXISTS ck_resource_grade_costs__usd_rate;
ALTER TABLE resource_grade_costs DROP COLUMN usd_rate;
