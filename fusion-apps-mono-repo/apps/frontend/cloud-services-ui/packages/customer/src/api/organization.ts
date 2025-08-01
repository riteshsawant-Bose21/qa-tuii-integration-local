import type { Organization } from 'xyte-api';
import api from './axios';

export const getOrganization = () =>
    api.get<Organization>('/organization').then(r => r.data);
