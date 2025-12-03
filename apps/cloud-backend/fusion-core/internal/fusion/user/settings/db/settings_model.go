package db

import (
	"errors"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

var (
	UserSettingsTable string = model.TableNames.UserSettings
)

// Column name mappings
var (
	UserSettingsColumnID        = model.UserSettingColumns.ID
	UserSettingsColumnUserID    = model.UserSettingColumns.UserID
	UserSettingsColumnLanguage  = model.UserSettingColumns.Language
	UserSettingsColumnTheme     = model.UserSettingColumns.Theme
	UserSettingsColumnCreatedAt = model.UserSettingColumns.CreatedAt
	UserSettingsColumnUpdatedAt = model.UserSettingColumns.UpdatedAt
)

func newUserSettings(row *model.UserSetting) (*types.UserSettings, error) {
	if row == nil {
		return nil, errors.New("dbUserSettings cannot be nil")
	}

	// Handle nullable fields
	var updatedAt *time.Time
	if row.UpdatedAt.Valid {
		t := row.UpdatedAt.Time
		updatedAt = &t
	}

	return &types.UserSettings{
		ID:        row.ID,
		UserID:    row.UserID,
		Language:  row.Language.String,
		Theme:     row.Theme.String,
		CreatedAt: row.CreatedAt,
		UpdatedAt: updatedAt,
	}, nil
}
