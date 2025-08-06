import axios from 'axios';
import { Organization } from '../models/organization';
import { XYTE_BASE_URL } from '../constants';

export async function getOrganization(apiKey: string): Promise<Organization> {
    const response = await axios.get<Organization>(`${XYTE_BASE_URL}/info`, {
        headers: {
            Authorization: `Bearer ${apiKey}`,
        },
    });
    return response.data;
}
