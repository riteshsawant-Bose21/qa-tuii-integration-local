import type { User, UserMeta } from "../contexts/AuthContext";
import api from "./axios";
import type { AxiosResponse } from "./types";

export interface AuthResponse {
  accessToken?: string;
  refreshToken?: string;
  expiresIn?: number;
  user: User;
}

export interface RefreshTokenResponse {
  accessToken: string;
  expiresIn: number;
}

export const login = async (email: string, password: string) => {
  const r = await api.post<AxiosResponse<AuthResponse>>("/auth/login", {
    email,
    password,
  });
  return r.data.data;
};

export const register = async (email: string, password: string) => {
  const r = await api.post<AxiosResponse<AuthResponse>>("/auth/register", {
    email,
    password,
  });
  return r.data.data;
};

export const refresh = async (refreshToken: string) => {
  const r = await api.post<AxiosResponse<RefreshTokenResponse>>(
    "/auth/refresh",
    {
      refreshToken,
    }
  );
  return r.data.data;
};

export const logout = () => api.post("/auth/logout");

export const getMe = async () => {
  const r = await api.get<AxiosResponse<Partial<AuthResponse>>>("/auth/me");
  return r.data.data;
};

export const updateMetadata = async (fields: UserMeta) => {
  const r = await api.post<AxiosResponse<AuthResponse>>(
    "/auth/metadata",
    fields
  );
  return r.data.data;
};
