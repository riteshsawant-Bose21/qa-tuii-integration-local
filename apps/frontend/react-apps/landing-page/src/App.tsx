/**
 * Simple Professional App Component
 * Clean black and white design with Auth0 integration
 */

import React, { useEffect } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { useAuth0 } from '@auth0/auth0-react';
import theme from './theme/theme';
import { Box, CircularProgress, Typography } from '@mui/material';
import LoginPage from './components/auth/LoginPage';
import Dashboard from './components/dashboard/Dashboard';
import UserSetupRequired from './components/auth/UserSetupRequired';
import { useUserAuthorization } from './hooks/useApi';

const App: React.FC = () => {
  const { isLoading: authLoading, error: authError, isAuthenticated, logout } = useAuth0();
  const { isLoading: authorizationLoading, isUserNotFound, error: authorizationError } = useUserAuthorization();

  // Automatically redirect to login when token expires
  useEffect(() => {
    if (authorizationError && (authorizationError.includes('expired') || authorizationError.includes('Session expired'))) {
      console.log('Token expired, automatically redirecting to login...');
      logout({ logoutParams: { returnTo: window.location.origin } });
    }
  }, [authorizationError, logout]);

  // Auth0 error
  if (authError) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            minHeight: '100vh',
            flexDirection: 'column',
            gap: 2
          }}
        >
          <Typography variant="h4" color="error">
            Authentication Error
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {authError.message}
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  // Loading Auth0 authentication
  if (authLoading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            minHeight: '100vh',
            flexDirection: 'column',
            gap: 2
          }}
        >
          <CircularProgress size={60} />
          <Typography variant="body1" color="text.secondary">
            Authenticating...
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  // Not authenticated with Auth0 - show login page
  if (!isAuthenticated) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <LoginPage />
      </ThemeProvider>
    );
  }

  // Authenticated with Auth0, but checking backend authorization
  if (authorizationLoading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            minHeight: '100vh',
            flexDirection: 'column',
            gap: 2
          }}
        >
          <CircularProgress size={60} />
          <Typography variant="body1" color="text.secondary">
            Loading account information...
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  // Authenticated with Auth0 but user not found in backend system
  if (isUserNotFound) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <UserSetupRequired />
      </ThemeProvider>
    );
  }

  // Backend authorization error (not user not found)
  if (authorizationError && !isUserNotFound) {
    // If token is expired, show loading while redirecting (useEffect handles the redirect)
    if (authorizationError.includes('expired') || authorizationError.includes('Session expired')) {
      return (
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Box 
            sx={{ 
              display: 'flex', 
              justifyContent: 'center', 
              alignItems: 'center', 
              minHeight: '100vh',
              flexDirection: 'column',
              gap: 2
            }}
          >
            <CircularProgress size={60} />
            <Typography variant="body1" color="text.secondary">
              Session expired. Redirecting to login...
            </Typography>
          </Box>
        </ThemeProvider>
      );
    }
    
    // For other authorization errors, show error message
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            minHeight: '100vh',
            flexDirection: 'column',
            gap: 2
          }}
        >
          <Typography variant="h4" color="error">
            Authorization Error
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {authorizationError}
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  // Successfully authenticated and authorized - show dashboard
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Dashboard />
    </ThemeProvider>
  );
};

export default App;
