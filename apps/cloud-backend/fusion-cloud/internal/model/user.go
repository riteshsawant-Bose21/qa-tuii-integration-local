package model

type UserRegistration struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}
type UserLogin struct {
	Email    string `json:"email" validate:"required"`
	Password string `json:"password" validate:"required"`
}

type UserMetaData struct {
	XyteApiKey string `json:"xyte_api_key" validate:"required"`
	// xyteApiKey is used to store the API key for the XYTE service
	// It is not exposed in the API response and is stored securely.
	PersonalInfo struct {
		Name         string `json:"name"`
		Organization string `json:"organization"`
		JobTitle     string `json:"jobTitle"`
		Phone        string `json:"phone"`
	} `json:"personalInfo"`
	Security struct {
		Username                 string `json:"username"`
		Password                 string `json:"password"`
		IsTwoFactorEnabled       bool   `json:"isTwoFactorEnabled"`
		EnableEmailNotifications bool   `json:"enableEmailNotifications"`
		EnableSMSNotifications   bool   `json:"enableSMSNotifications"`
	} `json:"security"`
	Address struct {
		AddressLine1 string `json:"addressLine1"`
		AddressLine2 string `json:"addressLine2"`
		City         string `json:"city"`
		State        string `json:"state"`
		ZipCode      string `json:"zipCode"`
		Country      string `json:"country"`
		Timezone     string `json:"timezone"`
	} `json:"address"`
	MeasurementUnit string `json:"measurementUnit"`
	Currency        string `json:"currency"`
	Language        string `json:"language"`
	Location        string `json:"location"`
	Notifications   struct {
		ProductUpdates       bool `json:"productUpdates"`
		ProjectActivity      bool `json:"projectActivity"`
		TrainingAndResources bool `json:"trainingAndResources"`
	} `json:"notifications"`
}

type User struct {
	ID       int64  `json:"id"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"-" validate:"required,min=8"`
	MetaData string `json:"-"`
	// MetaData can store additional user information in JSON format
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type UserResponse struct {
	ID       int64       `json:"id"`
	Email    string      `json:"email"`
	MetaData interface{} `json:"metadata"`
	// MetaData is returned in the response, but sensitive fields like API keys are not included
	CreatedAt string     `json:"created_at"`
	UpdatedAt string     `json:"updated_at"`
}
