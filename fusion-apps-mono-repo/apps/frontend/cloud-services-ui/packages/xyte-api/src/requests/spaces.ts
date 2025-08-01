import axios from 'axios';
import { SpaceItem, SpacesResponse } from '../models/spaces';
import { XYTE_BASE_URL } from '../constants';

export async function getSpaces(apiKey: string): Promise<SpacesResponse> {
    const response = await axios.get<SpacesResponse>(`${XYTE_BASE_URL}/spaces`, {
        headers: {
            Authorization: `Bearer ${apiKey}`,
        },
    });
    return response.data;
}

export interface CreateSpacePayload {
    name: string;
    parent_id?: number | null;
}
export async function createSpace(apiKey: string, payload: CreateSpacePayload): Promise<SpaceItem> {
    const response = await axios.post<SpaceItem>(`${XYTE_BASE_URL}/spaces`, payload, {
        headers: {
            Authorization: `Bearer ${apiKey}`,
        },
    });
    return response.data;
}

export interface UpdateSpacePayload {
    id: number;
    name?: string;
    parent_id?: number | null;
}
export async function updateSpace(apiKey: string, payload: UpdateSpacePayload): Promise<SpaceItem> {
    const response = await axios.patch<SpaceItem>(
        `${XYTE_BASE_URL}/spaces/${payload.id}`,
        payload,
        {
            headers: {
                Authorization: `Bearer ${apiKey}`,
            },
        }
    );
    return response.data;
}

export async function deleteSpace(apiKey: string, spaceId: number): Promise<void> {
    await axios.delete(`${XYTE_BASE_URL}/spaces/${spaceId}`, {
        headers: {
            Authorization: `Bearer ${apiKey}`,
        },
    });
}
