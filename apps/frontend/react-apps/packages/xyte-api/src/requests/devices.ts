import axios from 'axios';
import { XYTE_BASE_URL } from '../constants';
import { Device } from '../models/devices';
import { ModelDefinition } from '../models/model';

export async function getDevices(apiKey: string): Promise<{ items: Device[] }> {
    const response = await axios.get<{ items: Device[] }>(`${XYTE_BASE_URL}/devices`, {
        headers: {
            Authorization: `Bearer ${apiKey}`,
        },
    });
    return response.data;
}

export interface ClaimDevicePayload {
    space_id?: number;
    cloud_id: string;
    mac?: string;
    sn?: string;
    name: string;
}

export async function claimDevice(
    apiKey: string,
    payload: ClaimDevicePayload
): Promise<Device> {
    const response = await axios.post<Device>(
        `${XYTE_BASE_URL}/devices/claim`,
        payload,
        {
            headers: {
                Authorization: `Bearer ${apiKey}`,
            },
        }
    );
    return response.data;
}

