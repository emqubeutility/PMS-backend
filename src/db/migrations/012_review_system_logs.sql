-- Update tab log: besides comments and progress, the system adds a log entry when the stage changes
-- ("Stage changed from Draft to In Progress"). review_date is shown as the stage date.

ALTER TABLE project_reviews ADD COLUMN is_system boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN project_reviews.is_system IS 'true = log written by the system (e.g. stage changed), false = a user comment / progress entry';
COMMENT ON COLUMN project_reviews.review_date IS 'stage date: the date the stage / progress applies to';
