-- Consolidated seed data (duplicates removed)

-- account_type (canonical IDs + extras Enterprise/Internal)
INSERT INTO account_type (id, name, description) VALUES
  ('23c5a9f0-dcd3-416e-9132-29331f1828a9','Reseller','Account type representing reseller organizations'),
  ('7f567ce6-3fba-4633-b53e-a107f437aca4','Bose Pro','Account type representing internal Bose Professional team'),
  ('794ba404-548b-4366-a1b7-2adbc3a7facb','Distributor','Account type representing distributors or representatives'),
  ('8ba32e4b-b7a3-4663-baca-8281503dbf81','End User / System Owner','Account type representing customer or system owner'),
  ('f6cfb2d6-55fd-4ab7-ad37-e13e2917e383','Enterprise','Enterprise customer account'),
  ('b1f24ccf-3465-43b0-ba16-3081fa24a868','Internal','Internal Bose employee account');

-- Insert role data (latest roles)
INSERT INTO role (id, name, description) VALUES
  (1,'Super Admin','Highest administrative control'),
  (2,'Admin','Organization administrator'),
  (3,'Designer','Creates and manages projects'),
  (4,'Technician','Onsite installation & commissioning'),
  (5,'Design Assistance','Supports design activities'),
  (6,'Service','Post-install support & troubleshooting'),
  (7,'Operator','Operates system with limited adjustments'),
  (8,'Guest','Restricted access for demo');

INSERT INTO access_level (id, key, label) VALUES
  (1,'not_visible','Not Visible'),
  (2,'read','Read Only'),
  (3,'edit','Edit');

INSERT INTO account (id, name, description, account_type_id, created_at) VALUES
  ('0c688469-70ba-4104-a51c-c5307c456158','Reseller-Test-Account-1','Test Reseller organization','23c5a9f0-dcd3-416e-9132-29331f1828a9','2025-11-06 01:56:19.037524'),
  ('50000001-0000-4000-8000-000000000001','Bose Corporation','Main administrative account','7f567ce6-3fba-4633-b53e-a107f437aca4','2024-01-15 10:00:00'),
  ('50000001-0000-4000-8000-000000000002','AudioTech Solutions','Authorized reseller NA','23c5a9f0-dcd3-416e-9132-29331f1828a9','2024-02-10 14:30:00'),
  ('50000001-0000-4000-8000-000000000003','Sound Dynamics LLC','Regional reseller Southeast','23c5a9f0-dcd3-416e-9132-29331f1828a9','2024-02-20 09:15:00'),
  ('50000001-0000-4000-8000-000000000004','Metro Conference Center','Corporate end user','8ba32e4b-b7a3-4663-baca-8281503dbf81','2024-03-05 11:45:00'),
  ('50000001-0000-4000-8000-000000000005','University Audio Labs','Education end user','8ba32e4b-b7a3-4663-baca-8281503dbf81','2024-03-12 16:20:00'),
  ('50000001-0000-4000-8000-000000000006','Event Productions Inc','Event management company','8ba32e4b-b7a3-4663-baca-8281503dbf81','2024-03-18 13:10:00');

INSERT INTO account_type_role (id, account_type_id, role_id) VALUES
  (1,'23c5a9f0-dcd3-416e-9132-29331f1828a9',2), -- Reseller Admin
  (2,'23c5a9f0-dcd3-416e-9132-29331f1828a9',3), -- Reseller Designer
  (3,'23c5a9f0-dcd3-416e-9132-29331f1828a9',4), -- Reseller Technician
  (4,'7f567ce6-3fba-4633-b53e-a107f437aca4',1), -- Bose Pro Super Admin
  (5,'7f567ce6-3fba-4633-b53e-a107f437aca4',5), -- Bose Pro Design Assistance
  (6,'7f567ce6-3fba-4633-b53e-a107f437aca4',6), -- Bose Pro Service
  (7,'794ba404-548b-4366-a1b7-2adbc3a7facb',5), -- Distributor Design Assistance
  (8,'794ba404-548b-4366-a1b7-2adbc3a7facb',6), -- Distributor Service
  (9,'8ba32e4b-b7a3-4663-baca-8281503dbf81',2), -- End User Admin
  (10,'8ba32e4b-b7a3-4663-baca-8281503dbf81',7), -- End User Operator
  (11,'8ba32e4b-b7a3-4663-baca-8281503dbf81',8); -- End User Guest

