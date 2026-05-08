INSERT INTO source (model_name, asset_path, model_family, description, specifications, is_fusion_compatible) VALUES
-- Microphones
('Gooseneck',         'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Hanging',          'assets/images/products/hanging_mic.png', 'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Condenser',        'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Dynamic',          'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Shotgun',          'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('PZM',              'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Lavalier',         'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Headset',          'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Handheld',         'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Beltpack',         'assets/images/products/mic1.png',        'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Table',            'assets/images/products/paging_mic.png',  'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Wireless Handheld','assets/images/products/paging_mic.png',  'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Wireless Headset', 'assets/images/products/paging_mic.png',  'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),
('Wireless Beltpack','assets/images/products/paging_mic.png',  'mic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","endpoint","xlr","aes67input"], "paging_type": null}', TRUE),

-- Media Sources
('Media Player', 'assets/images/products/dvdplayer.png', 'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('CD',           'assets/images/products/dvdplayer.png', 'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('DVD',          'assets/images/products/hdmi.png',      'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('BluRay',       'assets/images/products/hdmi.png',      'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('Sat/Cable',    'assets/images/products/hdmi.png',      'media', NULL, '{"primary_connection": "hdmi", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('TV',           'assets/images/products/dvdplayer.png', 'media', NULL, '{"primary_connection": "hdmi", "supported_connections": ["analogInput","audioJack","rca","hdmi","endpoint","aes67input"], "paging_type": null}', TRUE),
('Tuner',        'assets/images/products/dvdplayer.png', 'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('Laptop',       'assets/images/products/laptop.png',    'media', NULL, '{"primary_connection": "usb", "supported_connections": ["analogInput","audioJack","rca","usb","bluetooth","endpoint","aes67input"], "paging_type": null}', TRUE),
('Desk PC',      'assets/images/products/laptop.png',    'media', NULL, '{"primary_connection": "usb", "supported_connections": ["analogInput","audioJack","rca","usb","bluetooth","endpoint","aes67input"], "paging_type": null}', TRUE),
('Mixer',        'assets/images/products/dvdplayer.png', 'generic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","endpoint","aes67input"], "paging_type": null}', TRUE),
('Generic',      'assets/images/products/dvdplayer.png', 'generic', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","usb","endpoint","aes67input"], "paging_type": null}', TRUE),
('Phone',        'assets/images/products/dvdplayer.png', 'media', NULL, '{"primary_connection": "analogInput", "supported_connections": ["analogInput","audioJack","rca","bluetooth","endpoint","aes67input"], "paging_type": null}', TRUE),

-- Paging Sources
('Message Player','assets/images/products/dvdplayer.png','paging', NULL, '{"primary_connection": "messagePlayer", "supported_connections": [], "paging_type": "messagePlayer"}', TRUE);
