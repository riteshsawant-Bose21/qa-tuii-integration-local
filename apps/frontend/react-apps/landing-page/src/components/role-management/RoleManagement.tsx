/**
 * Role Management Component for Organization Admins
 * Allows admins to manage user roles and permissions within their organization
 */

import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  Select,
  MenuItem,
  Chip,
  Stack,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Security as SecurityIcon,
  People as PeopleIcon,
  Settings as SettingsIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';

interface RoleManagementData {
  roles: RoleWithPermissions[];
  features: Feature[];
  access_levels: AccessLevel[];
  users: UserBasicInfo[];
}

interface RoleWithPermissions {
  id: number;
  name: string;
  description: string;
  permissions: FeaturePermissionDetail[];
  user_count: number;
  created_at: string;
}

interface Feature {
  id: number;
  name: string;
  description: string;
}

interface AccessLevel {
  id: number;
  key: string;
  label: string;
}

interface UserBasicInfo {
  id: string;
  email: string;
  full_name: string;
  role_id: number;
  role_name: string;
}

interface FeaturePermissionDetail {
  feature_id: number;
  feature_name: string;
  access_level_id: number;
  access_level: string;
  access_label: string;
}

const RoleManagement: React.FC = () => {
  const { getIdTokenClaims } = useAuth0();
  const [data, setData] = useState<RoleManagementData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedTab, setSelectedTab] = useState(0);
  
  // Dialog states
  const [createRoleDialog, setCreateRoleDialog] = useState(false);
  const [editPermissionsDialog, setEditPermissionsDialog] = useState(false);
  const [selectedRole, setSelectedRole] = useState<RoleWithPermissions | null>(null);
  
  // Form states
  const [newRoleName, setNewRoleName] = useState('');
  const [newRoleDescription, setNewRoleDescription] = useState('');
  const [permissionChanges, setPermissionChanges] = useState<Record<number, number>>({});

  useEffect(() => {
    loadRoleManagementData();
  }, [getIdTokenClaims]);

  const loadRoleManagementData = async () => {
    try {
      setLoading(true);
      setError(null);

      const tokenClaims = await getIdTokenClaims();
      if (!tokenClaims) {
        setError('No authentication token available');
        return;
      }

      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
      const url = `${apiBaseUrl}/api/v1/organization/role-management`;
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${tokenClaims.__raw}`
        }
      });

      if (response.ok) {
        const roleData = await response.json();
        setData(roleData);
      } else {
        const errorText = await response.text();
        const errorMsg = `Failed to load role management data: ${response.status} ${errorText}`;
        setError(errorMsg);
      }
    } catch (err) {
      const errorMsg = `Error loading role management data: ${err instanceof Error ? err.message : 'Unknown error'}`;
      setError(errorMsg);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateRole = async () => {
    try {
      const idTokenClaims = await getIdTokenClaims();
      const idToken = idTokenClaims?.__raw;

      if (!idToken) {
        setError('No authentication token available');
        return;
      }

      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/v1/organization/roles`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: newRoleName,
          description: newRoleDescription
        })
      });

      if (response.ok) {
        setCreateRoleDialog(false);
        setNewRoleName('');
        setNewRoleDescription('');
        await loadRoleManagementData(); // Refresh data
      } else {
        const errorText = await response.text();
        setError(`Failed to create role: ${response.status} ${errorText}`);
      }
    } catch (err) {
      setError(`Error creating role: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  };

  const handleUpdateUserRole = async (userId: string, newRoleId: number) => {
    try {
      const idTokenClaims = await getIdTokenClaims();
      const idToken = idTokenClaims?.__raw;

      if (!idToken) {
        setError('No authentication token available');
        return;
      }

      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/v1/organization/users/${userId}/role`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          user_id: parseInt(userId),
          role_id: newRoleId
        })
      });

      if (response.ok) {
        await loadRoleManagementData(); // Refresh data
      } else {
        const errorText = await response.text();
        setError(`Failed to update user role: ${response.status} ${errorText}`);
      }
    } catch (err) {
      setError(`Error updating user role: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  };

  const handleUpdateRolePermissions = async () => {
    if (!selectedRole) return;

    try {
      const idTokenClaims = await getIdTokenClaims();
      const idToken = idTokenClaims?.__raw;

      if (!idToken) {
        setError('No authentication token available');
        return;
      }

      // Convert permission changes to API format
      const permissionUpdates = Object.entries(permissionChanges).map(([featureId, accessLevelId]) => ({
        feature_id: parseInt(featureId),
        access_level_id: accessLevelId,
        action: accessLevelId === 0 ? 'remove' : 'update'
      }));

      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/v1/organization/roles/${selectedRole.id}/permissions`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(permissionUpdates)
      });

      if (response.ok) {
        setEditPermissionsDialog(false);
        setPermissionChanges({});
        setSelectedRole(null);
        await loadRoleManagementData(); // Refresh data
      } else {
        const errorText = await response.text();
        setError(`Failed to update role permissions: ${response.status} ${errorText}`);
      }
    } catch (err) {
      setError(`Error updating role permissions: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  };

  const RolesTab = () => (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h6">Organization Roles</Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => setCreateRoleDialog(true)}
        >
          Create Role
        </Button>
      </Stack>

      <TableContainer component={Card}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Role Name</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Users</TableCell>
              <TableCell>Permissions</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data?.roles.map((role) => (
              <TableRow key={role.id}>
                <TableCell>
                  <Typography variant="subtitle2">{role.name}</Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {role.description}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip label={`${role.user_count} users`} variant="outlined" size="small" />
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1} flexWrap="wrap" gap={0.5}>
                    {role.permissions.slice(0, 3).map((perm) => (
                      <Chip 
                        key={perm.feature_id}
                        label={`${perm.feature_name}: ${perm.access_label}`}
                        variant="outlined"
                        size="small"
                      />
                    ))}
                    {role.permissions.length > 3 && (
                      <Chip label={`+${role.permissions.length - 3} more`} variant="outlined" size="small" />
                    )}
                  </Stack>
                </TableCell>
                <TableCell>
                  <Tooltip title="Edit Permissions">
                    <IconButton
                      size="small"
                      onClick={() => {
                        setSelectedRole(role);
                        setEditPermissionsDialog(true);
                      }}
                    >
                      <EditIcon />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );

  const UsersTab = () => (
    <Box>
      <Typography variant="h6" mb={3}>Organization Users</Typography>
      
      <TableContainer component={Card}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>User</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Current Role</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data?.users.map((user) => (
              <TableRow key={user.id}>
                <TableCell>
                  <Typography variant="subtitle2">{user.full_name}</Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {user.email}
                  </Typography>
                </TableCell>
                <TableCell>
                  <FormControl size="small" sx={{ minWidth: 150 }}>
                    <Select
                      value={user.role_id}
                      onChange={(e) => handleUpdateUserRole(user.id, e.target.value as number)}
                    >
                      {data?.roles.map((role) => (
                        <MenuItem key={role.id} value={role.id}>
                          {role.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </TableCell>
                <TableCell>
                  <Chip label={user.role_name} variant="outlined" size="small" />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" p={4}>
        <CircularProgress />
        <Typography variant="body2" ml={2}>Loading role management...</Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        <Typography variant="h6" gutterBottom>🚨 Role Management API Error</Typography>
        <Typography variant="body2" sx={{ mb: 2 }}>{error}</Typography>
        <Button 
          onClick={loadRoleManagementData} 
          variant="contained"
          color="primary"
        >
          Retry Loading
        </Button>
      </Alert>
    );
  }

  return (
    <Box>
      <Tabs value={selectedTab} onChange={(_, newValue) => setSelectedTab(newValue)} sx={{ mb: 3 }}>
        <Tab icon={<SettingsIcon />} label="Roles & Permissions" />
        <Tab icon={<PeopleIcon />} label="Users" />
      </Tabs>

      {selectedTab === 0 && (data ? <RolesTab /> : (
        <Card sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>Roles & Permissions</Typography>
          <Typography variant="body2" color="text.secondary">
            🔄 Loading roles data from API...
          </Typography>
          <Button 
            onClick={loadRoleManagementData} 
            variant="outlined" 
            sx={{ mt: 2, color: '#666666', borderColor: '#666666', '&:hover': { borderColor: '#666666', bgcolor: 'rgba(102,102,102,0.1)' } }}
          >
            Load Data
          </Button>
        </Card>
      ))}
      {selectedTab === 1 && (data ? <UsersTab /> : (
        <Card sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>Users</Typography>
          <Typography variant="body2" color="text.secondary">
            🔄 Loading users data from API...
          </Typography>
          <Button 
            onClick={loadRoleManagementData} 
            variant="outlined" 
            sx={{ mt: 2, color: '#666666', borderColor: '#666666', '&:hover': { borderColor: '#666666', bgcolor: 'rgba(102,102,102,0.1)' } }}
          >
            Load Data
          </Button>
        </Card>
      ))}

      {/* Create Role Dialog */}
      <Dialog open={createRoleDialog} onClose={() => setCreateRoleDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Role</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Role Name"
            value={newRoleName}
            onChange={(e) => setNewRoleName(e.target.value)}
            margin="normal"
            required
          />
          <TextField
            fullWidth
            label="Description"
            value={newRoleDescription}
            onChange={(e) => setNewRoleDescription(e.target.value)}
            margin="normal"
            multiline
            rows={3}
            required
          />
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setCreateRoleDialog(false)} 
            startIcon={<CancelIcon />}
            sx={{ color: '#666666' }}
          >
            Cancel
          </Button>
          <Button 
            onClick={handleCreateRole} 
            variant="contained" 
            color="primary"
            startIcon={<SaveIcon />}
            disabled={!newRoleName.trim() || !newRoleDescription.trim()}
          >
            Create Role
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit Permissions Dialog */}
      <Dialog 
        open={editPermissionsDialog} 
        onClose={() => setEditPermissionsDialog(false)} 
        maxWidth="md" 
        fullWidth
      >
        <DialogTitle>
          Edit Permissions: {selectedRole?.name}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Configure access levels for each feature
          </Typography>
          
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Feature</TableCell>
                  <TableCell>Current Access</TableCell>
                  <TableCell>New Access</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {data?.features.map((feature) => {
                  const currentPerm = selectedRole?.permissions.find(p => p.feature_id === feature.id);
                  const newAccessLevel = permissionChanges[feature.id] || currentPerm?.access_level_id || 0;
                  
                  return (
                    <TableRow key={feature.id}>
                      <TableCell>
                        <Typography variant="subtitle2">{feature.name}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {feature.description}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {currentPerm ? (
                          <Chip label={currentPerm.access_label} variant="outlined" size="small" />
                        ) : (
                          <Typography variant="body2" color="text.secondary">No access</Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <FormControl size="small" sx={{ minWidth: 120 }}>
                          <Select
                            value={newAccessLevel}
                            onChange={(e) => setPermissionChanges(prev => ({
                              ...prev,
                              [feature.id]: e.target.value as number
                            }))}
                          >
                            <MenuItem value={0}>No Access</MenuItem>
                            {data?.access_levels.map((level) => (
                              <MenuItem key={level.id} value={level.id}>
                                {level.label}
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setEditPermissionsDialog(false)} 
            startIcon={<CancelIcon />}
            sx={{ color: '#666666' }}
          >
            Cancel
          </Button>
          <Button 
            onClick={handleUpdateRolePermissions} 
            variant="contained" 
            color="primary"
            startIcon={<SaveIcon />}
            disabled={Object.keys(permissionChanges).length === 0}
          >
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RoleManagement;