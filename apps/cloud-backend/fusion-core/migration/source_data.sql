INSERT INTO source (id, name, asset_path, type, connection_type, price, paging_source_type, supported_connection_types) VALUES
-- Microphones
('gooseneck', 'Gooseneck', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('hanging', 'Hanging', 'assets/images/products/hanging_mic.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('condenser', 'Condenser', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('dynamic', 'Dynamic', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('shotgun', 'Shotgun', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('pzm', 'PZM', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('lavalier', 'Lavalier', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('headset', 'Headset', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('handheld', 'Handheld', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('beltpack', 'Beltpack', 'assets/images/products/mic1.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('table', 'Table', 'assets/images/products/paging_mic.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('wireless_handheld', 'Wireless Handheld', 'assets/images/products/paging_mic.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('wireless_headset', 'Wireless Headset', 'assets/images/products/paging_mic.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),
('wireless_beltpack', 'Wireless Beltpack', 'assets/images/products/paging_mic.png', 'mic', 'analogInput', 100.0, NULL, '{analogInput,endpoint,xlr,aes67input}'),

-- Media Sources
('media_player', 'Media Player', 'assets/images/products/dvdplayer.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('cd', 'CD', 'assets/images/products/dvdplayer.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('dvd', 'DVD', 'assets/images/products/hdmi.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('bluray', 'BluRay', 'assets/images/products/hdmi.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('sat_cable', 'Sat/Cable', 'assets/images/products/hdmi.png', 'media', 'hdmi', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('tv', 'TV', 'assets/images/products/dvdplayer.png', 'media', 'hdmi', 100.0, NULL, '{analogInput,audioJack,rca,hdmi,endpoint,aes67input}'),
('tuner', 'Tuner', 'assets/images/products/dvdplayer.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('laptop', 'Laptop', 'assets/images/products/laptop.png', 'media', 'usb', 100.0, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}'),
('deskpc', 'Desk PC', 'assets/images/products/laptop.png', 'media', 'usb', 100.0, NULL, '{analogInput,audioJack,rca,usb,bluetooth,endpoint,aes67input}'),
('mixer', 'Mixer', 'assets/images/products/dvdplayer.png', 'generic', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,endpoint,aes67input}'),
('generic', 'Generic', 'assets/images/products/dvdplayer.png', 'generic', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,usb,endpoint,aes67input}'),
('phone', 'Phone', 'assets/images/products/dvdplayer.png', 'media', 'analogInput', 100.0, NULL, '{analogInput,audioJack,rca,bluetooth,endpoint,aes67input}'),

-- Paging Sources
('message_player', 'Message Player', 'assets/images/products/dvdplayer.png', 'paging', 'messagePlayer', 100.0, 'messagePlayer', '{}');

