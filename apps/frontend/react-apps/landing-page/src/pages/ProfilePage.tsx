/**
 * Profile Page Component
 * Clean view/edit interface for user profile information
 */

import React, { useState } from 'react';
import {
  Container,
  Typography,
  Box,
  Card,
  CardContent,
  Avatar,
  Divider,
  TextField,
  Chip,
  Button,
} from '@mui/material';
import {
  Person as PersonIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import { useUserAuthorization } from '../hooks/useApi';

const ProfilePage: React.FC = () => {
  const { user } = useAuth0();
  const { authorization: userAuthData } = useUserAuthorization();
  const [isEditing, setIsEditing] = useState(false);
  const [editedName, setEditedName] = useState(user?.name || '');

  const handleEdit = () => {
    setEditedName(user?.name || '');
    setIsEditing(true);
  };

  const handleSave = () => {
    // Here you would typically make an API call to update the user profile
    // For now, we'll just show an alert
    alert('Profile update functionality would be implemented here');
    setIsEditing(false);
  };

  const handleCancel = () => {
    setEditedName(user?.name || '');
    setIsEditing(false);
  };

  return (
    <Container maxWidth="md" sx={{ py: 2 }}>
      {/* Header */}
      <Box mb={4} display="flex" justifyContent="space-between" alignItems="center">
        <div>
          <Typography variant="h4" component="h1" gutterBottom>
            Profile
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {isEditing ? 'Edit your account information' : 'Manage your account information and preferences'}
          </Typography>
        </div>
        <Box display="flex" gap={1}>
          {isEditing ? (
            <>
              <Button
                variant="contained"
                startIcon={<SaveIcon />}
                onClick={handleSave}
                color="primary"
              >
                Save
              </Button>
              <Button
                variant="outlined"
                startIcon={<CancelIcon />}
                onClick={handleCancel}
              >
                Cancel
              </Button>
            </>
          ) : (
            <Button
              variant="outlined"
              startIcon={<EditIcon />}
              onClick={handleEdit}
            >
              Edit Profile
            </Button>
          )}
        </Box>
      </Box>

      {/* Profile Card */}
      <Card elevation={2} sx={{ mb: 4 }}>
        <CardContent sx={{ p: 4 }}>
          {/* User Avatar and Basic Info */}
          <Box display="flex" alignItems="center" mb={4}>
            <Avatar
              src={user?.picture}
              alt={user?.name || 'User'}
              sx={{ 
                width: 120, 
                height: 120, 
                mr: 3,
              }}
            >
              {!user?.picture && <PersonIcon sx={{ fontSize: 60 }} />}
            </Avatar>
            
            <Box flex={1}>
              <Typography variant="h5" gutterBottom>
                {isEditing ? editedName || 'Anonymous User' : user?.name || 'Anonymous User'}
              </Typography>
              <Typography variant="body1" color="text.secondary" gutterBottom>
                {user?.email}
              </Typography>
              <Box display="flex" gap={1} mt={2}>
                <Chip
                  label={user?.email_verified ? 'Verified' : 'Unverified'}
                  color={user?.email_verified ? 'success' : 'warning'}
                  size="small"
                />
                {user?.locale && (
                  <Chip
                    label={user.locale.toUpperCase()}
                    color="info"
                    size="small"
                  />
                )}
              </Box>
            </Box>
          </Box>

          <Divider sx={{ my: 3 }} />

          {/* User Information */}
          <Typography variant="h6" gutterBottom>
            User Information
          </Typography>
          
          <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                sx={{ flex: 1, minWidth: 250 }}
                label="Full Name"
                value={isEditing ? editedName : user?.name || ''}
                onChange={(e) => setEditedName(e.target.value)}
                disabled={!isEditing}
                variant={isEditing ? "outlined" : "filled"}
                InputProps={{
                  readOnly: !isEditing,
                }}
                helperText={isEditing ? "You can edit your display name" : ""}
              />
              
              <TextField
                sx={{ flex: 1, minWidth: 250 }}
                label="Email"
                value={user?.email || ''}
                disabled
                variant="filled"
                InputProps={{
                  readOnly: true,
                }}
                helperText="Email cannot be changed"
              />
            </Box>
          </Box>

          <Divider sx={{ my: 3 }} />

          {/* Account Information */}
          <Typography variant="h6" gutterBottom>
            Account Information
          </Typography>
          
          <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                sx={{ flex: 1, minWidth: 200 }}
                label="Account Name"
                value={userAuthData?.account?.name || 'Loading...'}
                disabled
                variant="filled"
                InputProps={{
                  readOnly: true,
                }}
              />
              
              <TextField
                sx={{ flex: 1, minWidth: 200 }}
                label="Account Type"
                value={userAuthData?.account?.type || 'Loading...'}
                disabled
                variant="filled"
                InputProps={{
                  readOnly: true,
                }}
              />
            </Box>
            
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                sx={{ flex: 1, minWidth: 200 }}
                label="Role"
                value={userAuthData?.role?.role_name || 'Loading...'}
                disabled
                variant="filled"
                InputProps={{
                  readOnly: true,
                }}
              />
              
              <TextField
                sx={{ flex: 1, minWidth: 200 }}
                label="Account Description"
                value={userAuthData?.account?.description || 'Loading...'}
                disabled
                variant="filled"
                InputProps={{
                  readOnly: true,
                }}
              />
            </Box>
          </Box>

          {/* Additional profile actions could go here */}
        </CardContent>
      </Card>
    </Container>
  );
};

export default ProfilePage;