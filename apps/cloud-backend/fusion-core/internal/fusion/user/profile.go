// Package user provides user management functionality including profiles and settings.
package user

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
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
	if profileDetails.FirstName != nil {
		existingProfile.FirstName = *profileDetails.FirstName
	}
	if profileDetails.LastName != nil {
		existingProfile.LastName = *profileDetails.LastName
	}
	if profileDetails.JobTitle != nil {
		existingProfile.JobTitle = *profileDetails.JobTitle
	}
	if profileDetails.Phone != nil {
		existingProfile.Phone = *profileDetails.Phone
	}
	if profileDetails.ProfilePhotoURL != nil {
		existingProfile.ProfilePhotoURL = *profileDetails.ProfilePhotoURL
	}
	if profileDetails.AddressLine1 != nil {
		existingProfile.AddressLine1 = *profileDetails.AddressLine1
	}
	if profileDetails.City != nil {
		existingProfile.City = *profileDetails.City
	}
	if profileDetails.StateProvince != nil {
		existingProfile.StateProvince = *profileDetails.StateProvince
	}
	if profileDetails.Country != nil {
		existingProfile.Country = *profileDetails.Country
	}
	if profileDetails.ZipPostalCode != nil {
		existingProfile.ZipPostalCode = *profileDetails.ZipPostalCode
	}
	if profileDetails.GDPROptOut != nil {
		existingProfile.GDPROptOut = *profileDetails.GDPROptOut
	}
	if profileDetails.PrivacyPolicyAccepted != nil {
		existingProfile.PrivacyPolicyAccepted = *profileDetails.PrivacyPolicyAccepted
	}
	if profileDetails.Timezone != nil {
		existingProfile.Timezone = *profileDetails.Timezone
	}
	if profileDetails.UnitSystem != nil {
		existingProfile.UnitSystem = *profileDetails.UnitSystem
	}
	if profileDetails.CustomerType != nil {
		existingProfile.CustomerType = *profileDetails.CustomerType
	}
	if profileDetails.ClientType != nil {
		existingProfile.ClientType = *profileDetails.ClientType
	}
	if profileDetails.CompanyName != nil {
		existingProfile.CompanyName = *profileDetails.CompanyName
	}
	if profileDetails.CompanyWebsite != nil {
		existingProfile.CompanyWebsite = *profileDetails.CompanyWebsite
	}
	if profileDetails.Currency != nil {
		existingProfile.Currency = *profileDetails.Currency
	}
	if profileDetails.NetsuiteCustomerID != nil {
		existingProfile.NetsuiteCustomerID = *profileDetails.NetsuiteCustomerID
	}

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
