import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from '@mui/material/styles';
import theme from './theme';
import DashboardView from './pages/Dashboard';
import Login from './pages/Login';
import ProtectedRoute from './components/ProtectedRoute/ProtectedRoute';
import Devices from './pages/Devices';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import CustomerLayout from './layout/customer';
import Settings from './pages/Settings';
import Incidents from './pages/Incidents';
import Files from './pages/Files';
import Projects from './pages/Project/Projects';
import ProjectDetails from './pages/Project/ProjectDetails';

export default function App() {
  return (
    <AuthProvider>
      <ThemeProvider theme={theme}>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route element={
              <ProtectedRoute>
                <CustomerLayout />
              </ProtectedRoute>
            }>
              <Route
                path="/dashboard"
                element={
                  <DashboardView />
                }
              />
              <Route
                path="/incidents"
                element={
                  <Incidents />
                }
              />
              <Route
                path="/devices"
                element={
                  <Devices />
                }
              />
              <Route
                path="/files"
                element={
                  <Files />
                }
              />
              <Route
                path="/settings"
                element={
                  <Settings />
                }
              />
              <Route
                path='/projects'
                element={
                  <Projects />
                }
              />
              <Route
                path="/projects/:projectId"
                element={
                  <ProjectDetails />
                }
              />
              <Route
                path="/*"
                element={
                  <DashboardView />
                }
              />
            </Route>
          </Routes>
        </BrowserRouter>
      </ThemeProvider>
    </AuthProvider>
  );
}
