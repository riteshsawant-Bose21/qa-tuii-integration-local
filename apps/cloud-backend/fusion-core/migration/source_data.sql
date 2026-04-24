INSERT INTO source (id, model_name, asset_path, model_family, primary_connection_type, description, paging_source_type, supported_connection_types, is_fusion_compatible) VALUES
-- Microphones
('gooseneck',        'Gooseneck',         'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}'::connection_type[],        TRUE),
('hanging',          'Hanging',           'https://audio-source-images.s3.us-east-2.amazonaws.com/hanging_mic.png', 'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('condenser',        'Condenser',         'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('dynamic',          'Dynamic',           'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('shotgun',          'Shotgun',           'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('pzm',              'PZM',               'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('lavalier',         'Lavalier',          'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('headset',          'Headset',           'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('handheld',         'Handheld',          'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('beltpack',         'Beltpack',          'https://audio-source-images.s3.us-east-2.amazonaws.com/mic1.png',        'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('table',            'Table',             'https://audio-source-images.s3.us-east-2.amazonaws.com/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_handheld','Wireless Handheld', 'https://audio-source-images.s3.us-east-2.amazonaws.com/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_headset', 'Wireless Headset',  'https://audio-source-images.s3.us-east-2.amazonaws.com/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),
('wireless_beltpack','Wireless Beltpack', 'https://audio-source-images.s3.us-east-2.amazonaws.com/paging_mic.png',  'mic', 'analogInput', NULL, NULL, '{analogInput,endpoint,xlr,aes67input}',        TRUE),

-- Media Sources
('media_player', 'Media Player', 'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('cd',           'CD',           'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('dvd',          'DVD',          'https://audio-source-images.s3.us-east-2.amazonaws.com/hdmi.png',      'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('bluray',       'BluRay',       'https://audio-source-images.s3.us-east-2.amazonaws.com/hdmi.png',      'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('sat_cable',    'Sat/Cable',    'https://audio-source-images.s3.us-east-2.amazonaws.com/hdmi.png',      'media', 'hdmi',        NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('tv',           'TV',           'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'media', 'hdmi',        NULL, NULL, '{analogInput,audioJack,rca,hdmi,endpoint,aes67input}',         TRUE),
('tuner',        'Tuner',        'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('laptop',       'Laptop',       'https://audio-source-images.s3.us-east-2.amazonaws.com/laptop.png',    'media', 'usb',         NULL, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}',TRUE),
('deskpc',       'Desk PC',      'https://audio-source-images.s3.us-east-2.amazonaws.com/laptop.png',    'media', 'usb',         NULL, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}',TRUE),
('mixer',        'Mixer',        'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'generic','analogInput', NULL, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}',              TRUE),
('generic',      'Generic',      'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'generic','analogInput', NULL, NULL, '{analogInput,audioJack,rca,usb,endpoint,aes67input}',          TRUE),
('phone',        'Phone',        'https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png', 'media', 'analogInput', NULL, NULL, '{analogInput,audioJack,rca,bluetooth,endpoint,aes67input}',    TRUE),

-- Paging Sources
('message_player','Message Player','https://audio-source-images.s3.us-east-2.amazonaws.com/dvdplayer.png','paging','messagePlayer',NULL,'messagePlayer','{}',TRUE);
