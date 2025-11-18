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
