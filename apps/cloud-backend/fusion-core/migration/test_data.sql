-- Dummy data for fusion_cloud database
-- Insert statements to populate all tables with test data

-- Insert accounts_type data
INSERT INTO accounts_type (id, name) VALUES
    ('10000001-0000-4000-8000-000000000001', 'admin'),
    ('10000001-0000-4000-8000-000000000002', 'reseller'),
    ('10000001-0000-4000-8000-000000000003', 'retail');

-- Insert account data
INSERT INTO account (id, name, description, type, created_at) VALUES
    (1, 'Bose Corporation', 'Main administrative account', 'admin', '2024-01-15 10:00:00'),
    (2, 'AudioTech Solutions', 'Authorized reseller for North America', 'reseller', '2024-02-10 14:30:00'),
    (3, 'Sound Dynamics LLC', 'Regional reseller for Southeast', 'reseller', '2024-02-20 09:15:00'),
    (4, 'Metro Conference Center', 'Corporate retail customer', 'retail', '2024-03-05 11:45:00'),
    (5, 'University Audio Labs', 'Educational institution customer', 'retail', '2024-03-12 16:20:00'),
    (6, 'Event Productions Inc', 'Event management company', 'retail', '2024-03-18 13:10:00');

-- Insert roles data
INSERT INTO roles (id, name, description) VALUES
    (1, 'Super Admin', 'Full system access and management capabilities'),
    (2, 'Admin', 'Administrative access with some restrictions'),
    (3, 'Reseller Manager', 'Manage reseller operations and accounts'),
    (4, 'Sales Representative', 'Sales and customer interaction role'),
    (5, 'Project Manager', 'Manage projects and technical implementations'),
    (6, 'Technical Support', 'Provide technical assistance and support'),
    (7, 'End User', 'Standard user with basic project access');

-- Insert access_level data
INSERT INTO access_level (id, key, label) VALUES
    (1, 'read', 'Read Only'),
    (2, 'write', 'Read and Write'),
    (3, 'admin', 'Administrative Access'),
    (4, 'owner', 'Full Owner Access');

-- Insert account_type_role data (mapping accounts to roles)
INSERT INTO account_type_role (id, account_id, role_id) VALUES
    (1, 1, 1),  -- Bose Corporation -> Super Admin
    (2, 1, 2),  -- Bose Corporation -> Admin
    (3, 2, 3),  -- AudioTech Solutions -> Reseller Manager
    (4, 2, 4),  -- AudioTech Solutions -> Sales Representative
    (5, 3, 3),  -- Sound Dynamics LLC -> Reseller Manager
    (6, 3, 4),  -- Sound Dynamics LLC -> Sales Representative
    (7, 4, 5),  -- Metro Conference Center -> Project Manager
    (8, 4, 7),  -- Metro Conference Center -> End User
    (9, 5, 5),  -- University Audio Labs -> Project Manager
    (10, 5, 7), -- University Audio Labs -> End User
    (11, 6, 5), -- Event Productions Inc -> Project Manager
    (12, 6, 7); -- Event Productions Inc -> End User

