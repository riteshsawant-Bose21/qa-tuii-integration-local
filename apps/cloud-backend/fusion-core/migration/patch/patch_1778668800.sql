-- Add BSF generate permission (Super Admin only)

INSERT INTO feature (name, description)
VALUES
  ('bsf.generate', 'Can generate BSF (Bose Speaker File) archives');

SELECT setval('feature_permission_id_seq', (SELECT MAX(id) FROM feature_permission));

INSERT INTO feature_permission (feature_id, account_type_role_id, access_level_id) VALUES
  -- feature: bsf.generate (Super Admin only)
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 1, 1),   -- Reseller: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 2, 1),   -- Reseller: Designer -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 3, 1),   -- Reseller: Technician -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 4, 3),   -- Bose Pro: Super Admin -> edit
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 5, 1),   -- Bose Pro: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 6, 1),   -- Bose Pro: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 7, 1),   -- Distributor: Design Assist -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 8, 1),   -- Distributor: Service -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 9, 1),   -- End User: Admin -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 10, 1),  -- End User: Operator -> not_visible
  ((SELECT id FROM feature WHERE name = 'bsf.generate'), 11, 1);  -- End User: Guest -> not_visible
