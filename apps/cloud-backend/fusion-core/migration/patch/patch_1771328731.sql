
CREATE TYPE bundle_approval_status_enum AS ENUM (
    'PENDING',
    'APPROVED',
    'REVOKED'
);

CREATE TABLE bundle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
    version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(version, '+', 1), '-', 1), '.' )::INT[] ) stored,
    prerelease_tag TEXT,      -- Channel tag for filtering: "alpha", "beta", "dev", NULL for stable
    prerelease_num INT,       -- Numeric part for ordering within channel: 1, 2, 5... NULL if absent
    release_notes TEXT,
    min_prev_version TEXT NOT NULL,
    min_prev_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(min_prev_version, '+', 1), '-', 1), '.' )::INT[] ) STORED,
    min_desktop_app_version TEXT NOT NULL,
    min_desktop_app_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(min_desktop_app_version, '+', 1), '-', 1), '.' )::INT[] ) STORED,
    manifest_data JSONB,
    checksum VARCHAR(64) NOT NULL,
    s3_path TEXT NOT NULL,
    approval_status bundle_approval_status_enum NOT NULL DEFAULT 'PENDING',
    approval_status_changed_by UUID references app_user(id),
    approval_status_changed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TYPE bundle_update_status_enum AS ENUM (
    'INSTALL_SUCCESS',
    'INSTALL_FAIL'
);
CREATE TABLE bundle_update_status (
    id UUID PRIMARY KEY,         
    update_id UUID NOT null UNIQUE,
    project_id UUID NOT NULL references project(id),
    bundle_version TEXT NOT NULL,      
    previous_version TEXT,
    status bundle_update_status_enum NOT NULL,             
    launcher_version TEXT,    
    installed_at TIMESTAMPTZ NOT null,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- permission tables data
INSERT INTO feature (name, description)
VALUES
  ('firmware.bundle.read', 'Can view and list firmware bundles'),
  ('firmware.bundle.create', 'Can upload new firmware bundles'),
  ('firmware.bundle.approve', 'Can approve firmware bundles for release'),
  ('firmware.update.check', 'Can check for available firmware updates'),
  ('firmware.download', 'Can download firmware bundles'),
  ('firmware.update.log', 'Can log firmware update status');

SELECT setval('feature_permission_id_seq', (SELECT MAX(id) FROM feature_permission));

INSERT INTO feature_permission (feature_id, account_type_role_id, access_level_id) VALUES
  -- feature: firmware.bundle.read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 1, 2),   -- Reseller: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 2, 2),   -- Reseller: Designer -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 3, 2),   -- Reseller: Technician -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 4, 2),   -- Bose Pro: Super Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 5, 2),   -- Bose Pro: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 6, 2),   -- Bose Pro: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 7, 2),   -- Distributor: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 8, 2),   -- Distributor: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 9, 2),   -- End User: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 10, 2),  -- End User: Operator -> read
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.read'), 11, 1),  -- End User: Guest -> not_visible

  -- feature: firmware.bundle.create (internal only)
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 1, 1),  -- Reseller: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 2, 1),  -- Reseller: Designer -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 3, 1),  -- Reseller: Technician -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 4, 3),  -- Bose Pro: Super Admin -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 5, 1),  -- Bose Pro: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 6, 1),  -- Bose Pro: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 7, 1),  -- Distributor: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 8, 1),  -- Distributor: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 9, 1),  -- End User: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 10, 1), -- End User: Operator -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.create'), 11, 1), -- End User: Guest -> not_visible

  -- feature: firmware.bundle.approve (admin only)
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 1, 1),  -- Reseller: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 2, 1),  -- Reseller: Designer -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 3, 1),  -- Reseller: Technician -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 4, 3),  -- Bose Pro: Super Admin -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 5, 1),  -- Bose Pro: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 6, 1),  -- Bose Pro: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 7, 1),  -- Distributor: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 8, 1),  -- Distributor: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 9, 1),  -- End User: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 10, 1), -- End User: Operator -> not_visible
  ((SELECT id FROM feature WHERE name = 'firmware.bundle.approve'), 11, 1), -- End User: Guest -> not_visible

  -- feature: firmware.update.check
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 1, 2),  -- Reseller: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 2, 2),  -- Reseller: Designer -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 3, 2),  -- Reseller: Technician -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 4, 2),  -- Bose Pro: Super Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 5, 2),  -- Bose Pro: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 6, 2),  -- Bose Pro: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 7, 2),  -- Distributor: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 8, 2),  -- Distributor: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 9, 2),  -- End User: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 10, 2), -- End User: Operator -> read
  ((SELECT id FROM feature WHERE name = 'firmware.update.check'), 11, 1), -- End User: Guest -> not_visible

  -- feature: firmware.download
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 1, 2),  -- Reseller: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 2, 2),  -- Reseller: Designer -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 3, 2),  -- Reseller: Technician -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 4, 2),  -- Bose Pro: Super Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 5, 2),  -- Bose Pro: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 6, 2),  -- Bose Pro: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 7, 2),  -- Distributor: Design Assist -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 8, 2),  -- Distributor: Service -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 9, 2),  -- End User: Admin -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 10, 2), -- End User: Operator -> read
  ((SELECT id FROM feature WHERE name = 'firmware.download'), 11, 1), -- End User: Guest -> not_visible

  -- feature: firmware.update.log
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 1, 3),  -- Reseller: Admin -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 2, 3),  -- Reseller: Designer -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 3, 3),  -- Reseller: Technician -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 4, 3),  -- Bose Pro: Super Admin -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 5, 3),  -- Bose Pro: Design Assist -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 6, 3),  -- Bose Pro: Service -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 7, 3),  -- Distributor: Design Assist -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 8, 3),  -- Distributor: Service -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 9, 3),  -- End User: Admin -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 10, 3), -- End User: Operator -> edit
  ((SELECT id FROM feature WHERE name = 'firmware.update.log'), 11, 1); -- End User: Guest -> not_visible