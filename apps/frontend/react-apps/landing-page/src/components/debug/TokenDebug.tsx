/**
 * Token Debug Component
 * Helper to inspect token format and debug JWT/JWE issues
 */

import React, { useState, useEffect } from 'react';
import { useAuth0 } from '@auth0/auth0-react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  Stack,
  Divider,
} from '@mui/material';
import type { UserAuthorizationResponse } from '../../services/apiClient';

interface TokenDebugProps {
  authorizationData?: UserAuthorizationResponse | null;
}

const TokenDebug: React.FC<TokenDebugProps> = ({ authorizationData }) => {
  const { getIdTokenClaims, getAccessTokenSilently, isAuthenticated } = useAuth0();
  const [tokenInfo, setTokenInfo] = useState<{
    idToken?: string;
    idTokenSegments?: number;
    accessToken?: string;
    accessTokenSegments?: number;
    apiResponse?: any;
    error?: string;
  }>({});

  useEffect(() => {
    if (!isAuthenticated) return;

    const fetchTokens = async () => {
      try {
        // Get ID Token (should be JWT - 3 segments)
        const idTokenClaims = await getIdTokenClaims();
        const idToken = idTokenClaims?.__raw;
        
        // Get Access Token (might be JWE - 5 segments)
        const accessToken = await getAccessTokenSilently();

        // Use authorization data passed as props instead of making API call
        const apiResponse = authorizationData || null;

        setTokenInfo({
          idToken: idToken ? `${idToken.substring(0, 50)}...` : 'Not available',
          idTokenSegments: idToken ? idToken.split('.').length : 0,
          accessToken: accessToken ? `${accessToken.substring(0, 50)}...` : 'Not available',
          accessTokenSegments: accessToken ? accessToken.split('.').length : 0,
          apiResponse,
        });
      } catch (error) {
        setTokenInfo({
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    };

    fetchTokens();
  }, [isAuthenticated, getIdTokenClaims, getAccessTokenSilently]);

  if (!isAuthenticated) {
    return null;
  }

  return (
    <Card sx={{ mt: 2 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Token Debug Information
        </Typography>
        
        {tokenInfo.error ? (
          <Typography color="error">{tokenInfo.error}</Typography>
        ) : (
          <Stack spacing={2}>
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                ID Token (JWT for backend):
              </Typography>
              <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                {tokenInfo.idToken}
              </Typography>
              <Chip 
                label={`${tokenInfo.idTokenSegments} segments ${tokenInfo.idTokenSegments === 3 ? '✓ JWT' : '✗ Not JWT'}`}
                color={tokenInfo.idTokenSegments === 3 ? 'success' : 'error'}
                size="small"
                sx={{ mt: 1 }}
              />
            </Box>
            
            <Divider />
            
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Access Token (API calls):
              </Typography>
              <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                {tokenInfo.accessToken}
              </Typography>
              <Chip 
                label={`${tokenInfo.accessTokenSegments} segments ${tokenInfo.accessTokenSegments === 5 ? 'JWE' : tokenInfo.accessTokenSegments === 3 ? 'JWT' : 'Unknown'}`}
                color={tokenInfo.accessTokenSegments === 3 ? 'success' : 'warning'}
                size="small"
                sx={{ mt: 1 }}
              />
            </Box>
            
            <Divider />
            
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                API Response (/api/v1/users/authorization):
              </Typography>
              <Box sx={{ p: 2, bgcolor: '#f5f5f5', borderRadius: 1, fontFamily: 'monospace', fontSize: '0.75rem', overflow: 'auto', maxHeight: 200 }}>
                <pre>{JSON.stringify(tokenInfo.apiResponse, null, 2)}</pre>
              </Box>
            </Box>
            
            <Box sx={{ p: 2, bgcolor: '#f5f5f5', borderRadius: 1 }}>
              <Typography variant="caption">
                <strong>Note:</strong> Backend expects JWT (3 segments). Using ID token for API calls.
              </Typography>
            </Box>
          </Stack>
        )}
      </CardContent>
    </Card>
  );
};

export default TokenDebug;