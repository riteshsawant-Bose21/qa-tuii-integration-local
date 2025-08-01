export interface SpaceItem {
    id: number;
    name: string;
    parent_id: number | null;
    config: Record<string, unknown>;
    path: string;
}

export interface SpacesResponse {
    items: SpaceItem[];
    next_page: string | null;
}
