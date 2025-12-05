package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
)

type Service struct {
	db *sql.DB
}

// NewService initializes the DB service
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// SelectByUserID fetches user profile for a specific userID
func (s *Service) SelectByUserID(ctx context.Context, userID string) (*types.UserProfile, error) {
	row, err := model.UserProfiles(model.UserProfileWhere.UserID.EQ(userID)).One(ctx, s.db)
	if err != nil {
		return nil, err
	}

	return newUserProfile(row)
}

// Insert a new user profile in the database
func (s *Service) Insert(ctx context.Context, userProfile *types.UserProfile) error {

	// Validations
	if userProfile == nil {
		return fmt.Errorf("userProfile cannot be nil")
	}

	linkedProfilesJSON, errLinkedProfiles := json.Marshal(userProfile.LinkedProfiles)
	if errLinkedProfiles != nil {
		return fmt.Errorf("failed to marshal linked profiles: %v", errLinkedProfiles)
	}

	PriceListJSON, errPriceList := json.Marshal(userProfile.PriceList)
	if errPriceList != nil {
		return fmt.Errorf("failed to marshal price list: %v", errPriceList)
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
		GDPROptOut:            null.NewBool(userProfile.GDPROptOut, userProfile.GDPROptOut),
		PrivacyPolicyAccepted: null.NewBool(userProfile.PrivacyPolicyAccepted, userProfile.PrivacyPolicyAccepted),
		LinkedProfiles:        null.JSONFrom(linkedProfilesJSON),
		Timezone:              null.NewString(userProfile.Timezone, userProfile.Timezone != ""),
		UnitSystem:            null.NewString(userProfile.UnitSystem, userProfile.UnitSystem != ""),
		CustomerType:          null.NewString(userProfile.CustomerType, userProfile.CustomerType != ""),
		ClientType:            null.NewString(userProfile.ClientType, userProfile.ClientType != ""),
		CompanyName:           null.NewString(userProfile.CompanyName, userProfile.CompanyName != ""),
		CompanyWebsite:        null.NewString(userProfile.CompanyWebsite, userProfile.CompanyWebsite != ""),
		Currency:              null.NewString(userProfile.Currency, userProfile.Currency != ""),
		NetsuiteCustomerID:    null.NewString(userProfile.NetsuiteCustomerID, userProfile.NetsuiteCustomerID != ""),
		PriceList:             null.JSONFrom(PriceListJSON),
		CreatedAt:             userProfile.CreatedAt,
	}

	// Insert the user profile into the database
	err := row.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert User Profile: %v", err)
	}

	// Populate the ID from the inserted row
	userProfile.ID = row.ID
	return nil
}

func (s *Service) Update(ctx context.Context, userProfile *types.UserProfile) error {
	if userProfile == nil {
		return fmt.Errorf("userProfile cannot be nil")
	}

	linkedProfilesJSON, errLinkedProfiles := json.Marshal(userProfile.LinkedProfiles)
	if errLinkedProfiles != nil {
		return fmt.Errorf("failed to marshal linked profiles: %v", errLinkedProfiles)
	}

	PriceListJSON, errPriceList := json.Marshal(userProfile.PriceList)
	if errPriceList != nil {
		return fmt.Errorf("failed to marshal price list: %v", errPriceList)
	}

	existingProfile, err := model.UserProfiles(model.UserProfileWhere.ID.EQ(userProfile.ID)).One(ctx, s.db)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user profile not found")
		}
		return fmt.Errorf("failed to fetch user profile: %v", err)
	}

	if existingProfile.UserID != userProfile.UserID {
		return fmt.Errorf("user profile does not belong to the specified user")
	}

	row := &model.UserProfile{
		ID:                    existingProfile.ID,
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
		GDPROptOut:            null.NewBool(userProfile.GDPROptOut, userProfile.GDPROptOut),
		PrivacyPolicyAccepted: null.NewBool(userProfile.PrivacyPolicyAccepted, userProfile.PrivacyPolicyAccepted),
		LinkedProfiles:        null.JSONFrom(linkedProfilesJSON),
		Timezone:              null.NewString(userProfile.Timezone, userProfile.Timezone != ""),
		UnitSystem:            null.NewString(userProfile.UnitSystem, userProfile.UnitSystem != ""),
		CustomerType:          null.NewString(userProfile.CustomerType, userProfile.CustomerType != ""),
		ClientType:            null.NewString(userProfile.ClientType, userProfile.ClientType != ""),
		CompanyName:           null.NewString(userProfile.CompanyName, userProfile.CompanyName != ""),
		CompanyWebsite:        null.NewString(userProfile.CompanyWebsite, userProfile.CompanyWebsite != ""),
		Currency:              null.NewString(userProfile.Currency, userProfile.Currency != ""),
		NetsuiteCustomerID:    null.NewString(userProfile.NetsuiteCustomerID, userProfile.NetsuiteCustomerID != ""),
		PriceList:             null.JSONFrom(PriceListJSON),
		CreatedAt:             existingProfile.CreatedAt,
	}

	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update user profile: %v", err)
	}

	return nil
}
