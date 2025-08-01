import type { ClaimDevicePayload, Device } from "xyte-api";
import api from "./axios";
import type { AxiosResponse } from "./types";

/* All devices for current org */
export const getDevices = () =>
  api
    .get<AxiosResponse<{ items: Device[]; next_page: number }>>("/devices")
    .then((r) => r.data.data);

/* Claim a new device */
export const claimDevice = (payload: ClaimDevicePayload) =>
  api
    .post<AxiosResponse<Device>>("/devices/claim", payload)
    .then((r) => r.data.data);

/* Single device by id */
export const getDeviceById = (id: string) =>
  api.get<AxiosResponse<Device>>(`/devices/${id}`).then((r) => r.data.data);

/* Execute command */
export const sendCommand = (id: string, command: string, body?: unknown) =>
  api.post(`/devices/${id}/commands/${command}`, body);
