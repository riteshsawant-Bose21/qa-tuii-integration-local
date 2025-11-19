/**
 * API Hooks
 * React hooks for making authenticated API calls with Auth0 tokens
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth0 } from '@auth0/auth0-react';
import { ApiClient, createApiClient } from '../services/apiClient';
import type { ApiResponse, UserAuthorizationResponse } from '../services/apiClient';

/**
 * Hook for getting an authenticated API client with automatic token refresh
 */
export const useApiClient = (): {
  apiClient: ApiClient | null;
  isLoading: boolean;
  error: string | null;
} => {
  const { getIdTokenClaims, getAccessTokenSilently, isAuthenticated, isLoading: authLoading, loginWithRedirect } = useAuth0();
  const [apiClient, setApiClient] = useState<ApiClient | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const getToken = useCallback(async (forceRefresh: boolean = false): Promise<string | null> => {
    try {
      if (forceRefresh) {
        console.log('Force refreshing ID token silently...');
        // Use silent authentication to get fresh token
        try {
          await getAccessTokenSilently({ cacheMode: 'off' });
          console.log('Silent token refresh completed');
        } catch (silentError) {
          console.log('Silent refresh failed:', silentError);
          // Fallback to regular token retrieval
        }
      }
      
      // Try to get a fresh ID token
      const idTokenClaims = await getIdTokenClaims();
      const token = idTokenClaims?.__raw;

      if (!token) {
        console.warn('No ID token available from Auth0');
        return null;
      }

      console.log('Token acquired successfully');
      return token;
    } catch (err) {
      console.error('Failed to get ID token:', err);
      return null;
    }
  }, [getIdTokenClaims, getAccessTokenSilently]);

  const initializeApiClient = useCallback(async () => {
    if (authLoading) return;

    try {
      setIsLoading(true);
      setError(null);

      if (isAuthenticated) {
        const token = await getToken();

        if (!token) {
          throw new Error('Failed to get ID token from Auth0');
        }



        // Create API client with token refresh capability
        const client = createApiClient(token);
        
        // Enhance the client with token refresh capability
        client.setTokenRefreshHandler(async () => {
          console.log('Token refresh handler called - attempting silent token renewal');
          try {
            const freshToken = await getToken(true); // Force refresh
            if (!freshToken) {
              console.warn('Unable to refresh token silently, will redirect to login on next attempt');
              return null;
            }
            console.log('Token refreshed successfully');
            return freshToken;
          } catch (error) {
            console.error('Token refresh failed:', error);
            return null;
          }
        });

        setApiClient(client);
      } else {
        // Create API client without token for public endpoints
        setApiClient(createApiClient());
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to initialize API client';
      console.error('API Client initialization error:', errorMessage);
      setError(errorMessage);
      setApiClient(createApiClient()); // Fallback to client without token
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated, authLoading, getToken, loginWithRedirect]);

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
  const [isUserNotFound, setIsUserNotFound] = useState(false);
  const [hasFetched, setHasFetched] = useState(false);

  // Auto-fetch when authenticated and API client is ready (only once)
  useEffect(() => {
    const fetchAuthorization = async () => {
      if (!apiClient || !isAuthenticated || !apiClient.hasToken()) {
        return;
      }
      
      try {
        setIsLoading(true);
        setError(null);
        setIsUserNotFound(false);

        const response = await apiClient.getUserAuthorization();


        if (response.success && response.data) {
          setAuthorization(response.data);
          setIsUserNotFound(false);
        } else {
          // Check if this is a 404 "User Not Found" error
          if (response.status === 404 && response.error?.includes('User Not Found')) {
            setIsUserNotFound(true);
            setError(response.error);
          } else if (response.status === 401) {
            // Handle authorization errors (token issues)
            const data = response.data as any || {};
            const errorCode = data.code || '';
            const details = data.details || '';
            
            let errorMessage = response.error || 'Authentication failed';
            
            if (errorCode === 'TOKEN_EXPIRED') {
              errorMessage = 'Session expired. Please refresh the page or log in again.';
            } else if (errorCode === 'TOKEN_MALFORMED') {
              errorMessage = `Token format error: ${details}`;
            } else if (errorCode === 'UNSUPPORTED_TOKEN_FORMAT') {
              errorMessage = `Auth0 configuration issue: ${details}`;
            } else if (details) {
              errorMessage = `Authentication failed: ${details}`;
            }
            
            setError(errorMessage);
            setIsUserNotFound(false);
          } else {
            // Other types of errors
            setError(response.error || 'Failed to fetch user authorization');
            setIsUserNotFound(false);
          }
          setAuthorization(null);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch authorization');
        setAuthorization(null);
        setIsUserNotFound(false);
      } finally {
        setIsLoading(false);
        setHasFetched(true);
      }
    };

    if (isAuthenticated && apiClient && !clientLoading && !hasFetched) {
      fetchAuthorization();
    }
  }, [isAuthenticated, apiClient, clientLoading, hasFetched]);

  const refetch = useCallback(() => {
    setHasFetched(false); // Reset the fetch flag to allow refetch
    // The useEffect will automatically trigger when hasFetched becomes false
  }, []);

  return {
    authorization,
    isLoading: isLoading || clientLoading,
    error,
    isUserNotFound,
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

