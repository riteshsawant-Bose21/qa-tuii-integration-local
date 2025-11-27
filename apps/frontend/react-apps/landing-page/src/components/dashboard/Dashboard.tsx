/**
 * Professional Dashboard with Side Navigation
 * Clean black and white design
 */

import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
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
  Stack,
  Menu,
  MenuItem,
  Tooltip,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Person as PersonIcon,
  Logout as LogoutIcon,
  Dashboard as DashboardIcon,
  FolderOpen as ProjectsIcon,
  Devices as DevicesIcon,
  People as UsersIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import RoleManagement from '../role-management/RoleManagement';
import ProfilePage from '../../pages/ProfilePage';
import BoseProLogo from '../../assets/bose_pro_logo_lines_black.png';

const DRAWER_WIDTH = 300;

const Dashboard: React.FC = () => {
  const { logout } = useAuth0();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [profileMenuAnchor, setProfileMenuAnchor] = useState<null | HTMLElement>(null);
  
  // Determine current path for navigation highlighting
  const getCurrentPath = () => {
    if (location.pathname === '/dashboard' || location.pathname === '/') return '/';
    if (location.pathname.startsWith('/dashboard/')) {
      return location.pathname.replace('/dashboard', '');
    }
    return location.pathname;
  };
  const currentPath = getCurrentPath();

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





  const navigationItems = [
    { id: '/', label: 'Dashboard', icon: <DashboardIcon />, path: '/dashboard' },
    { id: '/projects', label: 'Projects', icon: <ProjectsIcon />, path: '/dashboard/projects' },
    { id: '/devices', label: 'Devices', icon: <DevicesIcon />, path: '/dashboard/devices' },
    { id: '/users-roles', label: 'Users and Roles', icon: <UsersIcon />, path: '/dashboard/users-roles' },
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
                selected={currentPath === item.id}
                onClick={() => navigate(item.path)}
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

  const DashboardTab = () => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Dashboard
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Coming Soon
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Dashboard features are currently under development.
          </Typography>
        </CardContent>
      </Card>
    </Stack>
  );

  const ProjectsTab = () => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Projects
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Coming Soon
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Project management features are currently under development.
          </Typography>
        </CardContent>
      </Card>
    </Stack>
  );

  const DevicesTab = () => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Devices
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Coming Soon
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Device management features are currently under development.
          </Typography>
        </CardContent>
      </Card>
    </Stack>
  );

  const UsersRolesTab = React.memo(() => (
    <Stack spacing={3}>
      <Typography variant="h4" component="h2">
        Users and Roles
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            User and Role Management
          </Typography>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            Manage users and roles in your organization.
          </Typography>
          <RoleManagement />
        </CardContent>
      </Card>
    </Stack>
  ));
  UsersRolesTab.displayName = 'UsersRolesTab';

  const ProfileTab = () => <ProfilePage />;



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
          <Tooltip title="Profile">
            <IconButton
              onClick={handleProfileMenuOpen}
              size="large"
              sx={{ ml: 2 }}
              color="inherit"
              aria-controls={profileMenuAnchor ? 'profile-menu' : undefined}
              aria-haspopup="true"
              aria-expanded={profileMenuAnchor ? 'true' : undefined}
            >
              <PersonIcon />
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={profileMenuAnchor}
            id="profile-menu"
            open={Boolean(profileMenuAnchor)}
            onClose={handleProfileMenuClose}
            onClick={handleProfileMenuClose}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          >
            <MenuItem onClick={() => { navigate('/dashboard/profile'); handleProfileMenuClose(); }}>
              <PersonIcon sx={{ mr: 2 }} />
              Profile
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleLogout}>
              <LogoutIcon sx={{ mr: 2 }} />
              Logout
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
          <Routes>
            <Route index element={<DashboardTab />} />
            <Route path="projects" element={<ProjectsTab />} />
            <Route path="devices" element={<DevicesTab />} />
            <Route path="users-roles" element={<UsersRolesTab />} />
            <Route path="profile" element={<ProfileTab />} />
          </Routes>
        </Container>
      </Box>
    </Box>
  );
};

export default Dashboard;