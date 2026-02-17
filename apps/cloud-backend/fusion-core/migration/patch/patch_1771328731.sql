CREATE TYPE firmware_release_status AS ENUM (
    'PENDING_UPLOAD',
    'AVAILABLE',
    'ARCHIVED'
);

CREATE TABLE firmware_releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform TEXT NOT NULL,                 
    version TEXT NOT NULL,                  
    version_parts int[] GENERATED ALWAYS AS (
        string_to_array(version, '.')::int[]
    ) stored , 

    status firmware_release_status NOT NULL DEFAULT 'PENDING_UPLOAD',
    
    release_notes TEXT NOT NULL,                    
    s3_key TEXT NOT NULL UNIQUE,          
    file_checksum TEXT NOT NULL,           
    
    min_desktop_app_version TEXT NOT NULL,                
    hw_compatibility TEXT NOT NULL,                  
    api_level TEXT NOT NULL,

    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
   	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    UNIQUE(platform, version)
);

CREATE TYPE firmware_update_status AS ENUM (
    'INSTALL_SUCCESS',
    'INSTALL_FAIL'
);

CREATE TABLE firmware_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES firmware_releases(id),
    channel TEXT NOT NULL,                 
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE firmware_update_logs (
    id BIGSERIAL PRIMARY KEY, 
    device_id TEXT NOT NULL, 
    status firmware_update_status NOT NULL,     
    release_version TEXT NOT NULL,
    
    event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);