/**
 * Home Page Component
 * Landing page with Auth0 integration
 */

import React from "react";
import { Container, Typography, Button, Box } from "@mui/material";
import { useAuth0 } from "@auth0/auth0-react";
import { useNavigate } from "react-router-dom";

const HomePage: React.FC = () => {
  const { isAuthenticated, loginWithRedirect } = useAuth0();
  const navigate = useNavigate();

  const handleGetStarted = () => {
    if (isAuthenticated) {
      navigate("/dashboard");
    } else {
      loginWithRedirect();
    }
  };

  return (
    <Container maxWidth="lg">
      {/* Hero Section */}
      <Box display="flex" flexDirection="column" alignItems="center" textAlign="center" py={8}>
        <Typography
          variant="h2"
          component="h1"
          gutterBottom
          sx={{
            fontWeight: 300,
            mb: 3,
            background: "linear-gradient(45deg, #1976d2 30%, #42a5f5 90%)",
            backgroundClip: "text",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Welcome to Fusion Dashboard
        </Typography>

        <Button
          variant="contained"
          size="large"
          onClick={handleGetStarted}
          sx={{
            px: 4,
            py: 1.5,
            fontSize: "1.1rem",
          }}
        >
          {isAuthenticated ? "Go to Dashboard" : "Login with Auth0"}
        </Button>
      </Box>
    </Container>
  );
};

export default HomePage;