-- feature (extended project permissions replacing earlier project_file.* names)
INSERT INTO feature (id, name, description) VALUES
  (1,'project.create','Can create a new or duplicate project file'),
  (2,'project.grant_access','Can grant access to other users for the project file'),
  (3,'building.view','Defines access to Building Section'),
  (4,'building.cost_estimator_widget','Defines access to Building - Cost Estimator Widget'),
  (5,'cost_estimator.view','Defines access to Cost Estimator Section'),
  (6,'schematic.view','Defines access to Schematic Section'),
  (7,'configuration.view','Defines access to Configuration Section'),
  (8,'commissioning.view','Defines access to Commissioning Section'),
  (9,'project.read','Can read all the projects of an account or a user'),
  (10,'project.update','Can update a project'),
  (11,'project.delete','Can delete a project'),
  (12,'project.archive','Can archive a project'),
  (13,'project.unarchive','Can unarchive a project'),
  (14,'project.lock','Can lock a project'),
  (15,'project.unlock','Can unlock a project'),
  (16,'project.start','Can star a project'),
  (17,'project.unstar','Can unstar a project'),
  (18,'project.assign_user','Can assign a user to a project'),
  (19,'project.remove_user','Can remove a user from a project');

INSERT INTO feature_permission (id, feature_id, account_type_role_id, access_level_id, created_at) VALUES
  -- project_file.create
  (1,1,1,3,now()),(2,1,2,3,now()),(3,1,3,3,now()),(4,1,4,3,now()),(5,1,5,3,now()),(6,1,6,3,now()),(7,1,7,3,now()),(8,1,8,3,now()),(9,1,9,3,now()),(10,1,10,1,now()),(11,1,11,1,now()),
  -- project_file.grant_access
  (12,2,1,3,now()),(13,2,2,3,now()),(14,2,3,2,now()),(15,2,4,3,now()),(16,2,5,3,now()),(17,2,6,3,now()),(18,2,7,3,now()),(19,2,8,3,now()),(20,2,9,3,now()),(21,2,10,2,now()),(22,2,11,2,now()),
  -- building.view
  (23,3,1,3,now()),(24,3,2,3,now()),(25,3,3,3,now()),(26,3,4,3,now()),(27,3,5,3,now()),(28,3,6,3,now()),(29,3,7,3,now()),(30,3,8,3,now()),(31,3,9,2,now()),(32,3,10,2,now()),(33,3,11,1,now()),
  -- building.cost_estimator_widget
  (34,4,1,3,now()),(35,4,2,3,now()),(36,4,3,3,now()),(37,4,4,3,now()),(38,4,5,3,now()),(39,4,6,3,now()),(40,4,7,3,now()),(41,4,8,3,now()),(42,4,9,1,now()),(43,4,10,1,now()),(44,4,11,1,now()),
  -- cost_estimator.view
  (45,5,1,3,now()),(46,5,2,3,now()),(47,5,3,3,now()),(48,5,4,3,now()),(49,5,5,3,now()),(50,5,6,3,now()),(51,5,7,3,now()),(52,5,8,3,now()),(53,5,9,1,now()),(54,5,10,1,now()),(55,5,11,1,now()),
  -- schematic.view
  (56,6,1,3,now()),(57,6,2,3,now()),(58,6,3,3,now()),(59,6,4,3,now()),(60,6,5,3,now()),(61,6,6,3,now()),(62,6,7,3,now()),(63,6,8,3,now()),(64,6,9,2,now()),(65,6,10,2,now()),(66,6,11,1,now()),
  -- configuration.view
  (67,7,1,3,now()),(68,7,2,3,now()),(69,7,3,3,now()),(70,7,4,3,now()),(71,7,5,3,now()),(72,7,6,3,now()),(73,7,7,3,now()),(74,7,8,3,now()),(75,7,9,2,now()),(76,7,10,2,now()),(77,7,11,1,now()),
  -- commissioning.view
  (78,8,1,3,now()),(79,8,2,3,now()),(80,8,3,3,now()),(81,8,4,3,now()),(82,8,5,3,now()),(83,8,6,3,now()),(84,8,7,3,now()),(85,8,8,3,now()),(86,8,9,2,now()),(87,8,10,2,now()),(88,8,11,1,now());

