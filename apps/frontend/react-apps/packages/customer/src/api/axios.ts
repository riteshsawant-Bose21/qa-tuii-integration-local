import axios from 'axios';

const api = axios.create({
    baseURL: import.meta.env.VITE_APP_BACKEND_URL || 'http://localhost:4000/api',
    withCredentials: true,
});

// The server returns an access token we attach manually
api.interceptors.request.use((cfg) => {
    const token = localStorage.getItem('auth_token');
    if (token) cfg.headers!.Authorization = `Bearer ${token}`;
    return cfg;
});

export default api;
