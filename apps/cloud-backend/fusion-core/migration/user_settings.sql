CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL,
    language VARCHAR(20) DEFAULT 'en-US',
    theme VARCHAR(20) DEFAULT 'system',
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp,

    FOREIGN KEY (user_id) REFERENCES app_user(id)
);
