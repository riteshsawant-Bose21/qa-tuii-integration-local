/**
 * API Hooks
 * React hooks for making authenticated API calls with Auth0 tokens
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth0 } from '@auth0/auth0-react';
import { ApiClient, createApiClient } from '../services/apiClient';
import type { ApiResponse, UserAuthorizationResponse } from '../services/apiClient';

/**
 * Hook for getting an authenticated API client
 */
export const useApiClient = (): {
  apiClient: ApiClient | null;
  isLoading: boolean;
  error: string | null;
} => {
  const { getIdTokenClaims, isAuthenticated, isLoading: authLoading } = useAuth0();
  const [apiClient, setApiClient] = useState<ApiClient | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);



  const initializeApiClient = useCallback(async () => {
    if (authLoading) return;

    try {
      setIsLoading(true);
      setError(null);

      if (isAuthenticated) {
        // Get Auth0 ID token (JWT format) instead of access token (JWE format)
        const idTokenClaims = await getIdTokenClaims();
        const token = idTokenClaims?.__raw;

        if (!token) {
          throw new Error('Failed to get ID token from Auth0');
        }

        // Create API client with ID token (JWT)
        const client = createApiClient(token);
        setApiClient(client);
      } else {
        // Create API client without token for public endpoints
        setApiClient(createApiClient());
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to initialize API client');
      setApiClient(createApiClient()); // Fallback to client without token
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated, authLoading, getIdTokenClaims]);

  useEffect(() => {
    initializeApiClient();
  }, [initializeApiClient]);

  return { apiClient, isLoading, error };
};

/**
 * Hook for fetching user authorization (roles and permissions)
 */
export const useUserAuthorization = () => {
  const { apiClient, isLoading: clientLoading } = useApiClient();
  const { isAuthenticated } = useAuth0();
  const [authorization, setAuthorization] = useState<UserAuthorizationResponse | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasFetched, setHasFetched] = useState(false);

  const fetchAuthorization = useCallback(async () => {
    if (!apiClient || !isAuthenticated) {
      return;
    }

    // Check if API client has a token
    if (!apiClient.hasToken()) {
      return;
    }
    
    try {
      setIsLoading(true);
      setError(null);

      const response = await apiClient.getUserAuthorization();

      if (response.success && response.data) {
        setAuthorization(response.data);
      } else {
        throw new Error(response.error || 'Failed to fetch user authorization');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch authorization');
      setAuthorization(null);
    } finally {
      setIsLoading(false);
      setHasFetched(true);
    }
  }, [apiClient, isAuthenticated]);

    // Auto-fetch when authenticated and API client is ready (only once)
  useEffect(() => {
    if (isAuthenticated && apiClient && !clientLoading && !hasFetched) {
      fetchAuthorization();
    }
  }, [isAuthenticated, apiClient, clientLoading, hasFetched, fetchAuthorization]);

  const refetch = useCallback(() => {
    setHasFetched(false); // Reset the fetch flag to allow refetch
    fetchAuthorization();
  }, [fetchAuthorization]);

  return {
    authorization,
    isLoading: isLoading || clientLoading,
    error,
    refetch,
  };
};

/**
 * Generic hook for making API calls
 */
export const useApiCall = <T = any>() => {
  const { apiClient } = useApiClient();
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async (
    apiCall: (client: ApiClient) => Promise<ApiResponse<T>>
  ): Promise<ApiResponse<T>> => {
    if (!apiClient) {
      const errorResponse: ApiResponse<T> = {
        success: false,
        error: 'API client not available',
        status: 0,
      };
      setError('API client not available');
      return errorResponse;
    }

    try {
      setIsLoading(true);
      setError(null);

      const response = await apiCall(apiClient);

      if (response.success && response.data) {
        setData(response.data);
      } else {
        setError(response.error || 'API call failed');
      }

      return response;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);

      return {
        success: false,
        error: errorMessage,
        status: 0,
      };
    } finally {
      setIsLoading(false);
    }
  }, [apiClient]);

  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setIsLoading(false);
  }, []);

  return {
    data,
    isLoading,
    error,
    execute,
    reset,
  };
};

