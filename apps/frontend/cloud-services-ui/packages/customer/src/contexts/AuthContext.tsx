import React, { createContext, useContext, useState, useEffect } from 'react';
import * as authApi from '../api/auth';
import axios from 'axios';

export interface UserMeta {
  xyteApiKey?: string;
  organization?: unknown;
}

export interface User {
  id: string;
  email?: string;
  metadata?: UserMeta;
}

interface AuthCtx {
  user: User | null;
  loading: boolean;
  login(e: string, p: string): Promise<void>;
  register(e: string, p: string): Promise<void>;
  logout(): Promise<void>;
  updateMetadata(fields: Record<string, any>): Promise<void>;
}

const AuthContext = createContext<AuthCtx>(null as never);
export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    }

    authApi.getMe()
      .then(data => {
        setUser(data.user ?? null);
      })
      .catch(() => { })
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const interceptor = axios.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config;

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;
          try {
            const refreshToken = localStorage.getItem('auth_refresh_token');
            if (!refreshToken) {
              throw new Error('Missing refresh token');
            }
            const { accessToken } = await authApi.refresh(refreshToken);
            // Update access token
            if (accessToken) {
              localStorage.setItem('auth_token', accessToken);
              axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
              // Retry the original request with new token
              originalRequest.headers['Authorization'] = `Bearer ${accessToken}`;
            }

            return axios(originalRequest);
          } catch (refreshError) {
            // If refresh fails, force logout
            await logout();
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      }
    );

    return () => {
      axios.interceptors.response.eject(interceptor);
    };
  }, []);

  /* auth methods */
  const login = async (email: string, pw: string) => {
    const { user, accessToken, refreshToken } = await authApi.login(email, pw);
    if (user && accessToken && refreshToken) {
      localStorage.setItem('auth_token', accessToken);
      localStorage.setItem('auth_refresh_token', refreshToken);
      axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
      setUser(user);
    }
  };

  const register = async (email: string, pw: string) => {
    const { user, accessToken, refreshToken } = await authApi.register(email, pw);
    if (user && accessToken && refreshToken) {
      localStorage.setItem('auth_token', accessToken);
      localStorage.setItem('auth_refresh_token', refreshToken);
      axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
      setUser(user);
    }
  };

  const logout = async () => {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_refresh_token');
    delete axios.defaults.headers.common['Authorization'];
    setUser(null);
  };

  const updateMetadata = async (fields: Record<string, any>) => {
    const { user } = await authApi.updateMetadata(fields);
    setUser(user);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, updateMetadata }}>
      {children}
    </AuthContext.Provider>
  );
};
