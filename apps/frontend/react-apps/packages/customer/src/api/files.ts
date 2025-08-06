import api from './axios';
import type { FileMeta } from './types';

/* List files (optionally by device) */
export const getFiles = (deviceId?: string) =>
    api
        .get<FileMeta[]>(deviceId ? `/devices/${deviceId}/files` : '/files')
        .then(r => r.data);

/* Upload file (multipart) */
export const uploadFile = (file: File, deviceId?: string) => {
    const form = new FormData();
    form.append('file', file);
    return api.post<FileMeta>(deviceId ? `/devices/${deviceId}/files` : '/files', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
    }).then(r => r.data);
};

/* Delete */
export const deleteFile = (fileId: string) =>
    api.delete(`/files/${fileId}`);
