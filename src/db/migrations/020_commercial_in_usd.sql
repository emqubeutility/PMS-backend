-- Commercial tab works in USD for every project (USD rates: Parameters → CURRENCY).
-- Outsource / purchase / other values are stored in USD from now on: convert the existing ones from the
-- project's currency (left as they are when that currency has no USD rate yet).

UPDATE projects p
   SET outsource_value = round(p.outsource_value * l.usd_rate, 2),
       purchase_value = round(p.purchase_value * l.usd_rate, 2),
       other_value = round(p.other_value * l.usd_rate, 2)
  FROM lookups l
 WHERE l.type = 'CURRENCY'
   AND upper(trim(l.value)) = upper(trim(COALESCE(p.estimated_amount_currency, 'INR')))
   AND upper(trim(l.value)) <> 'USD'
   AND l.usd_rate IS NOT NULL
   AND (p.outsource_value IS NOT NULL OR p.purchase_value IS NOT NULL OR p.other_value IS NOT NULL);

COMMENT ON COLUMN projects.outsource_value IS 'Commercial tab: work outsourced to vendors (USD)';
COMMENT ON COLUMN projects.purchase_value IS 'Commercial tab: purchases – licences, hardware … (USD)';
COMMENT ON COLUMN projects.other_value IS 'Commercial tab: any other cost (USD)';
