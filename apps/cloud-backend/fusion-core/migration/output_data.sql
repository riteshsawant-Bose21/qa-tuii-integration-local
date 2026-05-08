INSERT INTO output (name, type, images, primary_connection, supported_connections) VALUES
('Media Recorder', 'media', 'product/output/images/media_recorder.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Laptop/PC', 'media', 'product/output/images/laptop_pc.png', 'usbOutput', ARRAY['usbOutput', 'hdmi', 'analogOutput']::connection_type[]),
('Mixer', 'media', 'product/output/images/mixer.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Local Output', 'media', 'product/output/images/local_output.png', 'analogOutput', ARRAY['analogOutput']::connection_type[]),
('Monitor Output', 'media', 'product/output/images/monitor_output.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]),
('Hearing Assistance', 'media', 'product/output/images/hearing_assistance.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Powered Speaker', 'media', 'product/output/images/powered_speaker.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]),
('External System', 'media', 'product/output/images/external_system.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput', 'aes67output']::connection_type[]),
('Generic Output', 'media', 'product/output/images/generic_output.png', 'analogOutput', ARRAY['analogOutput']::connection_type[]),
('Generic Amplifier', 'amplifier', 'product/output/images/generic_amplifier.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]);