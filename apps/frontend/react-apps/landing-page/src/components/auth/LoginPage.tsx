/**
 * Simple Professional Login Page
 * Clean black and white design
 */

import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Container,
  Stack,
} from '@mui/material';
import { useAuth0 } from '@auth0/auth0-react';
import BoseProLogo from '../../assets/bose_pro_logo_lines_black.png';

const LoginPage: React.FC = () => {
  const { loginWithRedirect, isLoading } = useAuth0();

  const handleLogin = () => {
    loginWithRedirect();
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#ffffff',
      }}
    >
      <Container maxWidth="sm">
        <Box textAlign="center" mb={4}>
          <Box
            component="img"
            src={BoseProLogo}
            alt="Bose Professional"
            sx={{
              height: 60,
              width: 'auto',
              mb: 2,
            }}
          />
          <Typography variant="h2" component="h1" gutterBottom>
            Fusion
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Professional Audio System Management
          </Typography>
        </Box>

        <Card
          sx={{
            maxWidth: 400,
            mx: 'auto',
            p: 3,
          }}
        >
          <CardContent>
            <Stack spacing={3} alignItems="center">
              <Typography variant="h5" component="h2" textAlign="center">
                Sign In
              </Typography>
              
              <Typography variant="body2" color="text.secondary" textAlign="center">
                Access your professional dashboard to manage audio systems and projects.
              </Typography>

              <Button
                variant="contained"
                size="large"
                fullWidth
                onClick={handleLogin}
                disabled={isLoading}
                sx={{
                  py: 1.5,
                  fontSize: '1rem',
                }}
              >
                {isLoading ? 'Signing In...' : 'Sign In with Auth0'}
              </Button>

              <Typography variant="body2" color="text.secondary" textAlign="center">
                Secure authentication powered by Auth0
              </Typography>
            </Stack>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
};

export default LoginPage;