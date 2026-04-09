// Package testutils provides shared test infrastructure for integration tests.
package testutils

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
)

// TestUser represents a test user with their role and account context.
type TestUser struct {
	ID          string `json:"id"`
	Email       string `json:"email"`
	AccountID   string `json:"account_id"`
	AccountName string `json:"account_name"`
	AccountType string `json:"account_type"`
	RoleID      int    `json:"role_id"`
	RoleName    string `json:"role_name"`
}

// TestProduct represents expected product data for testing.
type TestProduct struct {
	ProductID        int    `json:"productid"`
	ProductType      string `json:"product_type"`
	ModelName        string `json:"model_name"`
	ModelFamily      string `json:"model_family"`
	Description      string `json:"description"`
	ShortDesc        string `json:"short_description"`
	ExpectedPrice    float64
	ExpectedCurrency string
	ExpectedVariant  string
}

// TestProject represents a test project for testing.
type TestProject struct {
	ID                        string                `json:"project_id"`
	Name                      string                `json:"name"`
	Description               string                `json:"description"`
	Application               string                `json:"application"`
	Venue                     string                `json:"venue"`
	ProjectPhase              types.ProjectPhase    `json:"project_phase"`
	EnvironmentType           types.EnvironmentType `json:"environment_type"`
	Budget                    types.Budget          `json:"budget"`
	IsProjectFileCreated      bool                  `json:"is_project_file_created"`
	IsProjectThumbnailCreated bool                  `json:"is_project_thumbnail_created"`
}

// TestDevice represents a test device for testing.
type TestDevice struct {
	DeviceID        string `json:"device_id"`
	DeviceName      string `json:"device_name"`
	ModelName       string `json:"model_name"`
	FirmwareVersion string `json:"firmware_version"`
	SerialNumber    string `json:"serial_number"`
	MacAddress      string `json:"mac_address"`
	DeviceZone      string `json:"device_zone"`
	DeviceLocation  string `json:"device_location"`
	ProjectID       string `json:"project_id"`
	IsPrimary       bool   `json:"is_primary"`
}

// GetDefaultTestProducts returns the default test products from test_data.sql.
func GetDefaultTestProducts() []TestProduct {
	return []TestProduct{
		{
			ProductID:        1001,
			ProductType:      "speaker",
			ModelName:        "DM2SE",
			ModelFamily:      "DesignMax",
			Description:      "Surface-mount loudspeaker",
			ExpectedPrice:    299.99,
			ExpectedCurrency: "USD",
			ExpectedVariant:  "black",
		},
		{
			ProductID:        1002,
			ProductType:      "amplifier",
			ModelName:        "PWR4X100",
			ModelFamily:      "PowerSeries",
			Description:      "4-channel digital amplifier",
			ExpectedPrice:    1299.99,
			ExpectedCurrency: "USD",
			ExpectedVariant:  "standard",
		},
	}
}

// GetDefaultTestUsers returns the default test users from test_data.sql.
func GetDefaultTestUsers() []TestUser {
	return []TestUser{
		{ID: "60000001-0000-4000-8000-000000000001", Email: "admin@bose.com", AccountID: "50000001-0000-4000-8000-000000000001", AccountName: "Bose Corporation", AccountType: "Bose Pro", RoleID: 1, RoleName: "Super Admin"},
		{ID: "60000001-0000-4000-8000-000000000002", Email: "service@bose.com", AccountID: "50000001-0000-4000-8000-000000000001", AccountName: "Bose Corporation", AccountType: "Bose Pro", RoleID: 6, RoleName: "Service"},
		{ID: "60000001-0000-4000-8000-000000000003", Email: "mike.designer@audiotech.com", AccountID: "50000001-0000-4000-8000-000000000002", AccountName: "AudioTech Solutions", AccountType: "Reseller", RoleID: 3, RoleName: "Designer"},
		{ID: "60000001-0000-4000-8000-000000000004", Email: "lisa.tech@audiotech.com", AccountID: "50000001-0000-4000-8000-000000000002", AccountName: "AudioTech Solutions", AccountType: "Reseller", RoleID: 4, RoleName: "Technician"},
		{ID: "60000001-0000-4000-8000-000000000005", Email: "alex.designer@sounddynamics.com", AccountID: "50000001-0000-4000-8000-000000000003", AccountName: "Sound Dynamics LLC", AccountType: "Reseller", RoleID: 3, RoleName: "Designer"},
		{ID: "60000001-0000-4000-8000-000000000006", Email: "test@domain.com", AccountID: "50000001-0000-4000-8000-000000000004", AccountName: "Metro Conference Center", AccountType: "End User / System Owner", RoleID: 2, RoleName: "Admin"},
		{ID: "60000001-0000-4000-8000-000000000007", Email: "prof.operator@university.edu", AccountID: "50000001-0000-4000-8000-000000000005", AccountName: "University Audio Labs", AccountType: "End User / System Owner", RoleID: 7, RoleName: "Operator"},
		{ID: "60000001-0000-4000-8000-000000000008", Email: "emily.service@eventproductions.com", AccountID: "50000001-0000-4000-8000-000000000006", AccountName: "Event Productions Inc", AccountType: "End User / System Owner", RoleID: 6, RoleName: "Service"},
		{ID: "60000001-0000-4000-8000-000000000009", Email: "guest@metroconference.com", AccountID: "50000001-0000-4000-8000-000000000004", AccountName: "Metro Conference Center", AccountType: "End User / System Owner", RoleID: 8, RoleName: "Guest"},
		{ID: "60000001-0000-4000-8000-000000000010", Email: "fusion.reseller.sa@gmail.com", AccountID: "50000001-0000-4000-8000-000000000004", AccountName: "Metro Conference Center", AccountType: "End User / System Owner", RoleID: 2, RoleName: "Admin"},
	}
}

// CreateTestProject creates a new test project with the given name.
func CreateTestProject(name string) TestProject {
	return TestProject{
		ID:              uuid.New().String(),
		Name:            name,
		Description:     "Integration test project for " + name,
		Application:     "Corporate Conference Room",
		Venue:           "Integration Test Building",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   50000,
			Currency: "USD",
		},
		IsProjectFileCreated:      true,
		IsProjectThumbnailCreated: true,
	}
}

// CreateTestDevice creates a new test device with the given project ID.
func CreateTestDevice(projectID string) TestDevice {
	return TestDevice{
		DeviceID:        uuid.New().String(),
		DeviceName:      "Test Device",
		ModelName:       "Fusion-Mini",
		FirmwareVersion: "1.0.0",
		SerialNumber:    "SN" + uuid.New().String()[:8],
		MacAddress:      "00:11:22:33:44:55",
		DeviceZone:      "Zone A",
		DeviceLocation:  "Conference Room 1",
		ProjectID:       projectID,
		IsPrimary:       true,
	}
}

// DefaultAccountID returns the default test account ID.
func DefaultAccountID() string {
	return "50000001-0000-4000-8000-000000000001"
}

// DefaultAccountName returns the default test account name.
func DefaultAccountName() string {
	return "Bose Corporation"
}
