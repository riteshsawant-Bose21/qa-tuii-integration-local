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
  Info as InfoIcon,
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
  permissions: FeaturePermissionDetail[] | null;
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
  }, []);

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

  useEffect(() => {
    loadRoleManagementData();
  }, []); // Only run on mount - token is guaranteed to be available

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
          sx={{
            borderRadius: 2,
            textTransform: 'none',
            fontWeight: 600,
            px: 3,
            backgroundColor: '#000000',
            color: '#ffffff',
            boxShadow: '0 2px 8px rgba(0, 0, 0, 0.2)',
            '&:hover': {
              backgroundColor: '#333333',
              boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)',
            }
          }}
        >
          Create Role
        </Button>
      </Stack>

      <TableContainer 
        component={Card} 
        elevation={3}
        sx={{ 
          borderRadius: 3,
          overflow: 'hidden',
          border: '1px solid #e0e7ff',
          '& .MuiTable-root': {
            borderCollapse: 'separate',
          }
        }}
      >
        <Table>
          <TableHead>
            <TableRow sx={{ 
              background: 'linear-gradient(135deg, #000000 0%, #343a40 100%)',
              '& .MuiTableCell-head': {
                fontWeight: 700,
                fontSize: '0.875rem',
                color: 'white',
                borderBottom: 'none',
                py: 2.5,
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
              }
            }}>
              <TableCell>Role Name</TableCell>
              <TableCell>Users</TableCell>
              <TableCell>Permissions</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data?.roles.map((role) => (
              <TableRow 
                key={role.id}
                sx={{ 
                  '&:hover': {
                    backgroundColor: '#f8fafc',
                    transform: 'scale(1.001)',
                    transition: 'all 0.2s ease-in-out',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                  },
                  '&:nth-of-type(even)': {
                    backgroundColor: '#fafbfc',
                  },
                  '& .MuiTableCell-root': {
                    borderBottom: '1px solid #e2e8f0',
                    py: 3,
                  }
                }}
              >
                <TableCell>
                  <Box display="flex" alignItems="center" gap={1.5}>
                    <Typography variant="subtitle2" sx={{ 
                      fontWeight: 600, 
                      color: '#1e293b',
                      fontSize: '0.95rem'
                    }}>
                      {role.name}
                    </Typography>
                    {role.description && (
                      <Tooltip title={role.description} arrow placement="top">
                        <InfoIcon 
                          fontSize="small"
                          color='info'
                          sx={{ 
                            cursor: 'help',
                            '&:hover': { 
                              color: '#000000',
                              transform: 'scale(1.1)',
                              transition: 'all 0.2s ease-in-out'
                            }
                          }}
                        />
                      </Tooltip>
                    )}
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={`${role.user_count} users`} 
                    variant="filled"
                    size="small" 
                    color={role.user_count > 0 ? "primary" : "default"}
                    sx={{
                      borderRadius: 2,
                      fontWeight: 600,
                      fontSize: '0.75rem',
                      height: 26,
                      background: role.user_count > 0 
                        ? 'linear-gradient(45deg, #000000, #343a40)'
                        : '#e9ecef',
                      color: role.user_count > 0 ? 'white' : '#6c757d',
                    }}
                  />
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1} flexWrap="wrap" gap={0.5}>
                    {(role.permissions || []).slice(0, 3).map((perm) => (
                      <Chip 
                        key={perm.feature_id}
                        label={`${perm.feature_name}: ${perm.access_label}`}
                        variant="outlined"
                        size="small"
                        sx={{
                          borderRadius: 2,
                          fontSize: '0.7rem',
                          height: 24,
                          borderColor: '#dee2e6',
                          color: '#495057',
                          backgroundColor: '#f8f9fa',
                          '&:hover': {
                            borderColor: '#000000',
                            backgroundColor: '#e9ecef',
                          }
                        }}
                      />
                    ))}
                    {(role.permissions || []).length > 3 && (
                      <Chip 
                        label={`+${(role.permissions || []).length - 3} more`} 
                        variant="outlined" 
                        size="small"
                        sx={{
                          borderRadius: 2,
                          fontSize: '0.7rem',
                          height: 24,
                          borderColor: '#6c757d',
                          color: '#343a40',
                          backgroundColor: '#f1f3f4',
                        }}
                      />
                    )}
                  </Stack>
                </TableCell>
                <TableCell>
                  <Tooltip title="Edit Permissions" arrow>
                    <IconButton
                      size="small"
                      onClick={() => {
                        setSelectedRole(role);
                        setEditPermissionsDialog(true);
                      }}
                      sx={{
                        borderRadius: 2,
                        padding: 1,
                        backgroundColor: '#f8f9fa',
                        border: '1px solid #dee2e6',
                        color: '#495057',
                        '&:hover': {
                          backgroundColor: '#000000',
                          borderColor: '#000000',
                          color: 'white',
                          transform: 'scale(1.05)',
                          boxShadow: '0 2px 8px rgba(0, 0, 0, 0.3)',
                        },
                        transition: 'all 0.2s ease-in-out',
                      }}
                    >
                      <EditIcon fontSize="small" />
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
      <Typography variant="h6" mb={3} sx={{ color: '#1e293b', fontWeight: 600 }}>
        Organization Users
      </Typography>
      
      <TableContainer 
        component={Card} 
        elevation={3}
        sx={{ 
          borderRadius: 3,
          overflow: 'hidden',
          border: '1px solid #e0e7ff',
          '& .MuiTable-root': {
            borderCollapse: 'separate',
          }
        }}
      >
        <Table>
          <TableHead>
            <TableRow sx={{ 
              background: 'linear-gradient(135deg, #343a40 0%, #495057 100%)',
              '& .MuiTableCell-head': {
                fontWeight: 700,
                fontSize: '0.875rem',
                color: 'white',
                borderBottom: 'none',
                py: 2.5,
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
              }
            }}>
              <TableCell>User</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Current Role</TableCell>
              <TableCell>Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {data?.users.map((user) => (
              <TableRow 
                key={user.id}
                sx={{ 
                  '&:hover': {
                    backgroundColor: '#f8fafc',
                    transform: 'scale(1.001)',
                    transition: 'all 0.2s ease-in-out',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                  },
                  '&:nth-of-type(even)': {
                    backgroundColor: '#fafbfc',
                  },
                  '& .MuiTableCell-root': {
                    borderBottom: '1px solid #e2e8f0',
                    py: 3,
                  }
                }}
              >
                <TableCell>
                  <Box display="flex" alignItems="center" gap={1.5}>
                    <Box 
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: '50%',
                        background: 'linear-gradient(45deg, #343a40, #495057)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        fontWeight: 600,
                        fontSize: '0.875rem',
                        boxShadow: '0 2px 8px rgba(52, 58, 64, 0.3)',
                      }}
                    >
                      {user.full_name?.charAt(0).toUpperCase() || 'U'}
                    </Box>
                    <Typography variant="subtitle2" sx={{ 
                      fontWeight: 600, 
                      color: '#1e293b',
                      fontSize: '0.95rem'
                    }}>
                      {user.full_name}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" sx={{ 
                    color: '#64748b',
                    fontSize: '0.875rem',
                    fontWeight: 500,
                  }}>
                    {user.email}
                  </Typography>
                </TableCell>
                <TableCell>
                  <FormControl size="small" sx={{ minWidth: 150 }}>
                    <Select
                      value={user.role_id}
                      onChange={(e) => handleUpdateUserRole(user.id, e.target.value as number)}
                      sx={{
                        borderRadius: 2,
                        '& .MuiOutlinedInput-notchedOutline': {
                          borderColor: '#dee2e6',
                        },
                        '&:hover .MuiOutlinedInput-notchedOutline': {
                          borderColor: '#000000',
                        },
                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                          borderColor: '#000000',
                        },
                        '& .MuiSelect-select': {
                          fontWeight: 500,
                          color: '#495057',
                        }
                      }}
                    >
                      {data?.roles.map((role) => (
                        <MenuItem 
                          key={role.id} 
                          value={role.id}
                          sx={{
                            '&:hover': {
                              backgroundColor: '#f8f9fa',
                            },
                            '&.Mui-selected': {
                              backgroundColor: '#e9ecef',
                              '&:hover': {
                                backgroundColor: '#dee2e6',
                              }
                            }
                          }}
                        >
                          {role.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={user.role_name} 
                    variant="filled"
                    size="small"
                    sx={{
                      borderRadius: 2,
                      fontWeight: 600,
                      fontSize: '0.75rem',
                      height: 26,
                      background: 'linear-gradient(45deg, #495057, #6c757d)',
                      color: 'white',
                      boxShadow: '0 2px 4px rgba(73, 80, 87, 0.3)',
                    }}
                  />
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
                  const currentPerm = selectedRole?.permissions?.find(p => p.feature_id === feature.id);
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