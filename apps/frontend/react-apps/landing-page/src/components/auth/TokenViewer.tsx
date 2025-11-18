/**
 * Token Viewer Component (Temporary)
 * Displays ID token and Access token information for debugging
 */

import React, { useState, useEffect } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  Alert,
  Grid,
} from "@mui/material";
import {
  ExpandMore as ExpandMoreIcon,
  Token as TokenIcon,
  ContentCopy as CopyIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
} from "@mui/icons-material";
import { useAuth0 } from "@auth0/auth0-react";

interface TokenInfo {
  raw: string;
  header: any;
  payload: any;
  segments: number;
  type: 'JWT' | 'JWE' | 'Unknown';
}

interface Auth0Data {
  accessToken: TokenInfo | null;
  idToken: TokenInfo | null;
  idTokenClaims: any;
  userProfile: any;
  rawAuth0Response: any;
}

const TokenViewer: React.FC = () => {
  const { getAccessTokenSilently, getIdTokenClaims, user, isAuthenticated } = useAuth0();
  const [accessToken, setAccessToken] = useState<TokenInfo | null>(null);
  const [idToken, setIdToken] = useState<TokenInfo | null>(null);
  const [idTokenClaims, setIdTokenClaims] = useState<any>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showTokens, setShowTokens] = useState(false);
  const [showRawData, setShowRawData] = useState(false);

  const parseToken = (token: string): TokenInfo => {
    const segments = token.split('.');
    const type = segments.length === 3 ? 'JWT' : segments.length === 5 ? 'JWE' : 'Unknown';
    
    let header = null;
    let payload = null;

    try {
      if (type === 'JWT') {
        // Parse JWT header and payload
        header = JSON.parse(atob(segments[0].replace(/-/g, '+').replace(/_/g, '/')));
        payload = JSON.parse(atob(segments[1].replace(/-/g, '+').replace(/_/g, '/')));
      } else if (type === 'JWE') {
        // For JWE, we can only parse the header (first segment)
        header = JSON.parse(atob(segments[0].replace(/-/g, '+').replace(/_/g, '/')));
        payload = { note: 'JWE payload is encrypted and cannot be displayed' };
      }
    } catch (e) {
      header = { error: 'Failed to parse header' };
      payload = { error: 'Failed to parse payload' };
    }

    return {
      raw: token,
      header,
      payload,
      segments: segments.length,
      type,
    };
  };

  const fetchTokens = async () => {
    if (!isAuthenticated) return;

    setLoading(true);
    setError(null);

    try {
      // Get Access Token
      const accessTokenRaw = await getAccessTokenSilently({
        authorizationParams: {
          scope: 'openid profile email',
        },
      });
      setAccessToken(parseToken(accessTokenRaw));

      // Get ID Token Claims (complete raw response from Auth0)
      const rawIdTokenClaims = await getIdTokenClaims();
      setIdTokenClaims(rawIdTokenClaims);
      
      if (rawIdTokenClaims?.__raw) {
        setIdToken(parseToken(rawIdTokenClaims.__raw));
      }

      // Set user profile data
      setUserProfile(user);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch tokens');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isAuthenticated) {
      fetchTokens();
    }
  }, [isAuthenticated]);

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const formatTokenTable = (tokenInfo: TokenInfo) => {
    const rows: Array<{ key: string; value: any }> = [];

    // Add basic info
    rows.push({ key: 'Type', value: tokenInfo.type });
    rows.push({ key: 'Segments', value: tokenInfo.segments });
    rows.push({ key: 'Length', value: tokenInfo.raw.length });

    // Add header info
    if (tokenInfo.header) {
      Object.entries(tokenInfo.header).forEach(([key, value]) => {
        rows.push({ key: `Header.${key}`, value });
      });
    }

    // Add payload info
    if (tokenInfo.payload) {
      Object.entries(tokenInfo.payload).forEach(([key, value]) => {
        rows.push({ key: `Payload.${key}`, value });
      });
    }

    return rows;
  };

  if (!isAuthenticated) {
    return (
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Token Information
          </Typography>
          <Alert severity="info">Please log in to view token information.</Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Typography variant="h6" gutterBottom>
            <TokenIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Token Information (Debug)
          </Typography>
          <Box>
            <Button
              variant="outlined"
              size="small"
              onClick={() => setShowTokens(!showTokens)}
              startIcon={showTokens ? <VisibilityOffIcon /> : <VisibilityIcon />}
              sx={{ mr: 1 }}
            >
              {showTokens ? 'Hide' : 'Show'} Token Strings
            </Button>
            <Button
              variant="outlined"
              size="small"
              onClick={() => setShowRawData(!showRawData)}
              startIcon={showRawData ? <VisibilityOffIcon /> : <VisibilityIcon />}
              sx={{ mr: 1 }}
            >
              {showRawData ? 'Hide' : 'Show'} All Raw Data
            </Button>
            <Button
              variant="contained"
              size="small"
              onClick={fetchTokens}
              disabled={loading}
            >
              Refresh All Data
            </Button>
          </Box>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {/* Raw Auth0 Data Section */}
        <Accordion sx={{ mb: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" gap={1}>
              <Typography variant="h6">Complete Auth0 Raw Data</Typography>
              <Button
                variant="outlined"
                size="small"
                onClick={() => setShowRawData(!showRawData)}
                startIcon={showRawData ? <VisibilityOffIcon /> : <VisibilityIcon />}
              >
                {showRawData ? 'Hide' : 'Show'} Raw JSON
              </Button>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              {/* User Profile from Auth0 */}
              <Grid size={{ xs: 12, md: 4 }}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" gutterBottom>
                      User Profile (from useAuth0 hook)
                    </Typography>
                    {userProfile ? (
                      <Box>
                        {showRawData ? (
                          <Paper
                            sx={{
                              p: 2,
                              bgcolor: 'grey.50',
                              maxHeight: 300,
                              overflow: 'auto',
                              fontSize: '0.75rem',
                              fontFamily: 'monospace',
                            }}
                          >
                            <pre>{JSON.stringify(userProfile, null, 2)}</pre>
                            <Button
                              size="small"
                              onClick={() => copyToClipboard(JSON.stringify(userProfile, null, 2))}
                              sx={{ mt: 1 }}
                              startIcon={<CopyIcon />}
                            >
                              Copy JSON
                            </Button>
                          </Paper>
                        ) : (
                          <Typography variant="body2" color="text.secondary">
                            Click "Show Raw JSON" to view complete user profile data
                          </Typography>
                        )}
                      </Box>
                    ) : (
                      <Typography color="text.secondary">No user profile data</Typography>
                    )}
                  </CardContent>
                </Card>
              </Grid>

              {/* ID Token Claims */}
              <Grid size={{ xs: 12, md: 4 }}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" gutterBottom>
                      ID Token Claims (Raw Auth0 Response)
                    </Typography>
                    {idTokenClaims ? (
                      <Box>
                        {showRawData ? (
                          <Paper
                            sx={{
                              p: 2,
                              bgcolor: 'grey.50',
                              maxHeight: 300,
                              overflow: 'auto',
                              fontSize: '0.75rem',
                              fontFamily: 'monospace',
                            }}
                          >
                            <pre>{JSON.stringify(idTokenClaims, null, 2)}</pre>
                            <Button
                              size="small"
                              onClick={() => copyToClipboard(JSON.stringify(idTokenClaims, null, 2))}
                              sx={{ mt: 1 }}
                              startIcon={<CopyIcon />}
                            >
                              Copy JSON
                            </Button>
                          </Paper>
                        ) : (
                          <Typography variant="body2" color="text.secondary">
                            Click "Show Raw JSON" to view complete ID token claims
                          </Typography>
                        )}
                      </Box>
                    ) : (
                      <Typography color="text.secondary">No ID token claims data</Typography>
                    )}
                  </CardContent>
                </Card>
              </Grid>

              {/* Token Summary */}
              <Grid size={{ xs: 12, md: 4 }}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" gutterBottom>
                      Token Summary
                    </Typography>
                    <Box display="flex" flexDirection="column" gap={1}>
                      {accessToken && (
                        <Chip
                          label={`Access Token: ${accessToken.type} (${accessToken.segments} segments)`}
                          color={accessToken.type === 'JWT' ? 'success' : 'warning'}
                          size="small"
                        />
                      )}
                      {idToken && (
                        <Chip
                          label={`ID Token: ${idToken.type} (${idToken.segments} segments)`}
                          color={idToken.type === 'JWT' ? 'success' : 'warning'}
                          size="small"
                        />
                      )}
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
                        • JWT = 3 segments (Header.Payload.Signature)
                        <br />
                        • JWE = 5 segments (Encrypted format)
                        <br />
                        • Backend expects JWT format for validation
                      </Typography>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        <Grid container spacing={2}>
          {/* Access Token */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Box display="flex" alignItems="center" gap={1}>
                  <Typography variant="subtitle1">Access Token</Typography>
                  {accessToken && (
                    <Chip
                      label={accessToken.type}
                      color={accessToken.type === 'JWT' ? 'success' : accessToken.type === 'JWE' ? 'warning' : 'error'}
                      size="small"
                    />
                  )}
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                {accessToken ? (
                  <Box>
                    {showTokens && (
                      <Box mb={2}>
                        <Typography variant="caption" display="block" gutterBottom>
                          Raw Token:
                        </Typography>
                        <Paper
                          sx={{
                            p: 1,
                            bgcolor: 'grey.100',
                            wordBreak: 'break-all',
                            fontSize: '0.75rem',
                            fontFamily: 'monospace',
                            maxHeight: 100,
                            overflow: 'auto',
                          }}
                        >
                          {accessToken.raw}
                          <Button
                            size="small"
                            onClick={() => copyToClipboard(accessToken.raw)}
                            sx={{ ml: 1, minWidth: 'auto', p: 0.5 }}
                          >
                            <CopyIcon fontSize="small" />
                          </Button>
                        </Paper>
                      </Box>
                    )}
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>Property</TableCell>
                            <TableCell>Value</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {formatTokenTable(accessToken).map((row, index) => (
                            <TableRow key={index}>
                              <TableCell component="th" scope="row" sx={{ fontWeight: 'bold' }}>
                                {row.key}
                              </TableCell>
                              <TableCell sx={{ wordBreak: 'break-all', fontSize: '0.875rem' }}>
                                {typeof row.value === 'object' 
                                  ? JSON.stringify(row.value, null, 2) 
                                  : String(row.value)
                                }
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Box>
                ) : (
                  <Typography color="text.secondary">
                    {loading ? 'Loading...' : 'No access token available'}
                  </Typography>
                )}
              </AccordionDetails>
            </Accordion>
          </Grid>

          {/* ID Token */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Box display="flex" alignItems="center" gap={1}>
                  <Typography variant="subtitle1">ID Token</Typography>
                  {idToken && (
                    <Chip
                      label={idToken.type}
                      color={idToken.type === 'JWT' ? 'success' : idToken.type === 'JWE' ? 'warning' : 'error'}
                      size="small"
                    />
                  )}
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                {idToken ? (
                  <Box>
                    {showTokens && (
                      <Box mb={2}>
                        <Typography variant="caption" display="block" gutterBottom>
                          Raw Token:
                        </Typography>
                        <Paper
                          sx={{
                            p: 1,
                            bgcolor: 'grey.100',
                            wordBreak: 'break-all',
                            fontSize: '0.75rem',
                            fontFamily: 'monospace',
                            maxHeight: 100,
                            overflow: 'auto',
                          }}
                        >
                          {idToken.raw}
                          <Button
                            size="small"
                            onClick={() => copyToClipboard(idToken.raw)}
                            sx={{ ml: 1, minWidth: 'auto', p: 0.5 }}
                          >
                            <CopyIcon fontSize="small" />
                          </Button>
                        </Paper>
                      </Box>
                    )}
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>Property</TableCell>
                            <TableCell>Value</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {formatTokenTable(idToken).map((row, index) => (
                            <TableRow key={index}>
                              <TableCell component="th" scope="row" sx={{ fontWeight: 'bold' }}>
                                {row.key}
                              </TableCell>
                              <TableCell sx={{ wordBreak: 'break-all', fontSize: '0.875rem' }}>
                                {typeof row.value === 'object' 
                                  ? JSON.stringify(row.value, null, 2) 
                                  : String(row.value)
                                }
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Box>
                ) : (
                  <Typography color="text.secondary">
                    {loading ? 'Loading...' : 'No ID token available'}
                  </Typography>
                )}
              </AccordionDetails>
            </Accordion>
          </Grid>
        </Grid>

        <Alert severity="warning" sx={{ mt: 2 }}>
          <Typography variant="body2">
            <strong>🚨 Debug Mode:</strong> This component displays complete Auth0 raw data including sensitive tokens, user profiles, and claims. 
            Remove this component in production. 
            <br />
            <strong>Token Status:</strong> Access Token = {accessToken?.type || 'Unknown'}, ID Token = {idToken?.type || 'Unknown'}
            <br />
            <strong>Backend Compatibility:</strong> {idToken?.type === 'JWT' ? '✅ ID Token is JWT - Compatible' : '❌ ID Token is not JWT - May cause issues'}
          </Typography>
        </Alert>
      </CardContent>
    </Card>
  );
};

export default TokenViewer;