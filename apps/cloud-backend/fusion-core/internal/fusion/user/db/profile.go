// Package db provides database access layer for user profile operations.
package db

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
)

// SelectUserProfileByUserID fetches user profile for a specific userID
func (s *Service) SelectUserProfileByUserID(ctx context.Context, userID string) (*types.UserProfile, error) {
	row, err := model.UserProfiles(model.UserProfileWhere.UserID.EQ(userID)).One(ctx, s.db)
	if err != nil {
		return nil, err
	}

	return newUserProfile(row)
}

// SelectUserProfileByProfileIDAndUserID retrieves a user profile by profile ID and user ID
func (s *Service) SelectUserProfileByProfileIDAndUserID(ctx context.Context, profileID string, userID string) (*types.UserProfile, error) {
	row, err := model.UserProfiles(model.UserProfileWhere.ID.EQ(profileID), model.UserProfileWhere.UserID.EQ(userID)).One(ctx, s.db)
	if err != nil {
		return nil, err
	}

	return newUserProfile(row)
}

func newUserProfile(row *model.UserProfile) (*types.UserProfile, error) {
	var linkedProfiles json.RawMessage
	if row.LinkedProfiles.Valid {
		linkedProfiles = json.RawMessage(row.LinkedProfiles.JSON)
	}

	var priceList json.RawMessage
	if row.PriceList.Valid {
		priceList = json.RawMessage(row.PriceList.JSON)
	}

	var updatedAt *time.Time
	if row.UpdatedAt.Valid {
		updatedAt = &row.UpdatedAt.Time
	}

	return &types.UserProfile{
		ID:                    row.ID,
		UserID:                row.UserID,
		Email:                 row.Email,
		FirstName:             row.FirstName.String,
		LastName:              row.LastName.String,
		JobTitle:              row.JobTitle.String,
		Phone:                 row.Phone.String,
		ProfilePhotoURL:       row.ProfilePhotoURL.String,
		AddressLine1:          row.AddressLine1.String,
		City:                  row.City.String,
		StateProvince:         row.StateProvince.String,
		Country:               row.Country.String,
		ZipPostalCode:         row.ZipPostalCode.String,
		GDPROptOut:            row.GDPROptOut.Bool,
		PrivacyPolicyAccepted: row.PrivacyPolicyAccepted.Bool,
		LinkedProfiles:        linkedProfiles,
		Timezone:              row.Timezone.String,
		UnitSystem:            row.UnitSystem.String,
		CustomerType:          row.CustomerType.String,
		ClientType:            row.ClientType.String,
		CompanyName:           row.CompanyName.String,
		CompanyWebsite:        row.CompanyWebsite.String,
		Currency:              row.Currency.String,
		NetsuiteCustomerID:    row.NetsuiteCustomerID.String,
		PriceList:             priceList,
		CreatedAt:             row.CreatedAt,
		UpdatedAt:             updatedAt,
	}, nil
}

