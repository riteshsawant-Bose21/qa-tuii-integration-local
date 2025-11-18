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
                secondary={authorization.user_id}
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
                secondary={authorization.email}
                primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
              />
            </ListItem>
          </List>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* Roles Section */}
        <Box mb={3}>
          <Typography 
            variant="subtitle2" 
            color="text.secondary" 
            gutterBottom
            sx={{ display: 'flex', alignItems: 'center', gap: 1 }}
          >
            <GroupIcon fontSize="small" />
            Roles ({authorization.roles?.length || 0})
          </Typography>
          
          {authorization.roles && authorization.roles.length > 0 ? (
            <Box display="flex" flexWrap="wrap" gap={1} mt={1}>
              {authorization.roles.map((role, index) => (
                <Chip
                  key={index}
                  label={role}
                  size="small"
                  color="primary"
                  variant="outlined"
                  icon={<GroupIcon />}
                />
              ))}
            </Box>
          ) : (
            <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
              No roles assigned
            </Typography>
          )}
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
            Permissions ({authorization.permissions?.length || 0})
          </Typography>
          
          {authorization.permissions && authorization.permissions.length > 0 ? (
            <Box display="flex" flexWrap="wrap" gap={1} mt={1}>
              {authorization.permissions.map((permission, index) => (
                <Chip
                  key={index}
                  label={permission}
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

        {/* Metadata Section (if available) */}
        {authorization.metadata && Object.keys(authorization.metadata).length > 0 && (
          <Box mt={3}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
              Additional Metadata
            </Typography>
            <Box 
              component="pre" 
              sx={{ 
                fontSize: '0.75rem',
                fontFamily: 'monospace',
                backgroundColor: 'grey.50',
                p: 2,
                borderRadius: 1,
                overflow: 'auto',
                maxHeight: 200,
              }}
            >
              {JSON.stringify(authorization.metadata, null, 2)}
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default React.memo(UserAuthorizationCard);