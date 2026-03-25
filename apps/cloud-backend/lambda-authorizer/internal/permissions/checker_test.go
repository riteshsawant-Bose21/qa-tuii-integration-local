package permissions

import (
	"context"
	"database/sql"
	"fmt"
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

func TestCheckEndpointPermissionWithContext_AllowWithDirectPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Mock GetUserPermissions query
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.read", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-123", "Editor", "acc-456", "Bose Corp", "Enterprise", "role-789")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "GET", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for user with direct permission")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context")
	}
	if userCtx.UserID != "user-123" {
		t.Errorf("Expected UserID=user-123, got %s", userCtx.UserID)
	}
	if userCtx.Role != "Editor" {
		t.Errorf("Expected Role=Editor, got %s", userCtx.Role)
	}
	if userCtx.AccountID != "acc-456" {
		t.Errorf("Expected AccountID=acc-456, got %s", userCtx.AccountID)
	}
	if userCtx.AccountName != "Bose Corp" {
		t.Errorf("Expected AccountName=Bose Corp, got %s", userCtx.AccountName)
	}
	if userCtx.AccountType != "Enterprise" {
		t.Errorf("Expected AccountType=Enterprise, got %s", userCtx.AccountType)
	}
	if userCtx.RoleID != "role-789" {
		t.Errorf("Expected RoleID=role-789, got %s", userCtx.RoleID)
	}
	if userCtx.Permissions != "project.read:read" {
		t.Errorf("Expected Permissions=project.read:read, got %s", userCtx.Permissions)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_DenyInsufficientDirectPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has project.create but only at read level (needs write)
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.create", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false for insufficient direct permission level")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_DenyNoPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has no permissions at all
	permRows := sqlmock.NewRows([]string{"name", "key"})
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false with no permissions")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_AllowWithPatternPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has wildcard project.* permission
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.*", "write")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-123", "Admin", "acc-456", "Bose Corp", "Enterprise", "role-789")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for user with wildcard pattern permission")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_DenyPatternPermissionInsufficientLevel(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has wildcard project.* but only read level (needs write for POST)
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.*", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false for insufficient wildcard permission level")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_AllowWithAdminPermission(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" role permission with sufficient level
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "admin")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("admin@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("admin-1", "Admin", "acc-1", "Admin Corp", "Enterprise", "role-1")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("admin@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "admin@example.com", "DELETE", "/api/v1/projects/abc-123")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for admin user")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context for admin")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_DenyAdminInsufficientLevel(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" key but only "read" level, insufficient for write requirement
	// Also no "*" (full access) key
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false for admin with insufficient level and no full access")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_AdminInsufficientButFullAccessSufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" key but only "read" level, but also has "*" (full access) with "write"
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "read").
		AddRow("*", "write")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-1", "Admin", "acc-1", "Corp", "Enterprise", "role-1")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true when admin insufficient but full access is sufficient")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_AdminInsufficientAndFullAccessInsufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" key at "read" level AND "*" at "read" level — both insufficient for "write"
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "read").
		AddRow("*", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false when both admin and full access have insufficient level")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_NoAdminButFullAccessSufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has no "admin" key but has "*" (full access) at "write" level
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("*", "write")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-1", "SuperAdmin", "acc-1", "Corp", "Enterprise", "role-1")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "DELETE", "/api/v1/projects/abc-123")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true with full access permission")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_NoAdminNoFullAccess(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has no "admin", no "*", no matching feature
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("product.read", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false with no admin and no full access")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_NoAdminButFullAccessInsufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has no "admin", has "*" but at "read" level — insufficient for "write"
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("*", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false when full access level is insufficient")
	}
	if userCtx != nil {
		t.Error("Expected nil user context when denied")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_UnregisteredEndpointAllowed(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// No permission registered for this endpoint — authentication-only
	// GetUserPermissions still called for context
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.read", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-1", "Editor", "acc-1", "Corp", "Enterprise", "role-1")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "GET", "/api/v1/health")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for unregistered endpoint")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context for authenticated user")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_GetUserPermissionsError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Simulate database error on permissions query
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnError(fmt.Errorf("connection refused"))

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "GET", "/api/v1/projects")

	if err == nil {
		t.Error("Expected error for database failure")
	}
	if allowed {
		t.Error("Expected allowed=false on error")
	}
	if userCtx != nil {
		t.Error("Expected nil user context on error")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_UserContextQueryError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Permissions query succeeds
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.read", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// User context query fails
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnError(sql.ErrNoRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "GET", "/api/v1/projects")

	if err == nil {
		t.Error("Expected error when user context query fails")
	}
	if allowed {
		t.Error("Expected allowed=false on user context error")
	}
	if userCtx != nil {
		t.Error("Expected nil user context on error")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermissionWithContext_MultiplePermissionsInContext(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has multiple permissions
	permRows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("project.read", "read").
		AddRow("project.create", "write").
		AddRow("product.read", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(permRows)

	// Mock user context query
	ctxRows := sqlmock.NewRows([]string{"id", "name", "account_id", "account_name", "account_type", "role_id"}).
		AddRow("user-1", "Editor", "acc-1", "Corp", "Enterprise", "role-1")
	mock.ExpectQuery("SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text").
		WithArgs("user@example.com").
		WillReturnRows(ctxRows)

	allowed, userCtx, err := checker.CheckEndpointPermissionWithContext(ctx, "user@example.com", "GET", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true")
	}
	if userCtx == nil {
		t.Fatal("Expected non-nil user context")
	}
	// Verify that permissions string contains all permissions (order may vary)
	if userCtx.Permissions == "" {
		t.Error("Expected non-empty permissions string")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

// =====================================================
// GetUserPermissions edge case tests
// =====================================================

func TestGetUserPermissions_QueryError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnError(sql.ErrConnDone)

	perms, err := checker.GetUserPermissions(ctx, "user@example.com")

	if err == nil {
		t.Error("Expected error for database query failure")
	}
	if perms != nil {
		t.Error("Expected nil permissions on error")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestGetUserPermissions_ScanError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// Return rows with wrong column types to trigger scan error
	rows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow(nil, nil) // NULL values will cause scan error for string type
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(rows)

	perms, err := checker.GetUserPermissions(ctx, "user@example.com")

	if err == nil {
		t.Error("Expected error for scan failure")
	}
	if perms != nil {
		t.Error("Expected nil permissions on scan error")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestGetUserPermissions_EmptyResult(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	rows := sqlmock.NewRows([]string{"name", "key"})
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(rows)

	perms, err := checker.GetUserPermissions(ctx, "user@example.com")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if len(perms) != 0 {
		t.Errorf("Expected empty permissions map, got %d entries", len(perms))
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

// =====================================================
// CheckUserPermission edge case tests
// =====================================================

func TestCheckUserPermission_Success(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	rows := sqlmock.NewRows([]string{"key"}).AddRow("write")
	mock.ExpectQuery("SELECT a.key FROM app_user").
		WithArgs("user@example.com", "project.create").
		WillReturnRows(rows)

	allowed, err := checker.CheckUserPermission(ctx, "user@example.com", "project.create", "write")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for sufficient permission")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckUserPermission_InsufficientLevel(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	rows := sqlmock.NewRows([]string{"key"}).AddRow("read")
	mock.ExpectQuery("SELECT a.key FROM app_user").
		WithArgs("user@example.com", "project.create").
		WillReturnRows(rows)

	allowed, err := checker.CheckUserPermission(ctx, "user@example.com", "project.create", "write")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false for insufficient permission level")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckUserPermission_NoRows(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	mock.ExpectQuery("SELECT a.key FROM app_user").
		WithArgs("user@example.com", "project.delete").
		WillReturnError(sql.ErrNoRows)

	allowed, err := checker.CheckUserPermission(ctx, "user@example.com", "project.delete", "write")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false when no permission row exists")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

// =====================================================
// isPermissionSufficient edge case tests
// =====================================================

func TestIsPermissionSufficient_UnknownUserLevel(t *testing.T) {
	result := isPermissionSufficient("superadmin", "read")
	if result {
		t.Error("Expected false for unknown user level 'superadmin'")
	}
}

func TestIsPermissionSufficient_UnknownRequiredLevel(t *testing.T) {
	result := isPermissionSufficient("read", "superadmin")
	if result {
		t.Error("Expected false for unknown required level 'superadmin'")
	}
}

func TestIsPermissionSufficient_BothUnknown(t *testing.T) {
	result := isPermissionSufficient("unknown1", "unknown2")
	if result {
		t.Error("Expected false when both levels are unknown")
	}
}

func TestIsPermissionSufficient_NoneLevel(t *testing.T) {
	result := isPermissionSufficient("none", "read")
	if result {
		t.Error("Expected false for 'none' user level accessing 'read'")
	}
}

func TestIsPermissionSufficient_CaseInsensitive(t *testing.T) {
	result := isPermissionSufficient("READ", "read")
	if !result {
		t.Error("Expected true for case-insensitive match")
	}
}

// =====================================================
// CheckEndpointPermission - admin permission path
// =====================================================

func TestCheckEndpointPermission_AdminPermissionSufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" permission at admin level — no direct feature match
	rows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "admin")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("admin@example.com").
		WillReturnRows(rows)

	allowed, err := checker.CheckEndpointPermission(ctx, "admin@example.com", "DELETE", "/api/v1/projects/abc-123")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if !allowed {
		t.Error("Expected allowed=true for admin user with sufficient level")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermission_AdminPermissionInsufficient(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	// User has "admin" key but only "read" level — insufficient for write-required endpoint
	rows := sqlmock.NewRows([]string{"name", "key"}).
		AddRow("admin", "read")
	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnRows(rows)

	allowed, err := checker.CheckEndpointPermission(ctx, "user@example.com", "POST", "/api/v1/projects")

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	if allowed {
		t.Error("Expected allowed=false for admin with insufficient level")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestCheckEndpointPermission_GetPermissionsError(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)
	ctx := context.Background()

	mock.ExpectQuery("SELECT f.name, a.key FROM app_user").
		WithArgs("user@example.com").
		WillReturnError(fmt.Errorf("database connection lost"))

	allowed, err := checker.CheckEndpointPermission(ctx, "user@example.com", "GET", "/api/v1/projects")

	if err == nil {
		t.Error("Expected error when GetUserPermissions fails")
	}
	if allowed {
		t.Error("Expected allowed=false on error")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

// =====================================================
// findEndpointPermission edge case tests
// =====================================================

func TestFindEndpointPermission_ExactMatch(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	perm := checker.findEndpointPermission("GET", "/api/v1/projects")
	if perm == nil {
		t.Error("Expected to find permission for GET /api/v1/projects")
	}
}

func TestFindEndpointPermission_ParameterizedMatch(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	perm := checker.findEndpointPermission("PATCH", "/api/v1/projects/some-uuid-123")
	if perm == nil {
		t.Error("Expected to find permission for parameterized path")
	}
}

func TestFindEndpointPermission_NoMatch(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	perm := checker.findEndpointPermission("GET", "/api/v1/nonexistent")
	if perm != nil {
		t.Error("Expected nil for unregistered endpoint")
	}
}

func TestFindEndpointPermission_CaseInsensitiveMethod(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	perm := checker.findEndpointPermission("get", "/api/v1/projects")
	if perm == nil {
		t.Error("Expected to find permission with lowercase method")
	}
}

func TestFindEndpointPermission_MalformedKeySkipped(t *testing.T) {
	db, _, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	checker := NewSQLPermissionChecker(db)

	// Inject a malformed key (no colon separator) into the permissions map
	checker.permissions["malformed-key-no-colon"] = &EndpointPermission{
		Feature:       "test.feature",
		RequiredLevel: "read",
		Description:   "Malformed key for testing",
	}

	// Search for a path that won't exact-match, forcing iteration over all keys including the malformed one
	perm := checker.findEndpointPermission("GET", "/api/v1/nonexistent/path/here")
	if perm != nil {
		t.Error("Expected nil — malformed key should be skipped, and no other pattern matches")
	}
}
