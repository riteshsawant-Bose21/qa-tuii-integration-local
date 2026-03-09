# UI Gating System Implementation Guide

This document provides a comprehensive guide on implementing and using the scalable UI gating system for role and permission-based access control.

## Overview

The UI gating system provides a robust, scalable solution for managing user permissions and roles throughout the Flutter application. It's designed to handle current requirements (Reseller Admin and Bose Super Admin) while being easily extensible for future roles and permissions.

## Core Components

### 1. Permission System Architecture

```
core/permissions/
├── app_permissions.dart          # Permission and role constants
├── permission_service.dart       # Core permission logic
├── permission_widgets.dart       # UI widgets for gating
├── permission_extensions.dart    # Convenience extensions
├── auth_viewmodel_enhanced.dart  # Enhanced auth with permissions
├── permission_examples.dart      # Usage examples
└── permissions.dart             # Export file
```

### 2. Key Classes

#### `AppPermissions`
Defines all available permissions in the system:
```dart
class AppPermissions {
  static const String viewDashboard = 'view_dashboard';
  static const String manageUsers = 'manage_users';
  // ... more permissions
}
```

#### `AppRoles` 
Defines roles and their default permissions:
```dart
class AppRoles {
  static const String resellerAdmin = 'reseller_admin';
  static const String boseSuperAdmin = 'bose_super_admin';
  
  static Map<String, List<String>> get rolePermissions => {
    resellerAdmin: [AppPermissions.viewDashboard, ...],
    boseSuperAdmin: [...AppPermissions.allPermissions],
  };
}
```

#### `PermissionService`
Singleton service that manages permission checking:
```dart
// Initialize with auth data
PermissionService.instance.initialize(authResponse);

// Check permissions
if (PermissionService.instance.hasPermission('view_users')) {
  // Show users UI
}
```

## Implementation Steps

### Step 1: Initialize Permission System

After successful authentication, initialize the permission service:

```dart
// In your auth flow
Future<bool> loginWithAuthData(AuthorizationResponse authData) async {
  // Initialize permission service with auth data
  PermissionService.instance.initialize(authData);
  
  // Store auth data for your app
  _authorizationData = authData;
  _currentUser = authData.toUserEntity();
  _isLoggedIn = true;
  
  return true;
}
```

### Step 2: Add Permission Gating to UI

#### Basic Widget Gating
```dart
// Show widget only if user has permission
PermissionGate(
  permission: AppPermissions.viewUsers,
  child: UsersOverviewWidget(),
)

// Multiple permissions (any)
PermissionGate(
  permissions: [AppPermissions.createUsers, AppPermissions.editUsers],
  child: UserManagementButton(),
)

// Role-based gating
PermissionGate(
  role: AppRoles.resellerAdmin,
  child: ResellerSpecificWidget(),
)
```

#### Different Content by Role
```dart
RoleBasedWidget(
  roleWidgets: {
    AppRoles.resellerAdmin: ResellerDashboard(),
    AppRoles.boseSuperAdmin: SuperAdminDashboard(),
  },
  defaultWidget: StandardDashboard(),
)
```

#### Navigation Items
```dart
PermissionNavigationItem(
  permission: AppPermissions.viewUsers,
  child: ListTile(
    leading: Icon(Icons.people),
    title: Text('Users'),
    onTap: () => Navigator.pushNamed(context, '/users'),
  ),
)
```

### Step 3: Use Extensions for Convenience

#### Context Extensions
```dart
// In any widget
if (context.hasPermission(AppPermissions.viewUsers)) {
  // Show users content
}

if (context.isResellerAdmin) {
  // Show reseller admin features
}
```

#### Widget Extensions
```dart
// Conditional rendering
UsersWidget().showIfPermission(AppPermissions.viewUsers)

AdminPanel().showIfRole(AppRoles.boseSuperAdmin)

// Chain conditions
Button()
  .showIfPermission(AppPermissions.createUsers)
  .showIf(someOtherCondition)
```

#### Permission Mixin
```dart
class MyWidget extends StatelessWidget with PermissionMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (hasPermission(AppPermissions.viewUsers))
          Text('You can view users'),
        
        if (isResellerAdmin)
          AdminControls(),
      ],
    );
  }
}
```

### Step 4: Navigation with Permissions

```dart
class MyWidget extends StatelessWidget with PermissionMixin {
  void _navigateToUsers(BuildContext context) {
    navigateWithPermission(
      context,
      permission: AppPermissions.viewUsers,
      route: '/users',
      onAccessDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access denied')),
        );
      },
    );
  }
}
```

## Usage Examples

### Dashboard Page with UI Gating

