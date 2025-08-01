export interface Device {
    id: string;
    name: string;
    sn: string | null;
    mac: string | null;
    cloud_id: string | null;
    status: string | null;
    last_seen_at: string | null;
    details: string | null;
    created_at: string | null;
    model?: {
        id: string;
        name: string;
        sub_model: string | null;
    };
    firmware?: {
        version: string;
    };
    space?: {
        id: number;
        full_path: string;
    };
}
