import type { SpaceItem, SpacesResponse } from "xyte-api";
import api from "./axios";
import type { AxiosResponse } from "./types";

/* List (optionally paginated) */
export const getSpaces = () =>
  api.get<AxiosResponse<SpacesResponse>>("/spaces").then((r) => r.data.data);

/* Create */
export const createSpace = (payload: { name: string; parent_id?: number }) =>
  api
    .post<AxiosResponse<SpaceItem>>("/spaces", payload)
    .then((r) => r.data.data);

/* Update */
export const updateSpace = (id: number, payload: Partial<SpaceItem>) =>
  api
    .put<AxiosResponse<SpaceItem>>(`/spaces/${id}`, payload)
    .then((r) => r.data.data);

/* Delete */
export const deleteSpace = (id: number) => api.delete(`/spaces/${id}`);
