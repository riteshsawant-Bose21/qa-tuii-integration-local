
CREATE TABLE bundle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
             
    release_notes TEXT,
    
    min_prev_version TEXT NOT NULL,
    min_desktop_app_version TEXT NOT NULL,
    
    manifest_data JSONB NOT NULL,

    is_approved bool NOT NULL DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TYPE bundle_update_status_enum AS ENUM (
    'INSTALL_SUCCESS',
    'INSTALL_FAIL'
);

CREATE TABLE bundle_update_status (
    id UUID PRIMARY KEY,         
    update_id UUID NOT null,

    project_id UUID NOT NULL references project(id),
    bundle_version TEXT NOT NULL,      
    previous_version TEXT,
    status bundle_update_status_enum NOT NULL,             
    launcher_version TEXT,    
    
    installed_at TIMESTAMPTZ NOT null,
   
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);