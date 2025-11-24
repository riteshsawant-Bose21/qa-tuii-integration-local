CREATE TABLE "account_type" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(256) UNIQUE NOT NULL,
  "description" text
);

CREATE TABLE "account" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(150) UNIQUE NOT NULL,
  "description" varchar(200),
  "account_type_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "role" (
  "id" serial PRIMARY KEY,
  "name" varchar(100) UNIQUE NOT NULL,
  "description" text
);

CREATE TABLE "account_type_role" (
  "id" serial PRIMARY KEY,
  "account_type_id" uuid NOT NULL,
  "role_id" int NOT NULL
);

CREATE TABLE "feature" (
  "id" serial PRIMARY KEY,
  "name" varchar(200) UNIQUE NOT NULL,
  "description" text
);

CREATE TABLE "access_level" (
  "id" serial PRIMARY KEY,
  "key" varchar(50) UNIQUE NOT NULL,
  "label" varchar(100) NOT NULL
);

CREATE TABLE "feature_permission" (
  "id" serial PRIMARY KEY,
  "feature_id" int NOT NULL,
  "account_type_role_id" int NOT NULL,
  "access_level_id" int NOT NULL,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "app_user" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "email" varchar(255) UNIQUE NOT NULL,
  "full_name" varchar(255),
  "account_type_role_id" int NOT NULL,
  "account_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp
);

ALTER TABLE "account" ADD FOREIGN KEY ("account_type_id") REFERENCES "account_type" ("id");
ALTER TABLE "account_type_role" ADD FOREIGN KEY ("account_type_id") REFERENCES "account_type" ("id");
ALTER TABLE "account_type_role" ADD FOREIGN KEY ("role_id") REFERENCES "role" ("id");
ALTER TABLE "feature_permission" ADD FOREIGN KEY ("feature_id") REFERENCES "feature" ("id");
ALTER TABLE "feature_permission" ADD FOREIGN KEY ("account_type_role_id") REFERENCES "account_type_role" ("id");
ALTER TABLE "feature_permission" ADD FOREIGN KEY ("access_level_id") REFERENCES "access_level" ("id");
ALTER TABLE "app_user" ADD FOREIGN KEY ("account_type_role_id") REFERENCES "account_type_role" ("id");
ALTER TABLE "app_user" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");

INSERT INTO account_type (id, name, description)
VALUES
  (gen_random_uuid(), 'Reseller', 'Account type representing reseller organizations'),
  (gen_random_uuid(), 'Bose Pro', 'Account type representing internal Bose Professional team'),
  (gen_random_uuid(), 'Distributor', 'Account type representing distributors or representatives'),
  (gen_random_uuid(), 'End User / System Owner', 'Account type representing customer or system owner');

INSERT INTO role (name, description)
VALUES
  ('Super Admin', 'Holds the highest level of administrative control across all Fusion accounts. Manages users, roles, and project transfers across resellers. Oversees analytics, usability, and IT operations.'),
  ('Admin', 'Manages the organization with full visibility and administrative rights. Can add or remove users, view accurate pricing, and track project progress.'),
  ('Designer', 'Oversees the full lifecycle of a customer project, from creation through performance monitoring. Can create projects, buildings, and schematics; configure and commission systems; and maintain overall project performance.'),
  ('Technician', 'Handles onsite installation, commissioning, and end-user training. Can configure technical functions that require physical presence or setup.'),
  ('Design Assistance', 'Supports resellers by editing projects and assisting with system design. Typically Bose internal RSEs or third-party distributors providing design support.'),
  ('Service', 'Provides post-installation and commissioning support. Connects to customer systems for troubleshooting, maintenance, and debugging assistance.'),
  ('Operator', 'Operates the system with limited adjustment permissions. Can monitor, make small changes (volume, presets, source selection, etc.), and view system control dashboards.'),
  ('Guest', 'Has limited access to defined zones or system sections with basic control only. Intended for demo or restricted access scenarios.');

INSERT INTO access_level (key, label)
VALUES
  ('not_visible', 'Not Visible'),
  ('read', 'Read Only'),
  ('edit', 'Edit');

INSERT INTO account_type_role (account_type_id, role_id)
VALUES
  -- Reseller
  ('23c5a9f0-dcd3-416e-9132-29331f1828a9', 2), -- Admin
  ('23c5a9f0-dcd3-416e-9132-29331f1828a9', 3), -- Designer
  ('23c5a9f0-dcd3-416e-9132-29331f1828a9', 4), -- Technician

  -- Bose Pro
  ('7f567ce6-3fba-4633-b53e-a107f437aca4', 1), -- Super Admin
  ('7f567ce6-3fba-4633-b53e-a107f437aca4', 5), -- Design Assistance
  ('7f567ce6-3fba-4633-b53e-a107f437aca4', 6), -- Service

  -- Distributor
  ('794ba404-548b-4366-a1b7-2adbc3a7facb', 5), -- Design Assistance
  ('794ba404-548b-4366-a1b7-2adbc3a7facb', 6), -- Service

  -- End User / System Owner
  ('8ba32e4b-b7a3-4663-baca-8281503dbf81', 2), -- Admin
  ('8ba32e4b-b7a3-4663-baca-8281503dbf81', 7), -- Operator
  ('8ba32e4b-b7a3-4663-baca-8281503dbf81', 8);  -- Guest

