ALTER TABLE project_user
ADD CONSTRAINT UC_ProjectIDUserID UNIQUE (project_id, user_id);