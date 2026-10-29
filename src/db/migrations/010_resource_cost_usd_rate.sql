-- Every cost-per-hour period carries its conversion to USD: 1 unit of the cost's currency = usd_rate USD.
-- USD costs convert 1:1; older periods in other currencies get their rate when the grade is next saved.

ALTER TABLE resource_grade_costs ADD COLUMN usd_rate numeric(18,8);
ALTER TABLE resource_grade_costs ADD CONSTRAINT ck_resource_grade_costs__usd_rate CHECK (usd_rate IS NULL OR usd_rate > 0);
COMMENT ON COLUMN resource_grade_costs.usd_rate IS '1 unit of currency = usd_rate USD (1 for USD); cost in USD = cost_per_hour * usd_rate';

UPDATE resource_grade_costs SET usd_rate = 1 WHERE trim(currency) = 'USD';
