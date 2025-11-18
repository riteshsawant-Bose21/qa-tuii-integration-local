/**
 * Profile Page Component
 * Detailed user profile information
 */

import React from 'react';
import {
  Container,
  Typography,
  Box,
  Card,
  CardContent,
  Avatar,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  Paper,
  Chip,
  Button,
} from '@mui/material';
import {
  Person as PersonIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import { useAuth0 } from '@auth0/auth0-react';
import { useNavigate } from 'react-router-dom';

const ProfilePage: React.FC = () => {
  const { user } = useAuth0();
  const navigate = useNavigate();

  const formatDate = (dateString: string | undefined) => {
    if (!dateString) return 'Not available';
    try {
      return new Date(dateString).toLocaleString();
    } catch {
      return 'Invalid date';
    }
  };

  const profileData = [
    { label: 'User ID', value: user?.sub || 'Not available' },
    { label: 'Name', value: user?.name || 'Not provided' },
    { label: 'Email', value: user?.email || 'Not provided' },
    { label: 'Nickname', value: user?.nickname || 'Not provided' },
    { label: 'Email Verified', value: user?.email_verified ? 'Yes' : 'No' },
    { label: 'Locale', value: user?.locale || 'Not provided' },
    { label: 'Created At', value: formatDate(user?.updated_at) },
    { label: 'Last Updated', value: formatDate(user?.updated_at) },
  ];

  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      {/* Header */}
      <Box mb={4} display="flex" justifyContent="space-between" alignItems="center">
        <div>
          <Typography variant="h4" component="h1" gutterBottom>
            Profile
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage your account information and preferences
          </Typography>
        </div>
        <Button
          variant="outlined"
          startIcon={<EditIcon />}
          onClick={() => {
            // In a real app, this would navigate to an edit profile page
            alert('Profile editing would be implemented here');
          }}
        >
          Edit Profile
        </Button>
      </Box>

      {/* Profile Card */}
      <Card elevation={2} sx={{ mb: 4 }}>
        <CardContent sx={{ p: 4 }}>
          {/* User Avatar and Basic Info */}
          <Box display="flex" alignItems="center" mb={3}>
            <Avatar
              src={user?.picture}
              alt={user?.name || 'User'}
              sx={{ 
                width: 120, 
                height: 120, 
                mr: 3,
                border: '4px solid',
                borderColor: 'primary.main',
              }}
            >
              {!user?.picture && <PersonIcon sx={{ fontSize: 60 }} />}
            </Avatar>
            
            <Box>
              <Typography variant="h5" gutterBottom>
                {user?.name || 'Anonymous User'}
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

          {/* Detailed Information */}
          <Typography variant="h6" gutterBottom>
            Account Details
          </Typography>
          
          <TableContainer component={Paper} variant="outlined" sx={{ mt: 2 }}>
            <Table>
              <TableBody>
                {profileData.map((item, index) => (
                  <TableRow key={index}>
                    <TableCell component="th" scope="row" sx={{ fontWeight: 600 }}>
                      {item.label}
                    </TableCell>
                    <TableCell>
                      {item.label === 'Email Verified' ? (
                        <Chip
                          label={item.value}
                          color={item.value === 'Yes' ? 'success' : 'warning'}
                          size="small"
                        />
                      ) : (
                        <Typography 
                          variant="body2"
                          sx={{ 
                            wordBreak: 'break-all',
                            fontFamily: item.label === 'User ID' ? 'monospace' : 'inherit',
                          }}
                        >
                          {item.value}
                        </Typography>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          {/* Raw User Data (for debugging) */}
          <Box mt={4}>
            <Typography variant="h6" gutterBottom>
              Raw User Data
            </Typography>
            <Paper 
              variant="outlined" 
              sx={{ 
                p: 2, 
                backgroundColor: 'grey.50',
                maxHeight: 300,
                overflow: 'auto',
              }}
            >
              <pre style={{ 
                margin: 0, 
                fontSize: '0.75rem',
                fontFamily: 'monospace',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-all',
              }}>
                {JSON.stringify(user, null, 2)}
              </pre>
            </Paper>
          </Box>

          {/* Actions */}
          <Box mt={4} display="flex" gap={2}>
            <Button
              variant="outlined"
              onClick={() => navigate('/dashboard')}
            >
              Back to Dashboard
            </Button>
          </Box>
        </CardContent>
      </Card>
    </Container>
  );
};

export default ProfilePage;