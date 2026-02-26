/**
 * Navigation Header Component
 * Professional header with Auth0 integration using MUI
 */

import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Avatar,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Box,
} from '@mui/material';
import {
  AccountCircle as AccountCircleIcon,
  Logout as LogoutIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import { useNavigate } from 'react-router-dom';

const NavigationHeader: React.FC = () => {
  const { user, isAuthenticated, loginWithRedirect, logout } = useAuth0();
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleProfileMenuClose = () => {
    setAnchorEl(null);
  };

  const handleProfileClick = () => {
    handleProfileMenuClose();
    navigate('/profile');
  };

  const handleLogout = () => {
    handleProfileMenuClose();
    logout({
      logoutParams: {
        returnTo: window.location.origin,
      },
    });
  };

  const handleLogin = () => {
    loginWithRedirect();
  };

  const isMenuOpen = Boolean(anchorEl);

  return (
    <AppBar position="static" color="primary" elevation={1}>
      <Toolbar>
        <Typography 
          variant="h6" 
          component="div" 
          sx={{ flexGrow: 1, cursor: 'pointer' }}
          onClick={() => navigate('/')}
        >
          Fusion Dashboard
        </Typography>

        {isAuthenticated ? (
          <Box display="flex" alignItems="center" gap={1}>
            <Typography variant="body2" color="inherit" sx={{ mr: 1 }}>
              Welcome, {user?.name || user?.email}
            </Typography>
            <Avatar
              src={user?.picture}
              alt={user?.name || 'User'}
              sx={{ 
                width: 40, 
                height: 40, 
                cursor: 'pointer',
                border: '2px solid rgba(255, 255, 255, 0.2)',
              }}
              onClick={handleProfileMenuOpen}
            >
              {!user?.picture && <AccountCircleIcon />}
            </Avatar>
          </Box>
        ) : (
          <Button 
            color="inherit" 
            variant="outlined"
            onClick={handleLogin}
            sx={{ 
              borderColor: 'rgba(255, 255, 255, 0.5)',
              '&:hover': {
                borderColor: 'white',
                backgroundColor: 'rgba(255, 255, 255, 0.1)',
              },
            }}
          >
            Sign In
          </Button>
        )}

        {/* Profile Menu */}
        <Menu
          anchorEl={anchorEl}
          open={isMenuOpen}
          onClose={handleProfileMenuClose}
          onClick={handleProfileMenuClose}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          PaperProps={{
            elevation: 3,
            sx: {
              mt: 1,
              minWidth: 200,
              '& .MuiAvatar-root': {
                width: 24,
                height: 24,
                ml: -0.5,
                mr: 1,
              },
            },
          }}
        >
          <MenuItem onClick={handleProfileClick}>
            <ListItemIcon>
              <PersonIcon fontSize="small" />
            </ListItemIcon>
            <ListItemText>Profile</ListItemText>
          </MenuItem>
          <Divider />
          <MenuItem onClick={handleLogout}>
            <ListItemIcon>
              <LogoutIcon fontSize="small" />
            </ListItemIcon>
            <ListItemText>Sign Out</ListItemText>
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  );
};

export default NavigationHeader;