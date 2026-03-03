/**
 * Auth0 Configuration
 * Production-ready configuration for Auth0 integration
 */

export interface Auth0Config {
  domain: string;
  clientId: string;
  redirectUri: string;
  audience?: string;
  scope: string;
}

/**
 * Validates required environment variables
 */
function validateEnvVar(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

/**
 * Auth0 configuration with environment validation
 */
export const auth0Config: Auth0Config = {
  domain: validateEnvVar('VITE_AUTH0_DOMAIN', import.meta.env.VITE_AUTH0_DOMAIN),
  clientId: validateEnvVar('VITE_AUTH0_CLIENT_ID', import.meta.env.VITE_AUTH0_CLIENT_ID),
  redirectUri: import.meta.env.VITE_AUTH0_REDIRECT_URI || window.location.origin,
  audience: import.meta.env.VITE_AUTH0_AUDIENCE,
  scope: import.meta.env.VITE_AUTH0_SCOPE || 'openid profile email',
};

/**
 * Auth0Provider configuration options
 */
export const auth0ProviderConfig = {
  domain: auth0Config.domain,
  clientId: auth0Config.clientId,
  authorizationParams: {
    redirect_uri: auth0Config.redirectUri,
    ...(auth0Config.audience && { audience: auth0Config.audience }),
    scope: auth0Config.scope,
  },
  cacheLocation: 'localstorage' as const,
  useRefreshTokens: true,
  useRefreshTokensFallback: false,
};