/**
 * API Client Configuration
 * Centralized API client with Auth0 token integration
 */

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';

// Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  status: number;
}

export interface UserAuthorizationResponse {
  user: {
    id: string;
    email: string;
  };
  account: {
    id: string;
    name: string;
    description: string;
    type: string;
  };
  role: {
    id: number;
    role_name: string;
  };
  permissions: Record<string, string>;
}

export interface ApiError {
  message: string;
  status: number;
  code?: string;
}

/**
 * HTTP Methods
 */
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';

/**
 * Request options interface
 */
interface RequestOptions {
  method?: HttpMethod;
  headers?: Record<string, string>;
  body?: any;
  token?: string;
}

/**
 * Generic API request function with Auth0 token support
 */
export const apiRequest = async <T = any>(
  endpoint: string,
  options: RequestOptions = {}
): Promise<ApiResponse<T>> => {
  const { method = 'GET', headers = {}, body, token } = options;

  // Prepare headers
  const requestHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    ...headers,
  };

  // Add Authorization header if token is provided
  if (token) {
    requestHeaders['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method,
      headers: requestHeaders,
      body: body ? JSON.stringify(body) : undefined,
    });

    // Parse response
    let responseData: any = {};
    const contentType = response.headers.get('content-type');
    
    if (contentType && contentType.includes('application/json')) {
      try {
        responseData = await response.json();
      } catch (jsonError) {
        // Ignore JSON parsing errors for now
      }
    } else {
      // Handle non-JSON responses
      responseData = { message: await response.text() };
    }

    return {
      success: response.ok,
      data: response.ok ? responseData : responseData, // Include responseData even for errors
      message: responseData.message,
      error: !response.ok ? responseData.error || responseData.message || `HTTP ${response.status}` : undefined,
      status: response.status,
    };
  } catch (error) {
    return {
      success: false,
      data: undefined,
      error: error instanceof Error ? error.message : 'Network error',
      status: 0
    };
  }
};

/**
 * Token refresh handler type
 */
export type TokenRefreshHandler = () => Promise<string | null>;

/**
 * API Client class with token refresh support
 */
export class ApiClient {
  private token?: string;
  private tokenRefreshHandler?: TokenRefreshHandler;
  private isRefreshing = false;
  private refreshPromise?: Promise<string | null>;

  constructor(token?: string) {
    this.token = token;
  }

  /**
   * Set authentication token
   */
  setToken(token: string) {
    this.token = token;
  }

  /**
   * Clear authentication token
   */
  clearToken() {
    this.token = undefined;
  }

  /**
   * Check if the client has a token
   */
  hasToken(): boolean {
    return !!this.token;
  }

  /**
   * Set token refresh handler
   */
  setTokenRefreshHandler(handler: TokenRefreshHandler) {
    this.tokenRefreshHandler = handler;
  }

  /**
   * Refresh token if needed
   */
  private async refreshTokenIfNeeded(): Promise<string | null> {
    if (!this.tokenRefreshHandler) {
      console.log('No token refresh handler available');
      return this.token || null;
    }

    // If already refreshing, wait for the existing refresh
    if (this.isRefreshing && this.refreshPromise) {
      console.log('Token refresh already in progress, waiting...');
      return this.refreshPromise;
    }

    // Start refresh process
    console.log('Starting token refresh process...');
    this.isRefreshing = true;
    this.refreshPromise = this.tokenRefreshHandler();

    try {
      const newToken = await this.refreshPromise;
      if (newToken) {
        console.log('Token refresh successful, updating stored token');
        this.token = newToken;
      } else {
        console.log('Token refresh returned null');
      }
      return newToken;
    } catch (error) {
      console.error('Token refresh failed:', error);
      return null;
    } finally {
      this.isRefreshing = false;
      this.refreshPromise = undefined;
    }
  }

  /**
   * Check if error indicates token expiration
   */
  private isTokenExpiredError(response: ApiResponse<any>): boolean {
    if (response.status !== 401) return false;
    
    // Check if the response data indicates token expiration
    const data = response.data || {};
    const errorCode = data.code || '';
    const errorMessage = (response.error || '').toLowerCase();
    const details = (data.details || '').toLowerCase();
    
    const isExpired = (
      errorCode === 'TOKEN_EXPIRED' ||
      errorMessage.includes('expired') ||
      errorMessage.includes('session expired') ||
      details.includes('expired') ||
      details.includes('token is expired')
    );
    
    console.log('Checking if token expired:', {
      status: response.status,
      errorCode,
      errorMessage,
      details,
      isExpired
    });
    
    return isExpired;
  }

  /**
   * Make request with automatic token refresh on 401
   */
  private async makeRequestWithRefresh<T>(
    requestFn: () => Promise<ApiResponse<T>>
  ): Promise<ApiResponse<T>> {
    // First attempt
    let response = await requestFn();

    // If we get a token expiration error and have a refresh handler, try to refresh
    if (this.isTokenExpiredError(response) && this.tokenRefreshHandler) {
      console.log('Token expired, attempting refresh...');
      
      const newToken = await this.refreshTokenIfNeeded();
      
      if (newToken) {
        console.log('Token refreshed successfully, retrying request...');
        // Retry the request with the new token
        response = await requestFn();
      } else {
        console.warn('Token refresh failed');
      }
    } else if (response.status === 401) {
      console.log('Received 401 but not a token expiration error:', response.error);
    }

    return response;
  }

  /**
   * Make authenticated GET request with token refresh
   */
  async get<T = any>(endpoint: string): Promise<ApiResponse<T>> {
    return this.makeRequestWithRefresh(() =>
      apiRequest<T>(endpoint, {
        method: 'GET',
        token: this.token,
      })
    );
  }

  /**
   * Make authenticated POST request with token refresh
   */
  async post<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.makeRequestWithRefresh(() =>
      apiRequest<T>(endpoint, {
        method: 'POST',
        body: data,
        token: this.token,
      })
    );
  }

  /**
   * Make authenticated PUT request with token refresh
   */
  async put<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.makeRequestWithRefresh(() =>
      apiRequest<T>(endpoint, {
        method: 'PUT',
        body: data,
        token: this.token,
      })
    );
  }

  /**
   * Make authenticated DELETE request with token refresh
   */
  async delete<T = any>(endpoint: string): Promise<ApiResponse<T>> {
    return this.makeRequestWithRefresh(() =>
      apiRequest<T>(endpoint, {
        method: 'DELETE',
        token: this.token,
      })
    );
  }

  /**
   * Get user roles and permissions from backend
   */
  async getUserAuthorization(): Promise<ApiResponse<UserAuthorizationResponse>> {
    return this.get<UserAuthorizationResponse>('/api/v1/user/me/authorization');
  }
}

/**
 * Create API client instance
 */
export const createApiClient = (token?: string): ApiClient => {
  return new ApiClient(token);
};

/**
 * Default API client instance (token will be set dynamically)
 */
export const apiClient = new ApiClient();