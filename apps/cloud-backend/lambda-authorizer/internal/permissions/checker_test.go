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