INSERT INTO feature (name, description)
VALUES
  ('project_file.create', 'Can create a new or duplicate project file'),
  ('project_file.grant_access', 'Can grant access to other users for the project file'),
  ('building.view', 'Defines access to Building Section'),
  ('building.cost_estimator_widget', 'Defines access to Building - Cost Estimator Widget'),
  ('cost_estimator.view', 'Defines access to Cost Estimator Section'),
  ('schematic.view', 'Defines access to Schematic Section'),
  ('configuration.view', 'Defines access to Configuration Section'),
  ('commissioning.view', 'Defines access to Commissioning Section');


INSERT INTO feature_permission (feature_id, account_type_role_id, access_level_id) VALUES
  -- feature 1: project_file.create
  (1, 1, 3),  -- Reseller: Admin -> edit
  (1, 2, 3),  -- Reseller: Designer -> edit
  (1, 3, 3),  -- Reseller: Technician -> edit
  (1, 4, 3),  -- Bose Pro: Super Admin -> edit
  (1, 5, 3),  -- Bose Pro: Design Assist -> edit
  (1, 6, 3),  -- Bose Pro: Service -> edit
  (1, 7, 3),  -- Distributor: Design Assist -> edit
  (1, 8, 3),  -- Distributor: Service -> edit
  (1, 9, 1),  -- End User: Admin -> not_visible
  (1, 10, 1), -- End User: Operator -> not_visible
  (1, 11, 1), -- End User: Guest -> not_visible

  -- feature 2: project_file.grant_access
  (2, 1, 3),  -- Reseller: Admin -> edit
  (2, 2, 3),  -- Reseller: Designer -> edit
  (2, 3, 2),  -- Reseller: Technician -> read
  (2, 4, 3),  -- Bose Pro: Super Admin -> edit
  (2, 5, 3),  -- Bose Pro: Design Assist -> edit
  (2, 6, 3),  -- Bose Pro: Service -> edit
  (2, 7, 3),  -- Distributor: Design Assist -> edit
  (2, 8, 3),  -- Distributor: Service -> edit
  (2, 9, 3),  -- End User: Admin -> edit
  (2, 10, 2), -- End User: Operator -> read
  (2, 11, 2), -- End User: Guest -> read

  -- feature 3: building.view
  (3, 1, 3),
  (3, 2, 3),
  (3, 3, 3),
  (3, 4, 3),
  (3, 5, 3),
  (3, 6, 3),
  (3, 7, 3),
  (3, 8, 3),
  (3, 9, 2),
  (3, 10, 2),
  (3, 11, 1),

  -- feature 4: building.cost_estimator_widget
  (4, 1, 3),
  (4, 2, 3),
  (4, 3, 3),
  (4, 4, 3),
  (4, 5, 3),
  (4, 6, 3),
  (4, 7, 3),
  (4, 8, 3),
  (4, 9, 1),
  (4, 10, 1),
  (4, 11, 1),

  -- feature 5: cost_estimator.view
  (5, 1, 3),
  (5, 2, 3),
  (5, 3, 3),
  (5, 4, 3),
  (5, 5, 3),
  (5, 6, 3),
  (5, 7, 3),
  (5, 8, 3),
  (5, 9, 1),
  (5, 10, 1),
  (5, 11, 1),

  -- feature 6: schematic.view
  (6, 1, 3),
  (6, 2, 3),
  (6, 3, 3),
  (6, 4, 3),
  (6, 5, 3),
  (6, 6, 3),
  (6, 7, 3),
  (6, 8, 3),
  (6, 9, 2),
  (6, 10, 2),
  (6, 11, 1),

  -- feature 7: configuration.view
  (7, 1, 3),
  (7, 2, 3),
  (7, 3, 3),
  (7, 4, 3),
  (7, 5, 3),
  (7, 6, 3),
  (7, 7, 3),
  (7, 8, 3),
  (7, 9, 2),
  (7, 10, 2),
  (7, 11, 1),

  -- feature 8: commissioning.view
  (8, 1, 3),
  (8, 2, 3),
  (8, 3, 3),
  (8, 4, 3),
  (8, 5, 3),
  (8, 6, 3),
  (8, 7, 3),
  (8, 8, 3),
  (8, 9, 2),
  (8, 10, 2),
  (8, 11, 1);

