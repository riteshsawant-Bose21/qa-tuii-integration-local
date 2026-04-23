INSERT INTO source (id, model_name, asset_path, model_family, primary_connection_type, description, paging_source_type, supported_connection_types, is_fusion_compatible) VALUES
-- Microphones
('gooseneck',        'Gooseneck',         'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}'::connection_type[],        TRUE),
('hanging',          'Hanging',           'assets/images/products/hanging_mic.png', 'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('condenser',        'Condenser',         'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('dynamic',          'Dynamic',           'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('shotgun',          'Shotgun',           'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('pzm',              'PZM',               'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('lavalier',         'Lavalier',          'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('headset',          'Headset',           'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('handheld',         'Handheld',          'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('beltpack',         'Beltpack',          'assets/images/products/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('table',            'Table',             'assets/images/products/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_handheld','Wireless Handheld', 'assets/images/products/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_headset', 'Wireless Headset',  'assets/images/products/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_beltpack','Wireless Beltpack', 'assets/images/products/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),

-- Media Sources
('media_player', 'Media Player', 'assets/images/products/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('cd',           'CD',           'assets/images/products/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('dvd',          'DVD',          'assets/images/products/hdmi.png',      'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('bluray',       'BluRay',       'assets/images/products/hdmi.png',      'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('sat_cable',    'Sat/Cable',    'assets/images/products/hdmi.png',      'media', 'hdmi',        NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('tv',           'TV',           'assets/images/products/dvdplayer.png', 'media', 'hdmi',        NULL, NULL, '{analogInput,audioJack,rca,hdmi,endpoint,aes67input}',         TRUE),
('tuner',        'Tuner',        'assets/images/products/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('laptop',       'Laptop',       'assets/images/products/laptop.png',    'media', 'usb',         NULL, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}',TRUE),
('deskpc',       'Desk PC',      'assets/images/products/laptop.png',    'media', 'usb',         NULL, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}',TRUE),
('mixer',        'Mixer',        'assets/images/products/dvdplayer.png', 'generic','analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('generic',      'Generic',      'assets/images/products/dvdplayer.png', 'generic','analogInput', NULL, NULL, '{analogInput,audioJack,rca,usb,endpoint,aes67input}',          TRUE),
('phone',        'Phone',        'assets/images/products/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,bluetooth,endpoint,aes67input}',    TRUE),

-- Paging Sources
('message_player','Message Player','assets/images/products/dvdplayer.png','paging','messagePlayer',NULL,'messagePlayer','{}',TRUE);
