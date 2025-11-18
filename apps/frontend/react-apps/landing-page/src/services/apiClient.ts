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
      data: response.ok ? responseData : undefined,
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
 * API Client class with common methods
 */
export class ApiClient {
  private token?: string;

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
   * Make authenticated GET request
   */
  async get<T = any>(endpoint: string): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      method: 'GET',
      token: this.token,
    });
  }

  /**
   * Make authenticated POST request
   */
  async post<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      method: 'POST',
      body: data,
      token: this.token,
    });
  }

  /**
   * Make authenticated PUT request
   */
  async put<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      method: 'PUT',
      body: data,
      token: this.token,
    });
  }

  /**
   * Make authenticated DELETE request
   */
  async delete<T = any>(endpoint: string): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      method: 'DELETE',
      token: this.token,
    });
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