package types

import (
	"encoding/json"
	"time"
)

type UserProfile struct {
	ID                    string          `json:"id"`
	UserID                string          `json:"user_id"`
	Email                 string          `json:"email"`
	FirstName             string          `json:"first_name"`
	LastName              string          `json:"last_name"`
	JobTitle              string          `json:"job_title"`
	Phone                 string          `json:"phone"`
	ProfilePhotoURL       string          `json:"profile_photo_url"`
	AddressLine1          string          `json:"address_line_1"`
	City                  string          `json:"city"`
	StateProvince         string          `json:"state_province"`
	Country               string          `json:"country"`
	ZipPostalCode         string          `json:"zip_postal_code"`
	GDPROptOut            bool            `json:"gdpr_opt_out"`
	PrivacyPolicyAccepted bool            `json:"privacy_policy_accepted"`
	LinkedProfiles        json.RawMessage `json:"linked_profiles" swaggertype:"object"`
	Timezone              string          `json:"timezone"`
	UnitSystem            string          `json:"unit_system"`
	CustomerType          string          `json:"customer_type"`
	ClientType            string          `json:"client_type"`
	CompanyName           string          `json:"company_name"`
	CompanyWebsite        string          `json:"company_website"`
	Currency              string          `json:"currency"`
	NetsuiteCustomerID    string          `json:"netsuite_customer_id"`
	PriceList             json.RawMessage `json:"price_list" swaggertype:"object"`
	CreatedAt             time.Time       `json:"created_at"`
	UpdatedAt             *time.Time      `json:"updated_at"`
}

type UserProfileUpdateRequest struct {
	Email                 *string          `json:"email"`
	FirstName             *string          `json:"first_name"`
	LastName              *string          `json:"last_name"`
	JobTitle              *string          `json:"job_title"`
	Phone                 *string          `json:"phone"`
	ProfilePhotoURL       *string          `json:"profile_photo_url"`
	AddressLine1          *string          `json:"address_line_1"`
	City                  *string          `json:"city"`
	StateProvince         *string          `json:"state_province"`
	Country               *string          `json:"country"`
	ZipPostalCode         *string          `json:"zip_postal_code"`
	GDPROptOut            *bool            `json:"gdpr_opt_out"`
	PrivacyPolicyAccepted *bool            `json:"privacy_policy_accepted"`
	LinkedProfiles        *json.RawMessage `json:"linked_profiles" swaggertype:"object"`
	Timezone              *string          `json:"timezone"`
	UnitSystem            *string          `json:"unit_system"`
	CustomerType          *string          `json:"customer_type"`
	ClientType            *string          `json:"client_type"`
	CompanyName           *string          `json:"company_name"`
	CompanyWebsite        *string          `json:"company_website"`
	Currency              *string          `json:"currency"`
	NetsuiteCustomerID    *string          `json:"netsuite_customer_id"`
	PriceList             *json.RawMessage `json:"price_list" swaggertype:"object"`
}

// UserProfile constants for default values.
const (
	DefaultAppThemeDark             = "D"
	DefaultAppThemeLight            = "L"
	DefaultAppStartupBehaviourLast  = "L"
	DefaultAppStartupBehaviourOther = "O"
)

type GetUserProfile_statusNotFound struct {
	Message string `json:"message" example:"User profile not found"`
}

type InternalServerError struct {
	Message string `json:"message" example:"Internal server error"`
}

type CreateUserProfile_statusOk struct {
	ID string `json:"id" example:"53437319-7a5b-4462-bc7c-9e7f9a057a1a"`
}

type CreateUserProfile_internalServerError struct {
	Message string `json:"message" example:"Failed to create user profile: "`
}

type UpdateUserProfile_statusOk struct {
	Message string `json:"message" example:"User profile updated successfully"`
}

type UpdateUserProfile_internalServerError struct {
	Message string `json:"message" example:"Failed to update user profile: "`
}