```dart
class DashboardPage extends StatelessWidget with PermissionMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          // Settings only for admins
          PermissionGate(
            permission: AppPermissions.manageSettings,
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Role-specific welcome card
          RoleBasedWidget(
            roleWidgets: {
              AppRoles.resellerAdmin: ResellerWelcomeCard(),
              AppRoles.boseSuperAdmin: SuperAdminWelcomeCard(),
            },
            defaultWidget: DefaultWelcomeCard(),
          ),
          
          // Conditional widgets grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                // Users widget - only if can view users
                PermissionGate(
                  permission: AppPermissions.viewUsers,
                  child: DashboardCard(
                    title: 'Users',
                    icon: Icons.people,
                    onTap: () => _navigateToUsers(context),
                  ),
                ),
                
                // Projects widget - only if can view projects
                PermissionGate(
                  permission: AppPermissions.viewProjects,
                  child: DashboardCard(
                    title: 'Projects',
                    icon: Icons.work,
                    onTap: () => _navigateToProjects(context),
                  ),
                ),
                
                // System admin - only for super admin
                PermissionGate(
                  permission: AppPermissions.systemAdministration,
                  child: DashboardCard(
                    title: 'System Admin',
                    icon: Icons.admin_panel_settings,
                    onTap: () => Navigator.pushNamed(context, '/system-admin'),
                  ),
                ),
              ].where((widget) => widget != null).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Adding New Permissions/Roles

### Step 1: Add to Constants
```dart
// In app_permissions.dart
class AppPermissions {
  // Add new permission
  static const String newFeature = 'new_feature';
  
  // Update allPermissions list
  static List<String> get allPermissions => [
    // ... existing permissions
    newFeature,
  ];
}

// In AppRoles, add to role permissions
static Map<String, List<String>> get rolePermissions => {
  resellerAdmin: [
    // ... existing permissions
    AppPermissions.newFeature, // Add if reseller should have it
  ],
  // ... other roles
};
```

### Step 2: Use in UI
```dart
PermissionGate(
  permission: AppPermissions.newFeature,
  child: NewFeatureWidget(),
)
```

## Best Practices

### 1. Permission Naming
- Use clear, descriptive names: `viewUsers`, `createProjects`
- Follow pattern: `{action}_{resource}` 
- Group related permissions: `view_`, `create_`, `edit_`, `delete_`

### 2. Widget Structure
```dart
// ✅ Good: Clear permission requirements
PermissionGate(
  permission: AppPermissions.viewUsers,
  child: UsersWidget(),
)

// ✅ Good: Fallback content
PermissionGate(
  permission: AppPermissions.viewUsers,
  fallback: AccessDeniedWidget(),
  child: UsersWidget(),
)

// ❌ Avoid: Nested permission checks
PermissionGate(
  permission: AppPermissions.viewUsers,
  child: PermissionGate(
    permission: AppPermissions.editUsers,
    child: EditableUsersWidget(),
  ),
)

// ✅ Better: Combined permissions
PermissionGate(
  permissions: [AppPermissions.viewUsers, AppPermissions.editUsers],
  requireAll: true,
  child: EditableUsersWidget(),
)
```

### 3. Performance
- Permission service uses caching internally
- Extensions are lightweight and safe to use frequently
- `PermissionGate` widgets rebuild only when permissions change

### 4. Testing
```dart
// Mock permission service for testing
void main() {
  setUp(() {
    // Initialize with test auth data
    final testAuthResponse = AuthorizationResponse(
      // ... test data with specific permissions
    );
    PermissionService.instance.initialize(testAuthResponse);
  });
  
  testWidgets('should show users widget for admin', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Verify admin-only widgets are shown
    expect(find.byType(UsersWidget), findsOneWidget);
  });
}
```

## Current Role Configuration

### Reseller Admin Permissions
- Dashboard: view, manage
- Users: view, create, edit, manage roles
- Projects: view, create, edit, manage settings  
- Devices: view, manage, configure
- Settings: view, manage
- Reports: view, generate, export
- Audit: view logs
- Organization: manage

### Bose Super Admin Permissions
- All permissions (system-wide access)
- System administration
- Cross-organization management
- System settings management

## Migration from Current System

1. **Initialize in Auth Flow**: Add permission service initialization to your existing auth flow
2. **Gradual Adoption**: Start with high-level UI gating (dashboard, navigation)
3. **Replace Hard-coded Checks**: Convert existing role checks to use permission system
4. **Add Granular Controls**: Implement fine-grained permissions as needed

This system provides a solid foundation that will scale with your application's permission requirements while maintaining clean, readable code.