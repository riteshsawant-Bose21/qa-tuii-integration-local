ALTER TABLE bundle ADD COLUMN IF NOT EXISTS prerelease_tag TEXT;

-- Backfill prerelease_tag from version column for existing rows
UPDATE bundle
SET prerelease_tag = split_part(split_part(split_part(version, '+', 1), '-', 2), '.', 1)
WHERE version LIKE '%-%' AND prerelease_tag IS NULL;

-- Drop the unused prerelease column
ALTER TABLE bundle DROP COLUMN IF EXISTS prerelease;

ALTER TABLE bundle
    DROP COLUMN version_array,
    ADD COLUMN version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(version, '+', 1), '-', 1), '.' )::INT[] ) STORED;

ALTER TABLE bundle
    DROP COLUMN min_prev_version_array,
    ADD COLUMN min_prev_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(min_prev_version, '+', 1), '-', 1), '.' )::INT[] ) STORED;

ALTER TABLE bundle
    DROP COLUMN min_desktop_app_version_array,
    ADD COLUMN min_desktop_app_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(split_part(min_desktop_app_version, '+', 1), '-', 1), '.' )::INT[] ) STORED;

-- Rename columns in bundle_update_status to match updated payload field names
ALTER TABLE bundle_update_status RENAME COLUMN previous_version TO previous_bundle_version;
ALTER TABLE bundle_update_status RENAME COLUMN launcher_version TO desktop_app_version;
