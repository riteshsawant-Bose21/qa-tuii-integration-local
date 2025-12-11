package userprofile

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
)

func (s *Service) GetUserProfile(ctx context.Context, userID string) (*types.UserProfile, error) {
	return s.dbService.SelectByUserID(ctx, userID)
}

func (s *Service) CreateUserProfile(ctx context.Context, profileDetails *types.UserProfile) (string, error) {
	return s.dbService.Insert(ctx, profileDetails)
}

func (s *Service) UpdateUserProfile(ctx context.Context, profileDetails *types.UserProfileUpdateRequest, profileID string, userID string) error {
	if profileDetails == nil {
		return fmt.Errorf("userProfile cannot be nil")
	}

	_, errLinkedProfiles := json.Marshal(profileDetails.LinkedProfiles)
	if errLinkedProfiles != nil {
		return fmt.Errorf("failed to marshal linked profiles: %v", errLinkedProfiles)
	}

	_, errPriceList := json.Marshal(profileDetails.PriceList)
	if errPriceList != nil {
		return fmt.Errorf("failed to marshal price list: %v", errPriceList)
	}

	existingProfile, err := s.dbService.SelectByUserID(ctx, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user profile not found")
		}
		return fmt.Errorf("failed to fetch user profile: %v", err)
	}

	if existingProfile.ID != profileID {
		return fmt.Errorf("user profile does not belong to the specified user")
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
		existingProfile.PriceList = *profileDetails.PriceList
	}

	return s.dbService.Update(ctx, existingProfile)
}

// CreateUserProfileForRegistration creates a profile during user registration process
// This is called internally, not from HTTP handlers
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

	return s.dbService.Insert(ctx, profileData)
}
