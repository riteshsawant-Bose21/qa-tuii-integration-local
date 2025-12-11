CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES app_user(id),
    language VARCHAR(20) DEFAULT 'en-US',
    theme VARCHAR(20) DEFAULT 'system',
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp
);

-- Sample data for development/testing
INSERT INTO user_settings (user_id, language, theme)
VALUES ('39cfe695-5f7d-4870-b9da-31f024757a3e', 'en-US', 'system');
    
