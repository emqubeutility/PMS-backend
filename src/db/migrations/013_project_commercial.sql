-- Commercial tab: besides the total project value (estimated_amount) and the members' cost, a project
-- has outsource, purchase and other values (in the project's currency). Only the project's manager sees them.

ALTER TABLE projects
    ADD COLUMN outsource_value numeric(14,2),
    ADD COLUMN purchase_value numeric(14,2),
    ADD COLUMN other_value numeric(14,2),
    ADD CONSTRAINT ck_projects__outsource_value CHECK (outsource_value IS NULL OR outsource_value >= 0),
    ADD CONSTRAINT ck_projects__purchase_value CHECK (purchase_value IS NULL OR purchase_value >= 0),
    ADD CONSTRAINT ck_projects__other_value CHECK (other_value IS NULL OR other_value >= 0);

COMMENT ON COLUMN projects.outsource_value IS 'Commercial tab: work outsourced to vendors (project currency)';
COMMENT ON COLUMN projects.purchase_value IS 'Commercial tab: purchases – licences, hardware … (project currency)';
COMMENT ON COLUMN projects.other_value IS 'Commercial tab: any other cost (project currency)';
