INSERT INTO output (name, type, asset_path, primary_connection, supported_connections) VALUES
('Media Recorder', 'media', 'assets/images/outputs/media_recorder.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Laptop/PC', 'media', 'assets/images/outputs/laptop_pc.png', 'usbOutput', ARRAY['usbOutput', 'hdmi', 'analogOutput']::connection_type[]),
('Mixer', 'media', 'assets/images/outputs/mixer.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Local Output', 'media', 'assets/images/outputs/local_output.png', 'analogOutput', ARRAY['analogOutput']::connection_type[]),
('Monitor Output', 'media', 'assets/images/outputs/monitor_output.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]),
('Hearing Assistance', 'media', 'assets/images/outputs/hearing_assistance.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput']::connection_type[]),
('Powered Speaker', 'media', 'assets/images/outputs/powered_speaker.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]),
('External System', 'media', 'assets/images/outputs/external_system.png', 'analogOutput', ARRAY['analogOutput', 'usbOutput', 'aes67output']::connection_type[]),
('Generic Output', 'media', 'assets/images/outputs/generic_output.png', 'analogOutput', ARRAY['analogOutput']::connection_type[]),
('Generic Amplifier', 'amplifier', 'assets/images/outputs/generic_amplifier.png', 'analogOutput', ARRAY['analogOutput', 'aes67output']::connection_type[]);