-- Insert app_user data (mapping to account_type_role IDs and uuid accounts)
INSERT INTO app_user (id, email, full_name, account_type_role_id, account_id, created_at, updated_at) VALUES
  ('60000001-0000-4000-8000-000000000001','admin@bose.com','John Administrator',4,'50000001-0000-4000-8000-000000000001','2024-01-15 10:30:00','2024-01-15 10:30:00'),
  ('60000001-0000-4000-8000-000000000002','service@bose.com','Sarah Service',6,'50000001-0000-4000-8000-000000000001','2024-01-16 09:15:00','2024-01-16 09:15:00'),
  ('60000001-0000-4000-8000-000000000003','mike.designer@audiotech.com','Mike Designer',2,'50000001-0000-4000-8000-000000000002','2024-02-10 15:00:00','2024-02-10 15:00:00'),
  ('60000001-0000-4000-8000-000000000004','lisa.tech@audiotech.com','Lisa Technician',3,'50000001-0000-4000-8000-000000000002','2024-02-12 11:20:00','2024-02-12 11:20:00'),
  ('60000001-0000-4000-8000-000000000005','alex.designer@sounddynamics.com','Alex Designer',2,'50000001-0000-4000-8000-000000000003','2024-02-20 10:00:00','2024-02-20 10:00:00'),
  ('60000001-0000-4000-8000-000000000006','test@domain.com','David Admin',9,'50000001-0000-4000-8000-000000000004','2024-03-05 12:30:00','2024-03-05 12:30:00'),
  ('60000001-0000-4000-8000-000000000007','prof.operator@university.edu','Professor Operator',10,'50000001-0000-4000-8000-000000000005','2024-03-12 17:00:00','2024-03-12 17:00:00'),
  ('60000001-0000-4000-8000-000000000008','emily.service@eventproductions.com','Emily Service',6,'50000001-0000-4000-8000-000000000006','2024-03-18 14:15:00','2024-03-18 14:15:00'),
  ('60000001-0000-4000-8000-000000000009','guest@metroconference.com','Metro Guest',11,'50000001-0000-4000-8000-000000000004','2024-03-06 09:45:00','2024-03-06 09:45:00'),
  ('60000001-0000-4000-8000-000000000010','fusion.reseller.sa@gmail.com','Fusion Reseller Admin',9,'50000001-0000-4000-8000-000000000004','2024-03-05 12:30:00','2024-03-05 12:30:00');

-- Insert project data (primary_owner_account_id now UUID)
INSERT INTO project (id, application, budget_amount, currency, description, name, project_phase, venue, environment_type, is_archived, is_deleted, locked_by_user_id, primary_owner_account_id, created_at, updated_at) VALUES
 ('30000001-0000-4000-8000-000000000001','Corporate Conference Room',75000.00,'USD','High-end boardroom audio','Metro Conference Center - Executive Boardroom','planning','Metro Conference Center','indoor',false,false,NULL,'50000001-0000-4000-8000-000000000004','2024-03-10 09:00:00','2024-03-15 14:30:00'),
 ('30000001-0000-4000-8000-000000000002','Educational Facility',45000.00,'USD','University lecture hall upgrade','University Audio Labs - Lecture Hall Upgrade','design','University Campus Building A','indoor',false,false,'60000001-0000-4000-8000-000000000007','50000001-0000-4000-8000-000000000005','2024-03-15 11:20:00','2024-03-20 16:45:00'),
 ('30000001-0000-4000-8000-000000000003','Event Production',120000.00,'USD','Outdoor festival sound system','Summer Music Festival 2024','implementation','Central Park Amphitheater','outdoor',false,false,NULL,'50000001-0000-4000-8000-000000000006','2024-02-28 08:15:00','2024-04-02 12:00:00'),
 ('30000001-0000-4000-8000-000000000004','Retail Showroom',32000.00,'USD','Interactive demo showroom','AudioTech Solutions - Demo Showroom','completed','AudioTech Solutions Store','indoor',false,false,NULL,'50000001-0000-4000-8000-000000000002','2024-01-20 10:30:00','2024-02-25 17:20:00');

