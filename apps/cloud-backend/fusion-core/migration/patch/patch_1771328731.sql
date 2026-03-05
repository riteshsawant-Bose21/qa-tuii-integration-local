
CREATE TABLE bundle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
    version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(version, '-', 1), '.' )::INT[] ) stored,
    prerelease TEXT,      -- alpha, beta or null (for stable)
    prerelease_num INT, 
    release_notes TEXT,
    min_prev_version TEXT NOT NULL,
    min_prev_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(min_prev_version, '-', 1), '.' )::INT[] ) STORED,
    min_desktop_app_version TEXT NOT NULL,
    min_desktop_app_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(min_desktop_app_version, '-', 1), '.' )::INT[] ) STORED,
    manifest_data JSONB,
    checksum VARCHAR(64) NOT NULL,
    is_approved bool NOT NULL DEFAULT false,
    approved_by UUID references app_user(id),
    approved_at TIMESTAMPTZ,
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
  -- feature 26: firmware.bundle.read
  (26, 1, 2),   -- Reseller: Admin -> read
  (26, 2, 2),   -- Reseller: Designer -> read
  (26, 3, 2),   -- Reseller: Technician -> read
  (26, 4, 2),   -- Bose Pro: Super Admin -> read
  (26, 5, 2),   -- Bose Pro: Design Assist -> read
  (26, 6, 2),   -- Bose Pro: Service -> read
  (26, 7, 2),   -- Distributor: Design Assist -> read
  (26, 8, 2),   -- Distributor: Service -> read
  (26, 9, 2),   -- End User: Admin -> read
  (26, 10, 2),  -- End User: Operator -> read
  (26, 11, 1),  -- End User: Guest -> not_visible

  -- feature 27: firmware.bundle.create (internal only)
  (27, 1, 1),  -- Reseller: Admin -> not_visible
  (27, 2, 1),  -- Reseller: Designer -> not_visible
  (27, 3, 1),  -- Reseller: Technician -> not_visible
  (27, 4, 3),  -- Bose Pro: Super Admin -> edit
  (27, 5, 1),  -- Bose Pro: Design Assist -> not_visible
  (27, 6, 1),  -- Bose Pro: Service -> not_visible
  (27, 7, 1),  -- Distributor: Design Assist -> not_visible
  (27, 8, 1),  -- Distributor: Service -> not_visible
  (27, 9, 1),  -- End User: Admin -> not_visible
  (27, 10, 1), -- End User: Operator -> not_visible
  (27, 11, 1), -- End User: Guest -> not_visible

  -- feature 28: firmware.bundle.approve (admin only)
  (28, 1, 1),  -- Reseller: Admin -> not_visible
  (28, 2, 1),  -- Reseller: Designer -> not_visible
  (28, 3, 1),  -- Reseller: Technician -> not_visible
  (28, 4, 3),  -- Bose Pro: Super Admin -> edit
  (28, 5, 1),  -- Bose Pro: Design Assist -> not_visible
  (28, 6, 1),  -- Bose Pro: Service -> not_visible
  (28, 7, 1),  -- Distributor: Design Assist -> not_visible
  (28, 8, 1),  -- Distributor: Service -> not_visible
  (28, 9, 1),  -- End User: Admin -> not_visible
  (28, 10, 1), -- End User: Operator -> not_visible
  (28, 11, 1), -- End User: Guest -> not_visible

  -- feature 29: firmware.update.check
  (29, 1, 2),  -- Reseller: Admin -> read
  (29, 2, 2),  -- Reseller: Designer -> read
  (29, 3, 2),  -- Reseller: Technician -> read
  (29, 4, 2),  -- Bose Pro: Super Admin -> read
  (29, 5, 2),  -- Bose Pro: Design Assist -> read
  (29, 6, 2),  -- Bose Pro: Service -> read
  (29, 7, 2),  -- Distributor: Design Assist -> read
  (29, 8, 2),  -- Distributor: Service -> read
  (29, 9, 2),  -- End User: Admin -> read
  (29, 10, 2), -- End User: Operator -> read
  (29, 11, 1), -- End User: Guest -> not_visible

  -- feature 30: firmware.download
  (30, 1, 2),  -- Reseller: Admin -> read
  (30, 2, 2),  -- Reseller: Designer -> read
  (30, 3, 2),  -- Reseller: Technician -> read
  (30, 4, 2),  -- Bose Pro: Super Admin -> read
  (30, 5, 2),  -- Bose Pro: Design Assist -> read
  (30, 6, 2),  -- Bose Pro: Service -> read
  (30, 7, 2),  -- Distributor: Design Assist -> read
  (30, 8, 2),  -- Distributor: Service -> read
  (30, 9, 2),  -- End User: Admin -> read
  (30, 10, 2), -- End User: Operator -> read
  (30, 11, 1), -- End User: Guest -> not_visible

  -- feature 31: firmware.update.log
  (31, 1, 3),  -- Reseller: Admin -> edit
  (31, 2, 3),  -- Reseller: Designer -> edit
  (31, 3, 3),  -- Reseller: Technician -> edit
  (31, 4, 3),  -- Bose Pro: Super Admin -> edit
  (31, 5, 3),  -- Bose Pro: Design Assist -> edit
  (31, 6, 3),  -- Bose Pro: Service -> edit
  (31, 7, 3),  -- Distributor: Design Assist -> edit
  (31, 8, 3),  -- Distributor: Service -> edit
  (31, 9, 3),  -- End User: Admin -> edit
  (31, 10, 3), -- End User: Operator -> edit
  (31, 11, 1); -- End User: Guest -> not_visible