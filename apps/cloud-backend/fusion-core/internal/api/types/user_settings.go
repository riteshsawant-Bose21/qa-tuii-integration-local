package types

import "time"

type UserSettings struct {
	ID        string     `json:"id"`
	UserID    string     `json:"user_id"`
	Language  string     `json:"language"`
	Theme     string     `json:"theme"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt *time.Time `json:"updated_at"`
}

type UpdateUserSettingsRequest struct {
	Language *string `json:"language"`
	Theme    *string `json:"theme"`
}

type StatusBadRequest struct {
	Message string `json:"message" example:"Invalid request body"`
}

type StatusInternalServerError struct {
	Message string `json:"message" example:"Internal server error"`
}

type StatusNotFound struct {
	Message string `json:"message" example:"User settings not found"`
}

type StatusBadRequestForUpdateUserSettings struct {
	Message string `json:"message" example:"id is required for updating settings"`
}

type StatusInternalServerErrorForUpdateSettings struct {
	Message string `json:"message" example:"Failed to update user settings: "`
}

type StatusOkForUpdateUserSettings struct {
	Message string `json:"message" example:"User settings updated successfully"`
}

type StatusOkForCreateUserSettings struct {
	ID string `json:"id" example:"53437319-7a5b-4462-bc7c-9e7f9a057a1a"`
}

type StatusUnauthorized struct {
	Message string `json:"message" example:"Authentication required"`
}
