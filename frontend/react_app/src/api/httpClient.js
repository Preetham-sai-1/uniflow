/**
 * src/api/httpClient.js
 *
 * Centralized Axios instance configured for the UniFlow Express REST API.
 */

import axios from 'axios';

const baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001/api';

export const httpClient = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

// Request interceptor: attach Bearer token if present
httpClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('uniflow_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor: standard error extraction & session expiration handling
httpClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const errorData = error.response?.data?.error;

    // Build a standardized error payload
    const normalizedError = new Error(
      errorData?.message || error.message || 'An unexpected network error occurred.'
    );
    normalizedError.status = status;
    normalizedError.code = errorData?.code || 'NETWORK_ERROR';
    normalizedError.details = errorData?.details || null;
    normalizedError.raw = error;

    // If 401 Unauthorized occurs on an authenticated route, clear stored session
    if (status === 401 && !error.config.url.includes('/auth/login')) {
      localStorage.removeItem('uniflow_token');
      localStorage.removeItem('uniflow_user');
      window.dispatchEvent(new Event('uniflow_auth_expired'));
    }

    return Promise.reject(normalizedError);
  }
);

export default httpClient;
