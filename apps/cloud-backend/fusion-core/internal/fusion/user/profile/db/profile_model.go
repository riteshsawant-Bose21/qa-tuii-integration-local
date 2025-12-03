package db

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

var (
	UserProfileTable string = model.TableNames.UserProfile
)

// Column name mappings
var (
	UserProfileColumnUserID             = model.UserProfileColumns.UserID
	UserProfileColumnEmail              = model.UserProfileColumns.Email
	UserProfileColumnFirstName          = model.UserProfileColumns.FirstName
	UserProfileColumnLastName           = model.UserProfileColumns.LastName
	UserProfileColumnJobTitle           = model.UserProfileColumns.JobTitle
	UserProfileColumnPhone              = model.UserProfileColumns.Phone
	UserProfileColumnProfilePhotoURL    = model.UserProfileColumns.ProfilePhotoURL
	UserProfileColumnAddressLine1       = model.UserProfileColumns.AddressLine1
	UserProfileColumnCity               = model.UserProfileColumns.City
	UserprofileColumnstateProvince      = model.UserProfileColumns.StateProvince
	UserProfileColumnCountry            = model.UserProfileColumns.Country
	UserProfileColumnZipPostalCode      = model.UserProfileColumns.ZipPostalCode
	UserProfileColumnGDPROptOut         = model.UserProfileColumns.GDPROptOut
	UserProfileColumnPrivacyPolicy      = model.UserProfileColumns.PrivacyPolicyAccepted
	UserProfileColumnLinkedProfiles     = model.UserProfileColumns.LinkedProfiles
	UserProfileColumnTimezone           = model.UserProfileColumns.Timezone
	UserProfileColumnUnitSystem         = model.UserProfileColumns.UnitSystem
	UserProfileColumnCustomerType       = model.UserProfileColumns.CustomerType
	UserProfileColumnClientType         = model.UserProfileColumns.ClientType
	UserProfileColumnCompanyName        = model.UserProfileColumns.CompanyName
	UserProfileColumnCompanyWebsite     = model.UserProfileColumns.CompanyWebsite
	UserProfileColumnCurrency           = model.UserProfileColumns.Currency
	UserProfileColumnNetsuiteCustomerID = model.UserProfileColumns.NetsuiteCustomerID
	UserProfileColumnPriceList          = model.UserProfileColumns.PriceList
	UserProfileColumnCreatedAt          = model.UserProfileColumns.CreatedAt
	UserProfileColumnUpdatedAt          = model.UserProfileColumns.UpdatedAt
)

func newUserProfile(row *model.UserProfile) (*types.UserProfile, error) {
	if row == nil {
		return nil, errors.New("dbUserProfile cannot be nil")
	}

	// Handle nullable fields
	var updatedAt *time.Time
	if row.UpdatedAt.Valid {
		t := row.UpdatedAt.Time
		updatedAt = &t
	}

	var linkedProfiles json.RawMessage
	if row.LinkedProfiles.Valid {
		linkedProfiles = json.RawMessage(row.LinkedProfiles.JSON)
	}

	var priceList json.RawMessage
	if row.PriceList.Valid {
		priceList = json.RawMessage(row.PriceList.JSON)
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
