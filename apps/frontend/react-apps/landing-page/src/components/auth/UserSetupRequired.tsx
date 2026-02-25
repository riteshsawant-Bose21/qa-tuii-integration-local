/**
 * User Setup Required Component
 * Shown when user is authenticated via Auth0 but not registered in the backend system
 */

import React from 'react';
import {
  Box,
  Container,
  Card,
  CardContent,
  Typography,
  Button,
  Stack,
  Alert,
  Divider,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  Person as PersonIcon,
  Email as EmailIcon,
  AdminPanelSettings as AdminIcon,
  ContactSupport as SupportIcon,
  Logout as LogoutIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import BoseProLogo from '../../assets/bose_pro_logo_lines_black.png';

const UserSetupRequired: React.FC = () => {
  const { user, logout } = useAuth0();

  const handleLogout = () => {
    logout({ logoutParams: { returnTo: window.location.origin } });
  };

  const handleContactSupport = () => {
    // You can customize this based on your support process
    window.open('mailto:support@bose.com?subject=Account Setup Required', '_blank');
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f5f5f5',
        p: 2,
      }}
    >
      <Container maxWidth="md">
        <Stack spacing={4} alignItems="center">
          {/* Logo */}
          <Box
            component="img"
            src={BoseProLogo}
            alt="Bose Professional"
            sx={{
              height: 60,
              width: 'auto',
            }}
          />

          {/* Main Card */}
          <Card sx={{ width: '100%', maxWidth: 600 }}>
            <CardContent sx={{ p: 4 }}>
              <Stack spacing={3}>
                {/* Header */}
                <Box textAlign="center">
                  <AdminIcon sx={{ fontSize: 64, color: 'warning.main', mb: 2 }} />
                  <Typography variant="h4" component="h1" gutterBottom>
                    Account Setup Required
                  </Typography>
                  <Typography variant="body1" color="text.secondary">
                    Your authentication was successful, but your account needs to be set up in our system.
                  </Typography>
                </Box>

                <Divider />

                {/* User Info */}
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Your Authentication Details
                  </Typography>
                  <List>
                    <ListItem disablePadding>
                      <ListItemIcon>
                        <PersonIcon />
                      </ListItemIcon>
                      <ListItemText
                        primary="Name"
                        secondary={user?.name || 'Not provided'}
                      />
                    </ListItem>
                    <ListItem disablePadding>
                      <ListItemIcon>
                        <EmailIcon />
                      </ListItemIcon>
                      <ListItemText
                        primary="Email"
                        secondary={user?.email || 'Not provided'}
                      />
                    </ListItem>
                  </List>
                </Box>

                <Divider />

                {/* Instructions */}
                <Alert severity="info" sx={{ textAlign: 'left' }}>
                  <Typography variant="body2" component="div">
                    <strong>What happens next?</strong>
                    <br />
                    Your organization administrator needs to set up your account with the appropriate role and permissions. 
                    Please contact your administrator or support team with the email address shown above.
                  </Typography>
                </Alert>

                {/* Action Buttons */}
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} justifyContent="center">
                  <Button
                    variant="contained"
                    startIcon={<SupportIcon />}
                    onClick={handleContactSupport}
                    size="large"
                  >
                    Contact Support
                  </Button>
                  <Button
                    variant="outlined"
                    startIcon={<LogoutIcon />}
                    onClick={handleLogout}
                    size="large"
                  >
                    Sign Out
                  </Button>
                </Stack>

                <Divider />

                {/* Additional Info */}
                <Box>
                  <Typography variant="body2" color="text.secondary" textAlign="center">
                    If you believe this is an error, please contact your system administrator.
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Stack>
      </Container>
    </Box>
  );
};

export default UserSetupRequired;