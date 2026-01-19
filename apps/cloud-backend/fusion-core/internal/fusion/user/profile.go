package user

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/ptr"
	"github.com/google/uuid"
)

// GetUserProfile fetches a user profile by user ID
func (s *Service) GetUserProfile(ctx context.Context, userID string) (*types.UserProfile, error) {
	return s.dbService.SelectUserProfileByUserID(ctx, userID)
}

// CreateUserProfile creates a new user profile
func (s *Service) CreateUserProfile(ctx context.Context, profileDetails *types.UserProfile) (string, error) {
	return s.dbService.InsertUserProfile(ctx, profileDetails)
}

// UpdateUserProfile updates an existing user profile
func (s *Service) UpdateUserProfile(ctx context.Context, profileDetails *types.UserProfileUpdateRequest, profileID string, userID string) error {
	if profileDetails == nil {
		return fmt.Errorf("userProfile cannot be nil")
	}

	existingProfile, err := s.dbService.SelectUserProfileByProfileIDAndUserID(ctx, profileID, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user profile not found")
		}
		return fmt.Errorf("failed to fetch user profile: %v", err)
	}

	// update only the fields which are present in the request payload and are not null
	ptr.AssignIfNotNull(&existingProfile.FirstName, profileDetails.FirstName)
	ptr.AssignIfNotNull(&existingProfile.LastName, profileDetails.LastName)
	ptr.AssignIfNotNull(&existingProfile.JobTitle, profileDetails.JobTitle)
	ptr.AssignIfNotNull(&existingProfile.Phone, profileDetails.Phone)
	ptr.AssignIfNotNull(&existingProfile.ProfilePhotoURL, profileDetails.ProfilePhotoURL)
	ptr.AssignIfNotNull(&existingProfile.AddressLine1, profileDetails.AddressLine1)
	ptr.AssignIfNotNull(&existingProfile.City, profileDetails.City)
	ptr.AssignIfNotNull(&existingProfile.StateProvince, profileDetails.StateProvince)
	ptr.AssignIfNotNull(&existingProfile.Country, profileDetails.Country)
	ptr.AssignIfNotNull(&existingProfile.ZipPostalCode, profileDetails.ZipPostalCode)
	ptr.AssignIfNotNull(&existingProfile.GDPROptOut, profileDetails.GDPROptOut)
	ptr.AssignIfNotNull(&existingProfile.PrivacyPolicyAccepted, profileDetails.PrivacyPolicyAccepted)
	ptr.AssignIfNotNull(&existingProfile.Timezone, profileDetails.Timezone)
	ptr.AssignIfNotNull(&existingProfile.UnitSystem, profileDetails.UnitSystem)
	ptr.AssignIfNotNull(&existingProfile.CustomerType, profileDetails.CustomerType)
	ptr.AssignIfNotNull(&existingProfile.ClientType, profileDetails.ClientType)
	ptr.AssignIfNotNull(&existingProfile.CompanyName, profileDetails.CompanyName)
	ptr.AssignIfNotNull(&existingProfile.CompanyWebsite, profileDetails.CompanyWebsite)
	ptr.AssignIfNotNull(&existingProfile.Currency, profileDetails.Currency)
	ptr.AssignIfNotNull(&existingProfile.NetsuiteCustomerID, profileDetails.NetsuiteCustomerID)

	if profileDetails.PriceList != nil {
		var js map[string]interface{}
		if err := json.Unmarshal(*profileDetails.PriceList, &js); err != nil {
			return fmt.Errorf("price_list must be a valid JSON object")
		}
		existingProfile.PriceList = *profileDetails.PriceList
	}

	if profileDetails.LinkedProfiles != nil {
		var js map[string]interface{}
		if err := json.Unmarshal(*profileDetails.LinkedProfiles, &js); err != nil {
			return fmt.Errorf("linked_profiles must be a valid JSON object")
		}
		existingProfile.LinkedProfiles = *profileDetails.LinkedProfiles
	}

	return s.dbService.UpdateUserProfile(ctx, existingProfile)
}

// CreateUserProfileForRegistration creates a profile during user registration process
func (s *Service) CreateUserProfileForRegistration(ctx context.Context, profileData *types.UserProfile) (string, error) {
	// Validate required fields for registration
	if profileData.UserID == "" {
		return "", fmt.Errorf("userID is required")
	}

	if _, err := uuid.Parse(profileData.UserID); err != nil {
		return "", fmt.Errorf("invalid user_id format: must be a valid UUID")
	}

	if profileData.Email == "" {
		return "", fmt.Errorf("email is required")
	}

	return s.dbService.InsertUserProfile(ctx, profileData)
}
