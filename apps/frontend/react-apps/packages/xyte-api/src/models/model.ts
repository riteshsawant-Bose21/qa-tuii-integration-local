export interface PartnerInfo {
    display_name?: string;
    name?: string;
    id?: string;
}

export interface UserSettings {
    icon?: string;
    media?: Record<string, unknown>;
    visibility?: Record<string, unknown>;
}

export interface ModelDefinition {
    id?: string;
    partner?: PartnerInfo;
    model?: string;
    user_settings?: UserSettings;
    image_url?: string;
}