// InsertUserProfile inserts a new user profile in the database
func (s *Service) InsertUserProfile(ctx context.Context, userProfile *types.UserProfile) (string, error) {
	// Validations
	if userProfile == nil {
		return "", fmt.Errorf("userProfile cannot be nil")
	}

	var linkedProfilesJSON []byte
	var errLinkedProfiles error
	if userProfile.LinkedProfiles != nil {
		linkedProfilesJSON, errLinkedProfiles = json.Marshal(userProfile.LinkedProfiles)
		if errLinkedProfiles != nil {
			return "", fmt.Errorf("failed to marshal linked profiles: %v", errLinkedProfiles)
		}
	}

	var priceListJSON []byte
	var errPriceList error
	if userProfile.PriceList != nil {
		priceListJSON, errPriceList = json.Marshal(userProfile.PriceList)
		if errPriceList != nil {
			return "", fmt.Errorf("failed to marshal price list: %v", errPriceList)
		}
	}

	// Create the user profile
	row := &model.UserProfile{
		UserID:                userProfile.UserID,
		Email:                 userProfile.Email,
		FirstName:             null.NewString(userProfile.FirstName, userProfile.FirstName != ""),
		LastName:              null.NewString(userProfile.LastName, userProfile.LastName != ""),
		JobTitle:              null.NewString(userProfile.JobTitle, userProfile.JobTitle != ""),
		Phone:                 null.NewString(userProfile.Phone, userProfile.Phone != ""),
		ProfilePhotoURL:       null.NewString(userProfile.ProfilePhotoURL, userProfile.ProfilePhotoURL != ""),
		AddressLine1:          null.NewString(userProfile.AddressLine1, userProfile.AddressLine1 != ""),
		City:                  null.NewString(userProfile.City, userProfile.City != ""),
		StateProvince:         null.NewString(userProfile.StateProvince, userProfile.StateProvince != ""),
		Country:               null.NewString(userProfile.Country, userProfile.Country != ""),
		ZipPostalCode:         null.NewString(userProfile.ZipPostalCode, userProfile.ZipPostalCode != ""),
		GDPROptOut:            null.NewBool(userProfile.GDPROptOut, true),
		PrivacyPolicyAccepted: null.NewBool(userProfile.PrivacyPolicyAccepted, true),
		LinkedProfiles:        null.JSONFrom(linkedProfilesJSON),
		Timezone:              null.NewString(userProfile.Timezone, userProfile.Timezone != ""),
		UnitSystem:            null.NewString(userProfile.UnitSystem, userProfile.UnitSystem != ""),
		CustomerType:          null.NewString(userProfile.CustomerType, userProfile.CustomerType != ""),
		ClientType:            null.NewString(userProfile.ClientType, userProfile.ClientType != ""),
		CompanyName:           null.NewString(userProfile.CompanyName, userProfile.CompanyName != ""),
		CompanyWebsite:        null.NewString(userProfile.CompanyWebsite, userProfile.CompanyWebsite != ""),
		Currency:              null.NewString(userProfile.Currency, userProfile.Currency != ""),
		NetsuiteCustomerID:    null.NewString(userProfile.NetsuiteCustomerID, userProfile.NetsuiteCustomerID != ""),
		PriceList:             null.JSONFrom(priceListJSON),
		CreatedAt:             userProfile.CreatedAt,
	}

	// Insert the user profile into the database
	err := row.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return "", fmt.Errorf("failed to insert User Profile: %v", err)
	}

	return row.ID, nil
}

// UpdateUserProfile updates an existing user profile in the database
func (s *Service) UpdateUserProfile(ctx context.Context, userProfile *types.UserProfile) error {
	userProfileModel := &model.UserProfile{
		ID:                    userProfile.ID,
		UserID:                userProfile.UserID,
		Email:                 userProfile.Email,
		FirstName:             null.NewString(userProfile.FirstName, userProfile.FirstName != ""),
		LastName:              null.NewString(userProfile.LastName, userProfile.LastName != ""),
		JobTitle:              null.NewString(userProfile.JobTitle, userProfile.JobTitle != ""),
		Phone:                 null.NewString(userProfile.Phone, userProfile.Phone != ""),
		ProfilePhotoURL:       null.NewString(userProfile.ProfilePhotoURL, userProfile.ProfilePhotoURL != ""),
		AddressLine1:          null.NewString(userProfile.AddressLine1, userProfile.AddressLine1 != ""),
		City:                  null.NewString(userProfile.City, userProfile.City != ""),
		StateProvince:         null.NewString(userProfile.StateProvince, userProfile.StateProvince != ""),
		Country:               null.NewString(userProfile.Country, userProfile.Country != ""),
		ZipPostalCode:         null.NewString(userProfile.ZipPostalCode, userProfile.ZipPostalCode != ""),
		GDPROptOut:            null.BoolFrom(userProfile.GDPROptOut),
		PrivacyPolicyAccepted: null.BoolFrom(userProfile.PrivacyPolicyAccepted),
		LinkedProfiles:        null.JSONFrom(userProfile.LinkedProfiles),
		Timezone:              null.NewString(userProfile.Timezone, userProfile.Timezone != ""),
		UnitSystem:            null.NewString(userProfile.UnitSystem, userProfile.UnitSystem != ""),
		CustomerType:          null.NewString(userProfile.CustomerType, userProfile.CustomerType != ""),
		ClientType:            null.NewString(userProfile.ClientType, userProfile.ClientType != ""),
		CompanyName:           null.NewString(userProfile.CompanyName, userProfile.CompanyName != ""),
		CompanyWebsite:        null.NewString(userProfile.CompanyWebsite, userProfile.CompanyWebsite != ""),
		Currency:              null.NewString(userProfile.Currency, userProfile.Currency != ""),
		NetsuiteCustomerID:    null.NewString(userProfile.NetsuiteCustomerID, userProfile.NetsuiteCustomerID != ""),
		PriceList:             null.JSONFrom(userProfile.PriceList),
		CreatedAt:             userProfile.CreatedAt,
	}
	_, err := userProfileModel.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update user profile: %v", err)
	}

	return nil
}