-- Insert user data
INSERT INTO "user" (id, email, full_name, password_hash, role_id, account_id, created_at, updated_at) VALUES
    ('20000001-0000-4000-8000-000000000001', 'admin@bose.com', 'John Administrator', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 1, 1, '2024-01-15 10:30:00', '2024-01-15 10:30:00'),
    ('20000001-0000-4000-8000-000000000002', 'manager@bose.com', 'Sarah Manager', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 2, 1, '2024-01-16 09:15:00', '2024-01-16 09:15:00'),
    ('20000001-0000-4000-8000-000000000003', 'mike.reseller@audiotech.com', 'Mike Reseller', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 3, 2, '2024-02-10 15:00:00', '2024-02-10 15:00:00'),
    ('20000001-0000-4000-8000-000000000004', 'sales@audiotech.com', 'Lisa Sales', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 4, 2, '2024-02-12 11:20:00', '2024-02-12 11:20:00'),
    ('20000001-0000-4000-8000-000000000005', 'alex@sounddynamics.com', 'Alex Dynamic', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 5, 3, '2024-02-20 10:00:00', '2024-02-20 10:00:00'),
    ('20000001-0000-4000-8000-000000000006', 'david.pm@metroconference.com', 'David Project', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 7, 4, '2024-03-05 12:30:00', '2024-03-05 12:30:00'),
    ('20000001-0000-4000-8000-000000000007', 'prof.audio@university.edu', 'Professor Audio', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 9, 5, '2024-03-12 17:00:00', '2024-03-12 17:00:00'),
    ('20000001-0000-4000-8000-000000000008', 'emily@eventproductions.com', 'Emily Event', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 11, 6, '2024-03-18 14:15:00', '2024-03-18 14:15:00'),
    ('20000001-0000-4000-8000-000000000009', 'tech.support@bose.com', 'Tom Support', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDLExmLQ/LuUOXe', 2, 1, '2024-01-20 08:45:00', '2024-01-20 08:45:00');

-- Insert feature data
INSERT INTO feature (id, name, description) VALUES
    (1, 'Project Management', 'Create, edit, and manage audio projects'),
    (2, 'User Management', 'Manage user accounts and permissions'),
    (3, 'System Configuration', 'Configure system-wide settings'),
    (4, 'Reporting', 'Generate and view system reports'),
    (5, 'Device Management', 'Manage connected audio devices'),
    (6, 'Account Management', 'Manage customer accounts'),
    (7, 'Product Catalog', 'Access and manage product information'),
    (8, 'Sales Tools', 'Access sales and quoting tools'),
    (9, 'Technical Support', 'Access technical support features'),
    (10, 'Analytics Dashboard', 'View analytics and performance metrics');

-- Insert feature_permission data
INSERT INTO feature_permission (id, feature_id, role_id, access_level_id) VALUES
    -- Super Admin permissions (full access to everything)
    (1, 1, 1, 4), (2, 2, 1, 4), (3, 3, 1, 4), (4, 4, 1, 4), (5, 5, 1, 4),
    (6, 6, 1, 4), (7, 7, 1, 4), (8, 8, 1, 4), (9, 9, 1, 4), (10, 10, 1, 4),
    
    -- Admin permissions (admin access to most features)
    (11, 1, 2, 3), (12, 2, 2, 3), (13, 4, 2, 3), (14, 5, 2, 3), (15, 6, 2, 2),
    (16, 7, 2, 2), (17, 9, 2, 3), (18, 10, 2, 2),
    
    -- Reseller Manager permissions
    (19, 1, 3, 2), (20, 6, 3, 2), (21, 7, 3, 2), (22, 8, 3, 2), (23, 4, 3, 1), (24, 10, 3, 1),
    
    -- Sales Representative permissions
    (25, 1, 4, 1), (26, 7, 4, 1), (27, 8, 4, 2), (28, 6, 4, 1),
    
    -- Project Manager permissions
    (29, 1, 5, 2), (30, 5, 5, 2), (31, 7, 5, 1), (32, 4, 5, 1), (33, 10, 5, 1),
    
    -- Technical Support permissions
    (34, 1, 6, 1), (35, 5, 6, 2), (36, 9, 6, 2), (37, 7, 6, 1), (38, 4, 6, 1),
    
    -- End User permissions
    (39, 1, 7, 1), (40, 5, 7, 1), (41, 7, 7, 1);

-- Insert project data
INSERT INTO project (id, application, budget_amount, currency, description, name, project_phase, venue, environment_type, is_archived, is_deleted, locked_by_user_id, primary_owner_account_id, created_at, updated_at) VALUES
    ('30000001-0000-4000-8000-000000000001', 'Corporate Conference Room', 75000.00, 'USD', 'High-end audio system for executive boardroom with advanced noise cancellation and crystal clear conference capabilities', 'Metro Conference Center - Executive Boardroom', 'planning', 'Metro Conference Center, Downtown', 'indoor', false, false, NULL, 4, '2024-03-10 09:00:00', '2024-03-15 14:30:00'),
    
    ('30000001-0000-4000-8000-000000000002', 'Educational Facility', 45000.00, 'USD', 'Multi-room audio solution for university lecture halls and seminar rooms with integrated recording capabilities', 'University Audio Labs - Lecture Hall Upgrade', 'design', 'University Campus, Building A', 'indoor', false, false, '20000001-0000-4000-8000-000000000007', 5, '2024-03-15 11:20:00', '2024-03-20 16:45:00'),
    
    ('30000001-0000-4000-8000-000000000003', 'Event Production', 120000.00, 'USD', 'Portable high-capacity sound system for outdoor festivals and large-scale events with weather-resistant components', 'Summer Music Festival 2024', 'implementation', 'Central Park Amphitheater', 'outdoor', false, false, NULL, 6, '2024-02-28 08:15:00', '2024-04-02 12:00:00'),
    
    ('30000001-0000-4000-8000-000000000004', 'Retail Showroom', 32000.00, 'USD', 'Interactive audio demonstration system for retail showroom with customer experience zones', 'AudioTech Solutions - Demo Showroom', 'completed', 'AudioTech Solutions Store', 'indoor', false, false, NULL, 2, '2024-01-20 10:30:00', '2024-02-25 17:20:00'),
    
    ('30000001-0000-4000-8000-000000000005', 'Corporate Training', 28000.00, 'USD', 'Multi-zone audio system for corporate training facilities with individual zone control', 'Bose Training Center Upgrade', 'design', 'Bose Corporate Campus', 'indoor', false, false, '20000001-0000-4000-8000-000000000002', 1, '2024-04-01 13:45:00', '2024-04-05 09:30:00'),
    
    ('30000001-0000-4000-8000-000000000006', 'House of Worship', 65000.00, 'USD', 'Comprehensive sound reinforcement system for large sanctuary with distributed audio and video integration', 'First Baptist Church - Sanctuary Audio', 'planning', 'First Baptist Church', 'indoor', false, false, NULL, 3, '2024-03-25 15:10:00', '2024-03-28 11:25:00'),
    
    ('30000001-0000-4000-8000-000000000007', 'Sports Facility', 89000.00, 'USD', 'Stadium audio system with emergency notification capabilities and zone-based announcements', 'City Stadium Audio Overhaul', 'archived_project', 'City Sports Complex', 'outdoor', true, false, NULL, 4, '2023-09-15 14:20:00', '2023-12-10 16:40:00');

-- Insert project_user data (user-project associations with starred status)
INSERT INTO project_user (id, project_id, user_id, is_starred, created_at, updated_at) VALUES
    (1, '30000001-0000-4000-8000-000000000001', '20000001-0000-4000-8000-000000000006', true, '2024-03-10 09:30:00', '2024-03-12 10:15:00'),
    (2, '30000001-0000-4000-8000-000000000001', '20000001-0000-4000-8000-000000000003', false, '2024-03-10 10:00:00', '2024-03-10 10:00:00'),
    
    (3, '30000001-0000-4000-8000-000000000002', '20000001-0000-4000-8000-000000000007', true, '2024-03-15 11:45:00', '2024-03-18 14:20:00'),
    (4, '30000001-0000-4000-8000-000000000002', '20000001-0000-4000-8000-000000000009', false, '2024-03-16 09:30:00', '2024-03-16 09:30:00'),
    
    (5, '30000001-0000-4000-8000-000000000003', '20000001-0000-4000-8000-000000000008', true, '2024-02-28 08:45:00', '2024-03-01 16:30:00'),
    (6, '30000001-0000-4000-8000-000000000003', '20000001-0000-4000-8000-000000000004', false, '2024-03-01 12:15:00', '2024-03-01 12:15:00'),
    
    (7, '30000001-0000-4000-8000-000000000004', '20000001-0000-4000-8000-000000000003', false, '2024-01-20 11:00:00', '2024-01-20 11:00:00'),
    (8, '30000001-0000-4000-8000-000000000004', '20000001-0000-4000-8000-000000000004', true, '2024-01-22 14:20:00', '2024-02-15 10:45:00'),
    
    (9, '30000001-0000-4000-8000-000000000005', '20000001-0000-4000-8000-000000000001', false, '2024-04-01 14:00:00', '2024-04-01 14:00:00'),
    (10, '30000001-0000-4000-8000-000000000005', '20000001-0000-4000-8000-000000000002', true, '2024-04-01 14:15:00', '2024-04-03 11:30:00'),
    
    (11, '30000001-0000-4000-8000-000000000006', '20000001-0000-4000-8000-000000000005', true, '2024-03-25 15:30:00', '2024-03-26 09:45:00'),
    (12, '30000001-0000-4000-8000-000000000006', '20000001-0000-4000-8000-000000000009', false, '2024-03-26 10:15:00', '2024-03-26 10:15:00');

-- Reset sequences to match inserted data
SELECT setval('access_level_id_seq', 4, true);
SELECT setval('account_id_seq', 6, true);
SELECT setval('account_type_role_id_seq', 12, true);
SELECT setval('feature_id_seq', 10, true);
SELECT setval('feature_permission_id_seq', 41, true);
SELECT setval('products_id_seq', 10, true);
SELECT setval('project_user_id_seq', 12, true);
SELECT setval('roles_id_seq', 7, true);

-- -----------------------------------------------------------
-- Additional dummy data for new product-related tables
-- (Tables defined in fusion_cloud.sql: product, product_price, product_sync_job)
-- -----------------------------------------------------------

-- Insert product data (cover all enum types)
INSERT INTO product (product_id, product_type, model_name, model_family, description, short_description, images, specifications, created_at, updated_at) VALUES
    (1001, 'speaker', 'DM2SE', 'DesignMax', 'Surface-mount loudspeaker for premium installed sound systems', 'Premium surface-mount speaker',
        '{"primary":["https://example.com/images/dm2se_front.png"],"thumb":["https://example.com/images/dm2se_thumb.png"]}'::jsonb,
        '{"power_handling":"25W","frequency_range":"65Hz-20kHz","impedance":"8Ω"}'::jsonb,
        '2024-01-10 08:00:00','2024-01-10 08:00:00'),
    (1002, 'amplifier', 'PWR4X100', 'PowerSeries', '4-channel digital amplifier with integrated DSP', '4ch DSP amplifier',
        '{"primary":["https://example.com/images/pwr4x100_front.png"],"rear":["https://example.com/images/pwr4x100_rear.png"]}'::jsonb,
        '{"channels":4,"power_per_channel":"100W","dsp_features":["EQ","crossover","delay"],"network":["ethernet"]}'::jsonb,
        '2024-01-10 08:05:00','2024-01-10 08:05:00'),
    (1003, 'dsp', 'RoomDSP8', 'AcousticLogic', '8x8 digital signal processor with advanced room correction', '8x8 DSP processor',
        '{"primary":["https://example.com/images/roomdsp8_front.png"],"top":["https://example.com/images/roomdsp8_top.png"]}'::jsonb,
        '{"inputs":8,"outputs":8,"processing":["EQ","dynamics","room_correction"],"network":["dante","ethernet"]}'::jsonb,
        '2024-01-10 08:10:00','2024-01-10 08:10:00'),
    (1004, 'controller', 'CTL16', 'ControlPro', 'Wall-mounted control panel with preset recall and LCD', 'Wall control panel',
        '{"primary":["https://example.com/images/ctl16_front.png"],"in_situ":["https://example.com/images/ctl16_room.png"]}'::jsonb,
        '{"presets":16,"controls":["volume","source_select","mute"],"display":"LCD"}'::jsonb,
        '2024-01-10 08:15:00','2024-01-10 08:15:00'),
    (1005, 'io_endpoint', 'NetIO4', 'NetLink', 'Networked audio I/O endpoint with 4 in / 4 out', '4x4 network IO',
        '{"primary":["https://example.com/images/netio4_front.png"],"ports":["https://example.com/images/netio4_ports.png"]}'::jsonb,
        '{"inputs":4,"outputs":4,"protocols":["dante","aes67"],"sample_rates":[48000,96000]}'::jsonb,
        '2024-01-10 08:20:00','2024-01-10 08:20:00'),
    (1006, 'accessory', 'MICSTANDPRO', 'StageGear', 'Professional microphone stand with boom arm', 'Boom mic stand',
        '{"primary":["https://example.com/images/micstandpro.png"]}'::jsonb,
        '{"height_range":"90-165cm","boom_length":"75cm","material":"steel"}'::jsonb,
        '2024-01-10 08:25:00','2024-01-10 08:25:00');

-- Insert product_price data (variants & currencies)
INSERT INTO product_price (product_id, variant, currency, price, created_at, updated_at) VALUES
    (1001, 'black', 'USD', 299.99, '2024-01-10 08:30:00','2024-01-10 08:30:00'),
    (1001, 'white', 'USD', 299.99, '2024-01-10 08:30:00','2024-01-10 08:30:00'),
    (1002, 'standard', 'USD', 1299.99, '2024-01-10 08:35:00','2024-01-10 08:35:00'),
    (1002, 'standard', 'EUR', 1199.99, '2024-01-10 08:35:00','2024-01-10 08:35:00'),
    (1003, 'rackmount', 'USD', 2299.99, '2024-01-10 08:40:00','2024-01-10 08:40:00'),
    (1004, 'single_gang', 'USD', 399.99, '2024-01-10 08:45:00','2024-01-10 08:45:00'),
    (1005, 'poe', 'USD', 899.99, '2024-01-10 08:50:00','2024-01-10 08:50:00'),
    (1006, 'black', 'USD', 129.99, '2024-01-10 08:55:00','2024-01-10 08:55:00');

-- Insert product_sync_job data (sample sync jobs)
INSERT INTO product_sync_job (
    sync_operation, status, s3_bucket, s3_key, file_size_bytes, error_message,
    validation_errors, total_items, successful_items, failed_items, started_at, completed_at
) VALUES
    ('full_sync', 'completed', 'fusion-product-import', 'imports/2024/01/full_catalog.json', 524288,
        NULL, '{"warnings":[],"errors":[]}'::jsonb, 150, 150, 0,
        '2024-01-11 09:00:00','2024-01-11 09:02:30'),
    ('manual_sync', 'failed', 'fusion-product-import', 'imports/2024/01/manual_update.json', 104857,
        'Validation failed: missing required field model_name', '{"errors":[{"line":27,"issue":"missing model_name"}]}'::jsonb, 10, 7, 3,
        '2024-01-12 10:15:00','2024-01-12 10:16:10'),
    ('scheduled_sync', 'in_progress', 'fusion-product-import', 'imports/2024/01/scheduled_delta.json', 256000,
        NULL, NULL, NULL, NULL, NULL,
        '2024-01-13 02:00:00', NULL);
