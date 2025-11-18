/**
 * Professional Dashboard with Side Navigation
 * Clean black and white design
 */

import React, { useState, useEffect } from 'react';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  IconButton,
  Container,
  Card,
  CardContent,
  Divider,
  Avatar,
  Stack,
  Chip,
  CircularProgress,
  Menu,
  MenuItem,
  Tooltip,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Person as PersonIcon,
  Security as SecurityIcon,
  Logout as LogoutIcon,
  Dashboard as DashboardIcon,
  AccountCircle as AccountCircleIcon,
  Settings as SettingsIcon,
  Help as HelpIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import TokenDebug from '../debug/TokenDebug';
import RoleManagement from '../role-management/RoleManagement';
import BoseProLogo from '../../assets/bose_pro_logo_lines_black.png';

const DRAWER_WIDTH = 300;

interface UserAuthData {
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
  permissions?: string[] | Record<string, string> | null;
}

const Dashboard: React.FC = () => {
  const { user, logout, getIdTokenClaims } = useAuth0();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [selectedTab, setSelectedTab] = useState('profile');
  const [userAuthData, setUserAuthData] = useState<UserAuthData | null>(null);
  const [isLoadingAuth, setIsLoadingAuth] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);
  const [profileMenuAnchor, setProfileMenuAnchor] = useState<null | HTMLElement>(null);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleLogout = () => {
    logout({ logoutParams: { returnTo: window.location.origin } });
  };

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setProfileMenuAnchor(event.currentTarget);
  };

  const handleProfileMenuClose = () => {
    setProfileMenuAnchor(null);
  };

  useEffect(() => {
    const fetchUserAuth = async () => {
      try {
        setIsLoadingAuth(true);
        setAuthError(null);
        
        // Use getIdTokenClaims to get the ID token (JWT) instead of access token (JWE)
        const idTokenClaims = await getIdTokenClaims();
        const idToken = idTokenClaims?.__raw;
        
        if (!idToken) {
          setAuthError('No ID token available');
          setIsLoadingAuth(false);
          return;
        }

        const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
        const response = await fetch(`${apiBaseUrl}/api/v1/user/me/authorization`, {
          headers: {
            'Authorization': `Bearer ${idToken}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          
          // Keep permissions as they are - backend sends map[string]string, frontend handles both array and object
          setUserAuthData(data);
          setAuthError(null);
        } else {
          setAuthError(`Failed to fetch user authorization: ${response.status} ${response.statusText}`);
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        setAuthError(`Failed to fetch user authorization: ${errorMessage}`);
      } finally {
        setIsLoadingAuth(false);
      }
    };

    fetchUserAuth();
  }, [getIdTokenClaims]);

  // Helper function to check if user has admin permissions
  const hasAdminPermissions = () => {
    if (!userAuthData) {
      return false;
    }

    // First, check if the user has an admin role name (like "Reseller Admin")
    if (userAuthData.role?.role_name) {
      const roleName = userAuthData.role.role_name;
      const adminRolePatterns = [
        'Admin', 'admin', 'ADMIN',
        'Reseller Admin', 'reseller admin', 'RESELLER ADMIN',
        'Organization Admin', 'organization admin', 'ORGANIZATION ADMIN',
        'Super Admin', 'super admin', 'SUPER ADMIN',
        'User Management', 'user management', 'USER MANAGEMENT',
      ];
      
      if (adminRolePatterns.some(pattern => roleName === pattern)) {
        return true;
      }
    }

    // Fallback: check permissions if available
    if (!userAuthData.permissions) {
      return false;
    }
    
    // Handle both array and object formats
    if (Array.isArray(userAuthData.permissions)) {
      const hasAdminAccess = userAuthData.permissions.some(permission => 
        permission.includes('user.manage') || 
        permission.includes('user_management') ||
        permission.includes('User Management')
      );
      return hasAdminAccess;
    }
    
    // Handle object format
    if (typeof userAuthData.permissions === 'object') {
      const permissions = userAuthData.permissions as Record<string, string>;
      const hasAdminAccess = Object.entries(permissions).some(([key, value]) => 
        (key.includes('user.manage') || 
         key.includes('user_management') || 
         key.includes('User Management') ||
         key.includes('launcher.user.manage')) &&
        (value === 'admin' || value === 'full' || value === 'write')
      );
      return hasAdminAccess;
    }
    
    return false;
  };

  const navigationItems = [
    { id: 'profile', label: 'Profile', icon: <PersonIcon /> },
    { id: 'role-management', label: 'Role Management', icon: <SecurityIcon /> },
  ];

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Toolbar sx={{ flexDirection: 'column', alignItems: 'center', py: 2 }}>
        <Box
          component="img"
          src={BoseProLogo}
          alt="Bose Professional"
          sx={{
            height: 40,
            width: 'auto',
            mb: 1,
          }}
        />

      </Toolbar>
      <Divider />
      <Box sx={{ flexGrow: 1 }}>
        <List>
          {navigationItems.map((item) => (
            <ListItem key={item.id} disablePadding>
              <ListItemButton
                selected={selectedTab === item.id}
                onClick={() => setSelectedTab(item.id)}
                sx={{
                  '&.Mui-selected': {
                    backgroundColor: '#f5f5f5',
                    color: '#000000',
                    '&:hover': {
                      backgroundColor: '#e0e0e0',
                    },
                    '& .MuiListItemIcon-root': {
                      color: '#000000',
                      minWidth: '32px', // Reduce gap between icon and text
                    },
                    '& .MuiListItemText-primary': {
                      color: '#000000',
                      fontWeight: 600,
                    },
                  },
                  '&:hover': {
                    backgroundColor: '#f9f9f9',
                  },
                  '& .MuiListItemIcon-root': {
                    minWidth: '32px', // Reduce gap between icon and text
                  },
                }}
              >
                <ListItemIcon>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </Box>
      <Divider />
      <Box>
        <List>
          <ListItem disablePadding>
            <ListItemButton 
              onClick={handleLogout}
              sx={{
                '& .MuiListItemIcon-root': {
                  minWidth: '32px', // Reduce gap between icon and text
                },
              }}
            >
              <ListItemIcon><LogoutIcon /></ListItemIcon>
              <ListItemText primary="Sign Out" />
            </ListItemButton>
          </ListItem>
        </List>
      </Box>
    </Box>
  );

  const ProfileTab = () => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Profile
      </Typography>
      
      <Card>
        <CardContent>
          <Stack spacing={2} alignItems="center" textAlign="center">
            <Avatar
              src={user?.picture}
              alt={user?.name}
              sx={{ width: 80, height: 80 }}
            />
            <Typography variant="h6">{user?.name}</Typography>
            <Typography variant="body2" color="text.secondary">
              {user?.email}
            </Typography>
          </Stack>
        </CardContent>
      </Card>

      {authError && (
        <Card>
          <CardContent>
            <Typography variant="h6" color="error" gutterBottom>
              Error Loading Account Information
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {authError}
            </Typography>
          </CardContent>
        </Card>
      )}

      {isLoadingAuth ? (
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center" gap={2}>
              <CircularProgress size={24} />
              <Typography variant="body2" color="text.secondary">
                Loading account information...
              </Typography>
            </Box>
          </CardContent>
        </Card>
      ) : userAuthData && (
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Account Information
            </Typography>
            <Stack spacing={1}>
              <Typography variant="body2">
                <strong>Account:</strong> {userAuthData.account.name}
              </Typography>
              <Typography variant="body2">
                <strong>Type:</strong> {userAuthData.account.type}
              </Typography>
              <Typography variant="body2">
                <strong>Description:</strong> {userAuthData.account.description}
              </Typography>
            </Stack>
          </CardContent>
        </Card>
      )}

      <TokenDebug />
    </Stack>
  );

  const RoleTab = () => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Role Management
      </Typography>
      
      {authError && (
        <Card>
          <CardContent>
            <Typography variant="h6" color="error" gutterBottom>
              Error Loading Role Information
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {authError}
            </Typography>
          </CardContent>
        </Card>
      )}
      
      {isLoadingAuth ? (
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center" gap={2}>
              <CircularProgress size={24} />
              <Typography variant="body2" color="text.secondary">
                Loading role information...
              </Typography>
            </Box>
          </CardContent>
        </Card>
      ) : userAuthData && (
        <>
          {/* Current User Role Info */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Your Current Role
              </Typography>
              <Chip
                label={userAuthData.role.role_name}
                variant="outlined"
                size="medium"
              />
            </CardContent>
          </Card>

          {/* User Permissions */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Your Permissions
              </Typography>
              <Stack direction="row" spacing={1} flexWrap="wrap" gap={1}>
                {userAuthData.permissions ? (
                  Object.entries(userAuthData.permissions).map(([key, value], index) => (
                    <Chip
                      key={index}
                      label={`${key}: ${value}`}
                      variant="outlined"
                      size="small"
                      color="primary"
                      sx={{ mb: 1 }}
                    />
                  ))
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    No permissions found
                  </Typography>
                )}
              </Stack>
            </CardContent>
          </Card>

          {/* Admin Role Management Section - Only show if user has admin permissions */}
          {hasAdminPermissions() && (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <SecurityIcon />
                  Organization Management
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  As an administrator, you can manage roles and users in your organization.
                </Typography>
                <RoleManagement />
              </CardContent>
            </Card>
          )}
        </>
      )}
    </Stack>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { sm: `${DRAWER_WIDTH}px` },
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <DashboardIcon sx={{ mr: 2 }} />
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            Fusion Dashboard
          </Typography>
          
          {/* Profile Menu */}
          <Tooltip title="Account settings">
            <IconButton
              onClick={handleProfileMenuOpen}
              size="large"
              sx={{ ml: 2 }}
              color="inherit"
              aria-controls={profileMenuAnchor ? 'account-menu' : undefined}
              aria-haspopup="true"
              aria-expanded={profileMenuAnchor ? 'true' : undefined}
            >
              <AccountCircleIcon />
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={profileMenuAnchor}
            id="account-menu"
            open={Boolean(profileMenuAnchor)}
            onClose={handleProfileMenuClose}
            onClick={handleProfileMenuClose}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          >
            <MenuItem onClick={() => { setSelectedTab('profile'); handleProfileMenuClose(); }}>
              <PersonIcon sx={{ mr: 2 }} />
              Profile
            </MenuItem>
            {hasAdminPermissions() && (
              <MenuItem onClick={() => { setSelectedTab('role-management'); handleProfileMenuClose(); }}>
                <SecurityIcon sx={{ mr: 2 }} />
                Role Management
              </MenuItem>
            )}
            <Divider />
            <MenuItem onClick={handleLogout}>
              <LogoutIcon sx={{ mr: 2 }} />
              Sign Out
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Box
        component="nav"
        sx={{ width: { sm: DRAWER_WIDTH }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true,
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: DRAWER_WIDTH,
            },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: DRAWER_WIDTH,
            },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
        }}
      >
        <Toolbar />
        <Container maxWidth="lg">
          {selectedTab === 'profile' && <ProfileTab />}
          {selectedTab === 'role-management' && <RoleTab />}
        </Container>
      </Box>
    </Box>
  );
};

export default Dashboard;