-- Insert project_user data (user-project associations)
INSERT INTO project_user (id, project_id, user_id, is_starred, created_at, updated_at) VALUES
 (1,'30000001-0000-4000-8000-000000000001','60000001-0000-4000-8000-000000000006',true,'2024-03-10 09:30:00','2024-03-12 10:15:00'),
 (2,'30000001-0000-4000-8000-000000000001','60000001-0000-4000-8000-000000000003',false,'2024-03-10 10:00:00','2024-03-10 10:00:00'),
 (3,'30000001-0000-4000-8000-000000000002','60000001-0000-4000-8000-000000000007',true,'2024-03-15 11:45:00','2024-03-18 14:20:00'),
 (4,'30000001-0000-4000-8000-000000000002','60000001-0000-4000-8000-000000000009',false,'2024-03-16 09:30:00','2024-03-16 09:30:00'),
 (5,'30000001-0000-4000-8000-000000000003','60000001-0000-4000-8000-000000000008',true,'2024-02-28 08:45:00','2024-03-01 16:30:00'),
 (6,'30000001-0000-4000-8000-000000000003','60000001-0000-4000-8000-000000000004',false,'2024-03-01 12:15:00','2024-03-01 12:15:00'),
 (7,'30000001-0000-4000-8000-000000000004','60000001-0000-4000-8000-000000000003',false,'2024-01-20 11:00:00','2024-01-20 11:00:00'),
 (8,'30000001-0000-4000-8000-000000000004','60000001-0000-4000-8000-000000000004',true,'2024-01-22 14:20:00','2024-02-15 10:45:00');

-- Product-related test data (unchanged relative to new schema)
INSERT INTO product (product_id, product_type, model_name, model_family, description, short_description, images, specifications, created_at, updated_at) VALUES
  (1001,'speaker','DM2SE','DesignMax','Surface-mount loudspeaker','Premium surface-mount speaker','{"primary":["https://example.com/images/dm2se_front.png"]}'::jsonb,'{"power_handling":"25W"}'::jsonb,'2024-01-10 08:00:00','2024-01-10 08:00:00'),
  (1002,'amplifier','PWR4X100','PowerSeries','4-channel digital amplifier','4ch DSP amplifier','{"primary":["https://example.com/images/pwr4x100_front.png"]}'::jsonb,'{"channels":4}'::jsonb,'2024-01-10 08:05:00','2024-01-10 08:05:00');

INSERT INTO product_price (product_id, variant, currency, price, created_at, updated_at) VALUES
  (1001,'black','USD',299.99,'2024-01-10 08:30:00','2024-01-10 08:30:00'),
  (1002,'standard','USD',1299.99,'2024-01-10 08:35:00','2024-01-10 08:35:00');

INSERT INTO product_sync_job (sync_operation, status, s3_bucket, s3_key, file_size_bytes, error_message, validation_errors, total_items, successful_items, failed_items, version, started_at, completed_at) VALUES
 ('full_sync','completed','fusion-product-import','imports/2024/01/full_catalog.json',524288,NULL,'{"warnings":[],"errors":[]}'::jsonb,150,150,0,'v1','2024-01-11 09:00:00','2024-01-11 09:02:30');

SELECT setval('role_id_seq',8,true);
SELECT setval('access_level_id_seq',3,true);
SELECT setval('account_type_role_id_seq',11,true);
SELECT setval('feature_id_seq',19,true);
SELECT setval('feature_permission_id_seq',88,true);
SELECT setval('project_user_id_seq',8,true);

-- Grant full project feature access to account_type_role_id 9 (End User Admin)
-- Existing create permission updated above; now insert remaining project features (IDs 9-19)
INSERT INTO feature_permission (id, feature_id, account_type_role_id, access_level_id, created_at) VALUES
  (89,9,9,3,now()),   -- project.read
  (90,10,9,3,now()),  -- project.update
  (91,11,9,3,now()),  -- project.delete
  (92,12,9,3,now()),  -- project.archive
  (93,13,9,3,now()),  -- project.unarchive
  (94,14,9,3,now()),  -- project.lock
  (95,15,9,3,now()),  -- project.unlock
  (96,16,9,3,now()),  -- project.start (star)
  (97,17,9,3,now()),  -- project.unstar
  (98,18,9,3,now()),  -- project.assign_user
  (99,19,9,3,now());  -- project.remove_user

-- Advance sequence to latest id
SELECT setval('feature_permission_id_seq',99,true);

-- (Removed prior duplicate COPY-converted INSERT blocks.)

-- Insert data to User profile table
INSERT INTO user_profile (user_id, email, first_name, last_name, job_title, phone, address_line_1, city, state_province, country, zip_postal_code, gdpr_opt_out, privacy_policy_accepted, timezone, unit_system, customer_type, company_name, currency)
VALUES ('60000001-0000-4000-8000-000000000006', 'test@domain.com', 'David', 'Admin', 'Audio Engineer', '+1-555-0101', '123 Main Street', 'New York', 'NY', 'USA', '10001', false, true, 'America/New_York', 'imperial', 'enterprise', 'Acme Corp', 'USD');

-- Insert data to User settings table
INSERT INTO user_settings (user_id, language, theme)
VALUES ('60000001-0000-4000-8000-000000000006', 'en-US', 'system');