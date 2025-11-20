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

-- Insert products data
INSERT INTO products (id, category, description, price, meta_info, created_at, updated_at) VALUES
    (1, 'Loudspeakers', 'Professional ceiling-mounted speaker with 70V/100V transformer', 299.99, '{"power": "25W", "frequency_range": "60Hz-20kHz", "mounting": "ceiling", "color_options": ["white", "black"]}', '2024-01-10 08:00:00', '2024-01-10 08:00:00'),
    
    (2, 'Amplifiers', 'Multi-channel digital amplifier with DSP processing', 1299.99, '{"channels": 4, "power_per_channel": "100W", "dsp_features": ["EQ", "crossover", "delay"], "connectivity": ["analog", "digital", "ethernet"]}', '2024-01-10 08:15:00', '2024-01-10 08:15:00'),
    
    (3, 'Microphones', 'Wireless handheld microphone system with diversity receiver', 899.99, '{"type": "wireless", "frequency_band": "UHF", "battery_life": "8 hours", "range": "100 meters", "features": ["diversity", "encryption"]}', '2024-01-10 08:30:00', '2024-01-10 08:30:00'),
    
    (4, 'Mixers', 'Compact digital mixer with USB recording capability', 799.99, '{"channels": 8, "inputs": ["XLR", "1/4_inch", "USB"], "outputs": ["main", "monitor", "USB"], "effects": ["reverb", "delay", "compression"]}', '2024-01-10 08:45:00', '2024-01-10 08:45:00'),
    
    (5, 'Loudspeakers', 'Portable column array speaker with built-in mixer', 1899.99, '{"type": "column_array", "drivers": "8x3inch + 1x8inch", "power": "400W", "bluetooth": true, "battery": "8 hours", "weight": "15kg"}', '2024-01-10 09:00:00', '2024-02-15 14:20:00'),
    
    (6, 'Signal_Processing', 'Digital signal processor with advanced room correction', 2299.99, '{"inputs": 8, "outputs": 8, "processing": ["EQ", "dynamics", "room_correction"], "network": ["dante", "ethernet"], "control": ["software", "hardware_panel"]}', '2024-01-10 09:15:00', '2024-01-10 09:15:00'),
    
    (7, 'Accessories', 'Professional microphone stand with boom arm', 129.99, '{"type": "boom_stand", "height_range": "90-165cm", "boom_length": "75cm", "material": "steel", "weight": "3.2kg", "color": "black"}', '2024-01-10 09:30:00', '2024-01-10 09:30:00'),
    
    (8, 'Amplifiers', 'High-power subwoofer amplifier with variable crossover', 699.99, '{"power": "500W", "frequency_range": "20Hz-200Hz", "crossover": "variable", "protection": ["thermal", "short_circuit"], "cooling": "forced_air"}', '2024-01-10 09:45:00', '2024-03-01 11:30:00'),
    
    (9, 'Loudspeakers', 'Weather-resistant outdoor speaker for distributed systems', 449.99, '{"rating": "IP65", "power": "50W", "mounting": ["wall", "pole"], "transformer": "70V/100V", "materials": "marine_grade", "warranty": "5_years"}', '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
    
    (10, 'Control_Systems', 'Wall-mounted control panel with preset recall', 399.99, '{"presets": 16, "controls": ["volume", "source_select", "mute"], "display": "LCD", "network": "ethernet", "mounting": "single_gang"}', '2024-01-10 10:15:00', '2024-01-10 10:15:00');

-- Reset sequences to match inserted data
SELECT setval('access_level_id_seq', 4, true);
SELECT setval('account_id_seq', 6, true);
SELECT setval('account_type_role_id_seq', 12, true);
SELECT setval('feature_id_seq', 10, true);
SELECT setval('feature_permission_id_seq', 41, true);
SELECT setval('products_id_seq', 10, true);
SELECT setval('project_user_id_seq', 12, true);
SELECT setval('roles_id_seq', 7, true);