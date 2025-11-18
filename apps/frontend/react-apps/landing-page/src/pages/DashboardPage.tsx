/**
 * Dashboard Page Component
 * Main dashboard for authenticated users
 */

import React from "react";
import {
  Container,
  Typography,
  Box,
  Card,
  CardContent,
  Grid,
  Avatar,
  Chip,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Divider,
} from "@mui/material";
import {
  Person as PersonIcon,
  Email as EmailIcon,
  Verified as VerifiedIcon,
  Schedule as ScheduleIcon,
} from "@mui/icons-material";
import { useAuth0 } from "@auth0/auth0-react";
import UserAuthorizationCard from "../components/auth/UserAuthorizationCard";
import TokenViewer from "../components/auth/TokenViewer";

const DashboardPage: React.FC = () => {
  const { user } = useAuth0();

  const userStats = [
    {
      label: "Account Status",
      value: user?.email_verified ? "Verified" : "Pending",
      color: user?.email_verified ? ("success" as const) : ("warning" as const),
      icon: <VerifiedIcon />,
    },
    {
      label: "Last Login",
      value: user?.updated_at ? new Date(user.updated_at).toLocaleDateString() : "Unknown",
      color: "info" as const,
      icon: <ScheduleIcon />,
    },
  ];

  const formatDate = (dateString: string | undefined) => {
    if (!dateString) return "Not available";
    return new Date(dateString).toLocaleString();
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Welcome Section */}
      <Box mb={4}>
        <Typography variant="h4" component="h1" gutterBottom>
          Dashboard
        </Typography>
        <Typography variant="h6" color="text.secondary">
          Welcome back, {user?.name || user?.email}!
        </Typography>
      </Box>

      <Grid container spacing={4}>
        {/* User Profile Card */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card elevation={2}>
            <CardContent sx={{ textAlign: "center", p: 3 }}>
              <Avatar
                src={user?.picture}
                alt={user?.name || "User"}
                sx={{
                  width: 100,
                  height: 100,
                  mx: "auto",
                  mb: 2,
                  border: "4px solid",
                  borderColor: "primary.main",
                }}
              >
                {!user?.picture && <PersonIcon sx={{ fontSize: 50 }} />}
              </Avatar>

              <Typography variant="h6" gutterBottom>
                {user?.name || "Anonymous User"}
              </Typography>

              <Typography variant="body2" color="text.secondary" gutterBottom>
                {user?.email}
              </Typography>

              <Box mt={2} display="flex" justifyContent="center" gap={1}>
                {userStats.map((stat, index) => (
                  <Chip
                    key={index}
                    label={stat.value}
                    color={stat.color}
                    size="small"
                    icon={stat.icon}
                  />
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Account Information */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card elevation={2}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Account Information
              </Typography>

              <List>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: "primary.main" }}>
                      <PersonIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText primary="Full Name" secondary={user?.name || "Not provided"} />
                </ListItem>

                <Divider variant="inset" component="li" />

                <ListItem>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: "secondary.main" }}>
                      <EmailIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText primary="Email Address" secondary={user?.email || "Not provided"} />
                </ListItem>

                <Divider variant="inset" component="li" />

                <ListItem>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: "info.main" }}>
                      <VerifiedIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Email Verified"
                    secondary={user?.email_verified ? "Yes" : "No"}
                  />
                </ListItem>

                <Divider variant="inset" component="li" />

                <ListItem>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: "warning.main" }}>
                      <ScheduleIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText primary="Last Updated" secondary={formatDate(user?.updated_at)} />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* User Authorization Section */}
        <Grid size={{ xs: 12 }}>
          <UserAuthorizationCard />
        </Grid>

        {/* Token Information (Debug) */}
        <Grid size={{ xs: 12 }}>
          <TokenViewer />
        </Grid>
      </Grid>
    </Container>
  );
};

export default DashboardPage;
