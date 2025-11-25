/**
 * User Authorization Component
 * Displays user roles and permissions fetched from backend
 */

import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Chip,
  Box,
  List,
  ListItem,
  ListItemText,
  Alert,
  CircularProgress,
  Button,
  Divider,
} from '@mui/material';
import {
  Security as SecurityIcon,
  Group as GroupIcon,
  VpnKey as VpnKeyIcon,
  Refresh as RefreshIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { useUserAuthorization } from '../../hooks/useApi';

const UserAuthorizationCard: React.FC = () => {
  const { authorization, isLoading, error, refetch } = useUserAuthorization();

  if (isLoading) {
    return (
      <Card elevation={2}>
        <CardContent sx={{ textAlign: 'center', p: 4 }}>
          <CircularProgress size={40} />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Loading authorization data...
          </Typography>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    // Check if it's a "User Not Found" error (404)
    if (error.includes('User Not Found') || error.includes('USER_NOT_FOUND') || error.includes('404')) {
      return (
        <Card elevation={2}>
          <CardContent>
            <Alert 
              severity="warning" 
              icon={<SecurityIcon />}
              action={
                <Button 
                  color="inherit" 
                  size="small" 
                  onClick={refetch}
                  startIcon={<RefreshIcon />}
                >
                  Check Again
                </Button>
              }
            >
              <Typography variant="body2" gutterBottom>
                <strong>Account Setup Required</strong>
              </Typography>
              <Typography variant="body2">
                Your account is not yet set up in the system. Please contact your administrator to create your user account and assign appropriate roles and permissions.
              </Typography>
            </Alert>
          </CardContent>
        </Card>
      );
    }

    // Handle other errors
    return (
      <Card elevation={2}>
        <CardContent>
          <Alert 
            severity="error" 
            icon={<ErrorIcon />}
            action={
              <Button 
                color="inherit" 
                size="small" 
                onClick={refetch}
                startIcon={<RefreshIcon />}
              >
                Retry
              </Button>
            }
          >
            <Typography variant="body2">
              Failed to load authorization data: {error}
            </Typography>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  if (!authorization) {
    return (
      <Card elevation={2}>
        <CardContent>
          <Alert severity="warning">
            <Typography variant="body2">
              No authorization data available. 
              <Button size="small" onClick={refetch} sx={{ ml: 1 }}>
                Try loading
              </Button>
            </Typography>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card elevation={2}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Typography variant="h6" component="h3" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <SecurityIcon color="primary" />
            Authorization Details
          </Typography>
          <Button
            size="small"
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={refetch}
            sx={{ minWidth: 'auto' }}
          >
            Refresh
          </Button>
        </Box>

        {/* User Info */}
        <Box mb={3}>
          <Typography variant="subtitle2" color="text.secondary" gutterBottom>
            User Information
          </Typography>
          <List dense>
            <ListItem disablePadding>
              <ListItemText
                primary="User ID"
                secondary={authorization.user.id}
                primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
                secondaryTypographyProps={{ 
                  variant: 'caption', 
                  sx: { fontFamily: 'monospace', wordBreak: 'break-all' } 
                }}
              />
            </ListItem>
            <ListItem disablePadding>
              <ListItemText
                primary="Email"
                secondary={authorization.user.email}
                primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
              />
            </ListItem>
          </List>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* Role Section */}
        <Box mb={3}>
          <Typography 
            variant="subtitle2" 
            color="text.secondary" 
            gutterBottom
            sx={{ display: 'flex', alignItems: 'center', gap: 1 }}
          >
            <GroupIcon fontSize="small" />
            Role
          </Typography>
          
          {authorization.role ? (
            <Box display="flex" flexWrap="wrap" gap={1} mt={1}>
              <Chip
                label={authorization.role.role_name}
                size="small"
                color="primary"
                variant="outlined"
                icon={<GroupIcon />}
              />
            </Box>
          ) : (
            <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
              No role assigned
            </Typography>
          )}
        </Box>

        {/* Account Section */}
        <Box mb={3}>
          <Typography 
            variant="subtitle2" 
            color="text.secondary" 
            gutterBottom
          >
            Account Information
          </Typography>
          <List dense>
            <ListItem disablePadding>
              <ListItemText
                primary="Account Name"
                secondary={authorization.account.name}
                primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
              />
            </ListItem>
            <ListItem disablePadding>
              <ListItemText
                primary="Account Type"
                secondary={authorization.account.type}
                primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
              />
            </ListItem>
            {authorization.account.description && (
              <ListItem disablePadding>
                <ListItemText
                  primary="Description"
                  secondary={authorization.account.description}
                  primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
                />
              </ListItem>
            )}
          </List>
        </Box>

        {/* Permissions Section */}
        <Box>
          <Typography 
            variant="subtitle2" 
            color="text.secondary" 
            gutterBottom
            sx={{ display: 'flex', alignItems: 'center', gap: 1 }}
          >
            <VpnKeyIcon fontSize="small" />
            Permissions
          </Typography>
          
          {authorization.permissions && Object.keys(authorization.permissions).length > 0 ? (
            <Box display="flex" flexWrap="wrap" gap={1} mt={1}>
              {Object.entries(authorization.permissions).map(([key, value]) => (
                <Chip
                  key={key}
                  label={`${key}: ${value}`}
                  size="small"
                  color="secondary"
                  variant="outlined"
                  icon={<VpnKeyIcon />}
                />
              ))}
            </Box>
          ) : (
            <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
              No specific permissions assigned
            </Typography>
          )}
        </Box>


      </CardContent>
    </Card>
  );
};

export default React.memo(UserAuthorizationCard);