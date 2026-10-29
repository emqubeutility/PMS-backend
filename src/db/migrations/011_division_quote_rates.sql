-- Quote rate per hour of a business division, one per currency (e.g. Software: INR 1500 / hr, USD 25 / hr).
-- A project's estimated hours = its total estimate amount / the division's quote rate in the project's currency.

CREATE TABLE project_division_quote_rates (
    id bigint GENERATED ALWAYS AS IDENTITY,
    project_division_id bigint NOT NULL,
    currency char(3) NOT NULL,
    rate_per_hour numeric(12,2) NOT NULL,
    created_by bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_by bigint,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_project_division_quote_rates PRIMARY KEY (id),
    CONSTRAINT fk_project_division_quote_rates__division FOREIGN KEY (project_division_id) REFERENCES project_divisions (id) ON DELETE CASCADE,
    CONSTRAINT fk_project_division_quote_rates__created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_project_division_quote_rates__updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT uq_project_division_quote_rates__division_currency UNIQUE (project_division_id, currency),
    CONSTRAINT ck_project_division_quote_rates__rate CHECK (rate_per_hour > 0)
);
CREATE TRIGGER trg_project_division_quote_rates__updated_at BEFORE UPDATE ON project_division_quote_rates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
COMMENT ON TABLE project_division_quote_rates IS 'Quote rate per hour of a division per currency; project estimated hours = estimate amount / rate';
