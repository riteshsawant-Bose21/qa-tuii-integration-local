# Fusion Landing Page

A professional React application with Auth0 authentication, Material-UI components, and backend API integration.

## Features

- 🔐 **Auth0 Authentication**: Enterprise-grade authentication with social login support
- 🎨 **Material-UI Design**: Professional, responsive UI components with custom theming
- 🚀 **API Integration**: Authenticated API calls to backend services
- 📱 **Responsive Design**: Mobile-first approach with responsive layouts
- 🛡️ **Protected Routes**: Route-based authentication guards
- 🔄 **Real-time Status**: Live API connection status monitoring

## Tech Stack

- **React 19**: Latest React version with modern features
- **TypeScript**: Full type safety and IntelliSense support
- **Material-UI v7**: Professional component library
- **Auth0 React SDK**: Authentication and user management
- **React Router DOM**: Client-side routing
- **Vite**: Fast development server and build tool

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Auth0 account and application setup
- Backend API running on port 8080

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure environment variables:
   ```bash
   cp .env.example .env
   ```
   
   Update `.env` with your Auth0 credentials:
   ```
   VITE_AUTH0_DOMAIN=your-auth0-domain.auth0.com
   VITE_AUTH0_CLIENT_ID=your-auth0-client-id
   VITE_AUTH0_REDIRECT_URI=http://localhost:5173
   VITE_API_BASE_URL=http://localhost:8080
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:5173](http://localhost:5173) in your browser

## Project Structure

```
src/
├── components/
│   ├── auth/                 # Authentication components
│   │   ├── Auth0ProviderWithHistory.tsx
│   │   ├── ProtectedRoute.tsx
│   │   └── UserAuthorizationCard.tsx
│   ├── common/               # Shared components
│   │   └── ApiStatusIndicator.tsx
│   └── layout/               # Layout components
│       ├── LoadingSpinner.tsx
│       └── NavigationHeader.tsx
├── hooks/                    # Custom React hooks
│   └── useApi.ts            # API integration hooks
├── pages/                    # Application pages
│   ├── DashboardPage.tsx
│   ├── HomePage.tsx
│   └── ProfilePage.tsx
├── services/                 # API services
│   └── apiClient.ts         # Centralized API client
├── theme/                    # Material-UI theming
│   └── theme.ts
└── types/                    # TypeScript type definitions
    └── api.ts
```

## Authentication Flow

1. **Landing Page**: Public homepage with login option
2. **Auth0 Login**: Redirect to Auth0 hosted login page
3. **Authentication**: User authenticates with Auth0
4. **Token Management**: Auth0 SDK handles token storage and refresh
5. **Protected Access**: Access to dashboard and profile pages
6. **API Integration**: Authenticated API calls with token injection

## API Integration

The application integrates with backend services through a centralized API client:

### Features
- **Automatic Token Injection**: Auth0 tokens automatically added to requests
- **Error Handling**: Centralized error handling and user feedback
- **Loading States**: UI loading indicators during API calls
- **Real-time Status**: Connection status monitoring

### Endpoints
- `GET /api/v1/user/me/authorization` - User roles and permissions

### Usage Example
```typescript
import { useUserAuthorization } from '../hooks/useApi';

const MyComponent = () => {
  const { authorization, isLoading, error, refetch } = useUserAuthorization();
  
  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  
  return <UserRoles roles={authorization?.roles} />;
};
```

## Components

### UserAuthorizationCard
Displays user roles and permissions fetched from the backend API:
- Real-time data fetching
- Error handling with retry functionality
- Professional UI with Material-UI components
- Role and permission visualization

### ApiStatusIndicator
Shows live connection status to backend API:
- Real-time health checks
- Visual status indicators
- Manual refresh capability
- Tooltip information

### ProtectedRoute
Route wrapper that ensures authentication:
- Automatic Auth0 login redirect
- Loading state handling
- Clean authentication flow

## Environment Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `VITE_AUTH0_DOMAIN` | Auth0 tenant domain | `your-tenant.auth0.com` |
| `VITE_AUTH0_CLIENT_ID` | Auth0 application client ID | `abc123...` |
| `VITE_AUTH0_REDIRECT_URI` | Callback URL after login | `http://localhost:5173` |
| `VITE_API_BASE_URL` | Backend API base URL | `http://localhost:8080` |

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript checks

### Code Quality

The project includes:
- ESLint for code linting
- Prettier for code formatting
- TypeScript for type safety
- Strict TypeScript configuration

## Troubleshooting

### Common Issues

1. **Auth0 Configuration Error**
   - Verify Auth0 domain and client ID
   - Check callback URLs in Auth0 dashboard
   - Ensure application type is "Single Page Application"

2. **API Connection Issues**
   - Verify backend API is running on port 8080
   - Check CORS configuration on backend
   - Verify API endpoints and authentication requirements

3. **Build Issues**
   - Clear node_modules and reinstall dependencies
   - Check for TypeScript errors
   - Verify all environment variables are set
