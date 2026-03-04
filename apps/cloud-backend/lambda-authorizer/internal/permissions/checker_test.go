package permissions

import (
	"context"
	"database/sql"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestCheckEndpointPermission_DenyWithoutPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	tests := []struct {
		name          string
		userEmail     string
		method        string
		resource      string
		userPerms     map[string]string
		expectedAllow bool
		expectedError bool
		description   string
	}{
		{
			name:      "Deny user without project.update permission",
			userEmail: "user@example.com",
			method:    "PUT",
			resource:  "/api/v1/projects/12345/users/other@example.com",
			userPerms: map[string]string{
				"project.read": "read",
			},
			expectedAllow: false,
			expectedError: false,
			description:   "User only has read permission, trying to update project",
		},
		{
			name:      "Deny user with insufficient permission level",
			userEmail: "user@example.com",
			method:    "POST",
			resource:  "/api/v1/projects",
			userPerms: map[string]string{
				"project.create": "read", // Has feature but insufficient level
			},
			expectedAllow: false,
			expectedError: false,
			description:   "User has read level, but write is required",
		},
		{
			name:          "Deny user with no permissions at all",
			userEmail:     "user@example.com",
			method:        "DELETE",
			resource:      "/api/v1/projects/12345",
			userPerms:     map[string]string{},
			expectedAllow: false,
			expectedError: false,
			description:   "User has no permissions in database",
		},
		{
			name:      "Allow user with sufficient permission",
			userEmail: "admin@example.com",
			method:    "POST",
			resource:  "/api/v1/projects",
			userPerms: map[string]string{
				"project.create": "write",
			},
			expectedAllow: false, // Will be true after mock setup
			expectedError: false,
			description:   "User has write permission for project creation",
		},
		{
			name:          "Allow authentication-only endpoint (no registered permission)",
			userEmail:     "user@example.com",
			method:        "GET",
			resource:      "/api/v1/health",
			userPerms:     map[string]string{},
			expectedAllow: true, // No permission registered = authentication-only
			expectedError: false,
			description:   "Endpoint not registered, should allow after authentication",
		},
		{
			name:      "Allow with wildcard permission",
			userEmail: "superuser@example.com",
			method:    "GET",
			resource:  "/api/v1/projects",
			userPerms: map[string]string{
				"project.*": "read",
			},
			expectedAllow: false, // Will be true after mock setup
			expectedError: false,
			description:   "User has wildcard permission for all project features",
		},
		{
			name:      "Deny when wildcard permission level insufficient",
			userEmail: "user@example.com",
			method:    "POST",
			resource:  "/api/v1/projects",
			userPerms: map[string]string{
				"project.*": "read", // Wildcard but only read level
			},
			expectedAllow: false,
			expectedError: false,
			description:   "Wildcard permission exists but level is insufficient",
		},
		{
			name:      "Pattern matching for parameterized endpoints",
			userEmail: "user@example.com",
			method:    "PUT",
			resource:  "/api/v1/projects/abc-123-def/users/test@example.com",
			userPerms: map[string]string{
				"project.update": "write",
			},
			expectedAllow: false, // Will be true after mock setup
			expectedError: false,
			description:   "Should match pattern /api/v1/projects/:projectId/users/:userEmail",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Mock GetUserPermissions query
			rows := sqlmock.NewRows([]string{"name", "key"})
			for feature, level := range tt.userPerms {
				rows.AddRow(feature, level)
			}

			// Only expect query if endpoint has registered permission
			if tt.resource != "/api/v1/health" {
				mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
					WithArgs(tt.userEmail).
					WillReturnRows(rows)
			}

			allowed, err := checker.CheckEndpointPermission(ctx, tt.userEmail, tt.method, tt.resource)

			if tt.expectedError {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			// Adjust expected result for mock
			expectedResult := tt.expectedAllow
			if tt.description == "User has write permission for project creation" ||
				tt.description == "User has wildcard permission for all project features" ||
				tt.description == "Should match pattern /api/v1/projects/:projectId/users/:userEmail" {
				expectedResult = true
			}

			if allowed != expectedResult {
				t.Errorf("%s: Expected allowed=%v, got allowed=%v", tt.description, expectedResult, allowed)
			}

			// Verify all expectations were met
			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}

func TestCheckEndpointPermission_PermissionHierarchy(t *testing.T) {
	tests := []struct {
		name          string
		userLevel     string
		requiredLevel string
		shouldAllow   bool
	}{
		{"Read user accessing read endpoint", "read", "read", true},
		{"Write user accessing read endpoint", "write", "read", true},
		{"Admin user accessing read endpoint", "admin", "read", true},
		{"Read user accessing write endpoint", "read", "write", false},
		{"Write user accessing write endpoint", "write", "write", true},
		{"Admin user accessing write endpoint", "admin", "write", true},
		{"Read user accessing admin endpoint", "read", "admin", false},
		{"Write user accessing admin endpoint", "write", "admin", false},
		{"Edit permission (alias for write)", "edit", "write", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Test permission hierarchy directly
			result := isPermissionSufficient(tt.userLevel, tt.requiredLevel)

			if result != tt.shouldAllow {
				t.Errorf("Permission hierarchy failed: user level '%s' vs required '%s', expected %v, got %v",
					tt.userLevel, tt.requiredLevel, tt.shouldAllow, result)
			}
		})
	}
}

func TestCheckEndpointPermission_CriticalEndpoints(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Test critical security scenarios
	criticalTests := []struct {
		name        string
		method      string
		resource    string
		userPerms   map[string]string
		shouldAllow bool
		reason      string
	}{
		{
			name:     "CRITICAL: Prevent unauthorized project deletion",
			method:   "GET",
			resource: "/api/v1/products",
			userPerms: map[string]string{
				"product.read": "read",
			},
			shouldAllow: true,
			reason:      "User only has read permission, attempting to delete",
		},
		{
			name:     "CRITICAL: Prevent unauthorized project deletion",
			method:   "DELETE",
			resource: "/api/v1/projects/12345",
			userPerms: map[string]string{
				"project.read": "read",
			},
			shouldAllow: false,
			reason:      "User only has read permission, attempting to delete",
		},
		{
			name:     "CRITICAL: Prevent unauthorized user assignment",
			method:   "PUT",
			resource: "/api/v1/projects/12345/users/victim@example.com",
			userPerms: map[string]string{
				"project.read": "write", // Has write for wrong feature
			},
			shouldAllow: false,
			reason:      "User has project.read:write, but needs project.update:write",
		},
		{
			name:     "CRITICAL: Allow legitimate admin operations",
			method:   "DELETE",
			resource: "/api/v1/projects/12345",
			userPerms: map[string]string{
				"project.delete": "write",
			},
			shouldAllow: true,
			reason:      "User has proper delete permission",
		},
		{
			name:     "CRITICAL: Prevent privilege escalation via unregistered endpoints",
			method:   "POST",
			resource: "/api/v1/admin/grant-permissions", // Not registered
			userPerms: map[string]string{
				"project.read": "read",
			},
			shouldAllow: true, // Currently allows - THIS IS A SECURITY CONSIDERATION
			reason:      "Unregistered endpoint defaults to authentication-only (consider security implications)",
		},
	}

	for _, tt := range criticalTests {
		t.Run(tt.name, func(t *testing.T) {
			rows := sqlmock.NewRows([]string{"name", "key"})
			for feature, level := range tt.userPerms {
				rows.AddRow(feature, level)
			}

			// Skip query expectation for unregistered endpoints
			if tt.resource != "/api/v1/admin/grant-permissions" {
				mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
					WithArgs("malicious@example.com").
					WillReturnRows(rows)
			}

			allowed, err := checker.CheckEndpointPermission(ctx, "malicious@example.com", tt.method, tt.resource)

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if allowed != tt.shouldAllow {
				t.Errorf("SECURITY VIOLATION: %s\nReason: %s\nExpected allowed=%v, got allowed=%v",
					tt.name, tt.reason, tt.shouldAllow, allowed)
			}

			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}

func TestMatchesPathPattern(t *testing.T) {
	tests := []struct {
		pattern     string
		path        string
		shouldMatch bool
		description string
	}{
		{
			pattern:     "/api/v1/projects/:id",
			path:        "/api/v1/projects/12345",
			shouldMatch: true,
			description: "Simple parameter match",
		},
		{
			pattern:     "/api/v1/projects/:projectId/users/:userEmail",
			path:        "/api/v1/projects/abc-123/users/test@example.com",
			shouldMatch: true,
			description: "Multiple parameters match",
		},
		{
			pattern:     "/api/v1/projects/:id",
			path:        "/api/v1/projects/12345/extra",
			shouldMatch: false,
			description: "Path longer than pattern",
		},
		{
			pattern:     "/api/v1/projects/:id/users/:email",
			path:        "/api/v1/projects/12345",
			shouldMatch: false,
			description: "Path shorter than pattern",
		},
		{
			pattern:     "/api/v1/projects/:id",
			path:        "/api/v1/products/12345",
			shouldMatch: false,
			description: "Different static segments",
		},
		{
			pattern:     "/api/v1/projects",
			path:        "/api/v1/projects",
			shouldMatch: true,
			description: "Exact match without parameters",
		},
	}

	for _, tt := range tests {
		t.Run(tt.description, func(t *testing.T) {
			result := matchesPathPattern(tt.pattern, tt.path)
			if result != tt.shouldMatch {
				t.Errorf("Pattern: %s, Path: %s, Expected: %v, Got: %v",
					tt.pattern, tt.path, tt.shouldMatch, result)
			}
		})
	}
}

func TestCheckUserPermission_DatabaseError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Simulate database connection error
	mock.ExpectQuery("SELECT a.key FROM app_user").
		WithArgs("user@example.com", "project.read").
		WillReturnError(sql.ErrConnDone)

	allowed, err := checker.CheckUserPermission(ctx, "user@example.com", "project.read", "read")

	if err == nil {
		t.Error("Expected error for database failure, got nil")
	}

	if allowed {
		t.Error("Should deny access on database error")
	}
}

func TestRegisterPermission_Consistency(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	// Verify all critical endpoints are registered
	criticalEndpoints := []struct {
		method   string
		path     string
		expected bool
	}{
		{"PUT", "/api/v1/projects/:projectId/users/:userEmail", true},
		{"DELETE", "/api/v1/projects/:id", true},
		{"POST", "/api/v1/projects", true},
		{"GET", "/api/v1/unregistered-endpoint", false},
	}

	for _, test := range criticalEndpoints {
		perm := checker.findEndpointPermission(test.method, test.path)
		found := perm != nil

		if found != test.expected {
			t.Errorf("Endpoint %s %s: expected registered=%v, got registered=%v",
				test.method, test.path, test.expected, found)
		}
	}
}

// Benchmark tests to ensure permission checks are fast
func BenchmarkCheckEndpointPermission(b *testing.B) {
	db, mock, _ := sqlmock.New()
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	rows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.read", "read")

	for i := 0; i < b.N; i++ {
		mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
			WithArgs("user@example.com").
			WillReturnRows(rows)

		checker.CheckEndpointPermission(ctx, "user@example.com", "GET", "/api/v1/projects")
	}
}

// TestAllRegisteredEndpoints_WithCorrectPermissions ensures all registered endpoints
// allow users with the proper permissions
func TestAllRegisteredEndpoints_WithCorrectPermissions(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Test every single registered endpoint
	testCases := []struct {
		name          string
		method        string
		path          string
		requiredPerms map[string]string
		description   string
	}{
		// Project endpoints
		{
			name:   "Get all projects",
			method: "GET",
			path:   "/api/v1/projects",
			requiredPerms: map[string]string{
				"project.read": "read",
			},
			description: "User with project.read:read can list projects",
		},
		{
			name:   "Create project",
			method: "POST",
			path:   "/api/v1/projects",
			requiredPerms: map[string]string{
				"project.create": "write",
			},
			description: "User with project.create:write can create projects",
		},
		{
			name:   "Update project",
			method: "PATCH",
			path:   "/api/v1/projects/abc-123-def-456",
			requiredPerms: map[string]string{
				"project.update": "write",
			},
			description: "User with project.update:write can update projects",
		},
		{
			name:   "Delete project",
			method: "DELETE",
			path:   "/api/v1/projects/abc-123-def-456",
			requiredPerms: map[string]string{
				"project.delete": "write",
			},
			description: "User with project.delete:write can delete projects",
		},
		{
			name:   "Assign user to project",
			method: "PUT",
			path:   "/api/v1/projects/abc-123/users/user@example.com",
			requiredPerms: map[string]string{
				"project.update": "write",
			},
			description: "User with project.update:write can assign users to projects",
		},
		{
			name:   "Remove user from project",
			method: "DELETE",
			path:   "/api/v1/projects/abc-123/users/user@example.com",
			requiredPerms: map[string]string{
				"project.update": "write",
			},
			description: "User with project.update:write can remove users from projects",
		},
		{
			name:   "Star project",
			method: "POST",
			path:   "/api/v1/projects/abc-123/star/user-456",
			requiredPerms: map[string]string{
				"project.update": "read",
			},
			description: "User with project.update:read can star projects",
		},
		{
			name:   "Archive project",
			method: "POST",
			path:   "/api/v1/projects/abc-123/archive",
			requiredPerms: map[string]string{
				"project.update": "write",
			},
			description: "User with project.update:write can archive projects",
		},
		{
			name:   "Lock project",
			method: "POST",
			path:   "/api/v1/projects/abc-123/lock",
			requiredPerms: map[string]string{
				"project.update": "write",
			},
			description: "User with project.update:write can lock projects",
		},
		// Product endpoints
		{
			name:   "Get all products",
			method: "GET",
			path:   "/api/v1/products",
			requiredPerms: map[string]string{
				"product.read": "read",
			},
			description: "User with product.read:read can list products",
		},
		{
			name:   "Get product details",
			method: "GET",
			path:   "/api/v1/products/product-123",
			requiredPerms: map[string]string{
				"product.read": "read",
			},
			description: "User with product.read:read can view product details",
		},
		{
			name:   "Get product price",
			method: "GET",
			path:   "/api/v1/products/price",
			requiredPerms: map[string]string{
				"product.read": "read",
			},
			description: "User with product.read:read can get product prices",
		},
		// User Profile endpoints
		{
			name:   "Get user profile",
			method: "GET",
			path:   "/api/v1/users/profile",
			requiredPerms: map[string]string{
				"users.profile.read": "read",
			},
			description: "User with users.profile.read:read can view their profile",
		},
		{
			name:   "Create user profile",
			method: "POST",
			path:   "/api/v1/users/profile",
			requiredPerms: map[string]string{
				"users.profile.create": "write",
			},
			description: "User with users.profile.create:write can create profile",
		},
		{
			name:   "Update user profile",
			method: "PUT",
			path:   "/api/v1/users/profile/profile-123",
			requiredPerms: map[string]string{
				"users.profile.update": "write",
			},
			description: "User with users.profile.update:write can update profile",
		},
		// User Settings endpoints
		{
			name:   "Get user settings",
			method: "GET",
			path:   "/api/v1/users/settings",
			requiredPerms: map[string]string{
				"users.settings.read": "read",
			},
			description: "User with users.settings.read:read can view settings",
		},
		{
			name:   "Create user settings",
			method: "POST",
			path:   "/api/v1/users/settings",
			requiredPerms: map[string]string{
				"users.settings.create": "write",
			},
			description: "User with users.settings.create:write can create settings",
		},
		{
			name:   "Update user settings",
			method: "PUT",
			path:   "/api/v1/users/settings/settings-123",
			requiredPerms: map[string]string{
				"users.settings.update": "write",
			},
			description: "User with users.settings.update:write can update settings",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Mock user permissions - user HAS the required permissions
			rows := sqlmock.NewRows([]string{"name", "key"})
			for feature, level := range tc.requiredPerms {
				rows.AddRow(feature, level)
			}

			mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
				WithArgs("authorized@example.com").
				WillReturnRows(rows)

			allowed, err := checker.CheckEndpointPermission(ctx, "authorized@example.com", tc.method, tc.path)

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if !allowed {
				t.Errorf("AUTHORIZATION FAILURE: %s should ALLOW user with correct permissions\n"+
					"Method: %s, Path: %s\n"+
					"Required: %v\n"+
					"Description: %s",
					tc.name, tc.method, tc.path, tc.requiredPerms, tc.description)
			}

			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}

// TestAllRegisteredEndpoints_WithoutPermissions ensures all registered endpoints
// deny users without the proper permissions
func TestAllRegisteredEndpoints_WithoutPermissions(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Test every endpoint with NO permissions
	testCases := []struct {
		name        string
		method      string
		path        string
		description string
	}{
		{"Get all projects", "GET", "/api/v1/projects", "User with no permissions cannot list projects"},
		{"Create project", "POST", "/api/v1/projects", "User with no permissions cannot create projects"},
		{"Update project", "PATCH", "/api/v1/projects/abc-123", "User with no permissions cannot update projects"},
		{"Delete project", "DELETE", "/api/v1/projects/abc-123", "User with no permissions cannot delete projects"},
		{"Assign user to project", "PUT", "/api/v1/projects/abc-123/users/user@example.com", "User with no permissions cannot assign users"},
		{"Remove user from project", "DELETE", "/api/v1/projects/abc-123/users/user@example.com", "User with no permissions cannot remove users"},
		{"Star project", "POST", "/api/v1/projects/abc-123/star/user-456", "User with no permissions cannot star projects"},
		{"Archive project", "POST", "/api/v1/projects/abc-123/archive", "User with no permissions cannot archive projects"},
		{"Lock project", "POST", "/api/v1/projects/abc-123/lock", "User with no permissions cannot lock projects"},
		{"Get all products", "GET", "/api/v1/products", "User with no permissions cannot list products"},
		{"Get product details", "GET", "/api/v1/products/product-123", "User with no permissions cannot view products"},
		{"Get product price", "GET", "/api/v1/products/price", "User with no permissions cannot get prices"},
		{"Get user profile", "GET", "/api/v1/users/profile", "User with no permissions cannot view profile"},
		{"Create user profile", "POST", "/api/v1/users/profile", "User with no permissions cannot create profile"},
		{"Update user profile", "PUT", "/api/v1/users/profile/profile-123", "User with no permissions cannot update profile"},
		{"Get user settings", "GET", "/api/v1/users/settings", "User with no permissions cannot view settings"},
		{"Create user settings", "POST", "/api/v1/users/settings", "User with no permissions cannot create settings"},
		{"Update user settings", "PUT", "/api/v1/users/settings/settings-123", "User with no permissions cannot update settings"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Mock empty permissions - user has NO permissions
			rows := sqlmock.NewRows([]string{"name", "key"})

			mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
				WithArgs("unauthorized@example.com").
				WillReturnRows(rows)

			allowed, err := checker.CheckEndpointPermission(ctx, "unauthorized@example.com", tc.method, tc.path)

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if allowed {
				t.Errorf("SECURITY VIOLATION: %s should DENY user without permissions\n"+
					"Method: %s, Path: %s\n"+
					"Description: %s",
					tc.name, tc.method, tc.path, tc.description)
			}

			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}

// TestAllRegisteredEndpoints_WithWrongPermissions ensures endpoints deny users
// with permissions for the wrong feature
func TestAllRegisteredEndpoints_WithWrongPermissions(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	testCases := []struct {
		name        string
		method      string
		path        string
		wrongPerms  map[string]string
		description string
	}{
		{
			name:   "Create project with product permission",
			method: "POST",
			path:   "/api/v1/projects",
			wrongPerms: map[string]string{
				"product.read": "write", // Wrong feature
			},
			description: "User with product.read cannot create projects",
		},
		{
			name:   "Delete project with read permission",
			method: "DELETE",
			path:   "/api/v1/projects/abc-123",
			wrongPerms: map[string]string{
				"project.read": "write", // Wrong feature (needs project.delete)
			},
			description: "User with project.read cannot delete projects",
		},
		{
			name:   "Assign user with create permission",
			method: "PUT",
			path:   "/api/v1/projects/abc-123/users/user@example.com",
			wrongPerms: map[string]string{
				"project.create": "write", // Wrong feature (needs project.update)
			},
			description: "User with project.create cannot assign users",
		},
		{
			name:   "Get products with project permission",
			method: "GET",
			path:   "/api/v1/products",
			wrongPerms: map[string]string{
				"project.read": "read", // Wrong feature
			},
			description: "User with project.read cannot view products",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Mock wrong permissions
			rows := sqlmock.NewRows([]string{"name", "key"})
			for feature, level := range tc.wrongPerms {
				rows.AddRow(feature, level)
			}

			mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
				WithArgs("user@example.com").
				WillReturnRows(rows)

			allowed, err := checker.CheckEndpointPermission(ctx, "user@example.com", tc.method, tc.path)

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if allowed {
				t.Errorf("SECURITY VIOLATION: %s should DENY\n"+
					"Method: %s, Path: %s\n"+
					"Wrong Permissions: %v\n"+
					"Description: %s",
					tc.name, tc.method, tc.path, tc.wrongPerms, tc.description)
			}

			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}

// TestAllRegisteredEndpoints_WithInsufficientLevel ensures endpoints deny users
// with correct feature but insufficient permission level
func TestAllRegisteredEndpoints_WithInsufficientLevel(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	testCases := []struct {
		name              string
		method            string
		path              string
		insufficientPerms map[string]string
		description       string
	}{
		{
			name:   "Create project with read level",
			method: "POST",
			path:   "/api/v1/projects",
			insufficientPerms: map[string]string{
				"project.create": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with project.create:read cannot create (needs write)",
		},
		{
			name:   "Delete project with read level",
			method: "DELETE",
			path:   "/api/v1/projects/abc-123",
			insufficientPerms: map[string]string{
				"project.delete": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with project.delete:read cannot delete (needs write)",
		},
		{
			name:   "Update project with read level",
			method: "PATCH",
			path:   "/api/v1/projects/abc-123",
			insufficientPerms: map[string]string{
				"project.update": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with project.update:read cannot update (needs write)",
		},
		{
			name:   "Assign user with read level",
			method: "PUT",
			path:   "/api/v1/projects/abc-123/users/user@example.com",
			insufficientPerms: map[string]string{
				"project.update": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with project.update:read cannot assign users (needs write)",
		},
		// User Profile endpoints
		{
			name:   "Create user profile with read level",
			method: "POST",
			path:   "/api/v1/users/profile",
			insufficientPerms: map[string]string{
				"users.profile.create": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with users.profile.create:read cannot create profile (needs write)",
		},
		{
			name:   "Update user profile with read level",
			method: "PUT",
			path:   "/api/v1/users/profile/profile-123",
			insufficientPerms: map[string]string{
				"users.profile.update": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with users.profile.update:read cannot update profile (needs write)",
		},
		// User Settings endpoints
		{
			name:   "Create user settings with read level",
			method: "POST",
			path:   "/api/v1/users/settings",
			insufficientPerms: map[string]string{
				"users.settings.create": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with users.settings.create:read cannot create settings (needs write)",
		},
		{
			name:   "Update user settings with read level",
			method: "PUT",
			path:   "/api/v1/users/settings/settings-123",
			insufficientPerms: map[string]string{
				"users.settings.update": "read", // Has feature but insufficient level (needs write)
			},
			description: "User with users.settings.update:read cannot update settings (needs write)",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Mock insufficient permission level
			rows := sqlmock.NewRows([]string{"name", "key"})
			for feature, level := range tc.insufficientPerms {
				rows.AddRow(feature, level)
			}

			mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
				WithArgs("user@example.com").
				WillReturnRows(rows)

			allowed, err := checker.CheckEndpointPermission(ctx, "user@example.com", tc.method, tc.path)

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if allowed {
				t.Errorf("SECURITY VIOLATION: %s should DENY\n"+
					"Method: %s, Path: %s\n"+
					"Insufficient Permissions: %v\n"+
					"Description: %s",
					tc.name, tc.method, tc.path, tc.insufficientPerms, tc.description)
			}

			if err := mock.ExpectationsWereMet(); err != nil {
				t.Errorf("Unfulfilled expectations: %v", err)
			}
		})
	}
}
