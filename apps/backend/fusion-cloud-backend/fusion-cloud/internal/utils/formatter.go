package utils

import (
	// "fusion-cloud/internal/model"
	"strings"
)

type fieldFormatter func(value string) interface{}

// Registry of formatters
var fieldFormatters = map[string]fieldFormatter{
	"images": func(value string) interface{} {
		value = strings.TrimSpace(value)
		if value == "" {
			return []string{}
		}
		parts := strings.Split(value, ",")
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
		}
		return parts
	},

	"colors_physical": func(value string) interface{} {
		value = strings.TrimSpace(value)
		if value == "" {
			return []string{}
		}

		// Step 1: Replace escaped commas '\,' with a unique placeholder
		placeholder := "__SPLIT__"
		value = strings.ReplaceAll(value, `\,`, placeholder)

		// Step 2: Split using the placeholder
		parts := strings.Split(value, placeholder)

		// Step 3: Clean up each part
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
		}

		return parts
	},

	"maximum_peak_power_symmetrical_amplification": func(value string) interface{} {
		value = strings.TrimSpace(value)
		if value == "" {
			return []string{}
		}

		// Step 1: Split by forward slash
		parts := strings.Split(value, "/")

		// Step 2: Clean each part
		for i := range parts {
			part := parts[i]
			part = strings.ReplaceAll(part, `\,`, ",") // Replace escaped commas
			part = strings.ReplaceAll(part, `\\`, "")  // Remove any stray double slashes
			parts[i] = strings.TrimSpace(part)
		}

		return parts
	},
}

// Format fields for a single product
func FormatProductFields(p map[string]interface{}) map[string]interface{} {
	formatted := make(map[string]interface{})

	for key, val := range p {
		if formatter, exists := fieldFormatters[key]; exists {
			// Only apply if value is string
			if strVal, ok := val.(string); ok {
				formatted[key] = formatter(strVal)
			} else {
				formatted[key] = val
			}
		} else {
			formatted[key] = val
		}
	}

	return formatted
}

// Utility to prefix with http:// if not present
func FormatOrigins(origins string) []string {
	parts := strings.Split(origins, ",")
	formatted := []string{}
	for _, origin := range parts {
		origin = strings.TrimSpace(origin)
		if !strings.HasPrefix(origin, "http://") && !strings.HasPrefix(origin, "https://") {
			origin = "http://" + origin
		}
		formatted = append(formatted, origin)
	}
	return formatted
}

// MergeUserMetaData merges non-zero fields from src into dst
// func MergeUserMetaData(dst, src *model.UserMetaData) {
// 	if src.XyteApiKey != "" {
// 		dst.XyteApiKey = src.XyteApiKey
// 	}
// 	if src.MeasurementUnit != "" {
// 		dst.MeasurementUnit = src.MeasurementUnit
// 	}
// 	if src.Currency != "" {
// 		dst.Currency = src.Currency
// 	}
// 	if src.Language != "" {
// 		dst.Language = src.Language
// 	}
// 	if src.Location != "" {
// 		dst.Location = src.Location
// 	}
// 	// Merge nested structs (PersonalInfo, Security, Address, Notifications)
// 	if src.PersonalInfo.Name != "" {
// 		dst.PersonalInfo.Name = src.PersonalInfo.Name
// 	}
// 	if src.PersonalInfo.Organization != "" {
// 		dst.PersonalInfo.Organization = src.PersonalInfo.Organization
// 	}
// 	if src.PersonalInfo.JobTitle != "" {
// 		dst.PersonalInfo.JobTitle = src.PersonalInfo.JobTitle
// 	}
// 	if src.PersonalInfo.Phone != "" {
// 		dst.PersonalInfo.Phone = src.PersonalInfo.Phone
// 	}
// 	if src.Security.Username != "" {
// 		dst.Security.Username = src.Security.Username
// 	}
// 	if src.Security.Password != "" {
// 		dst.Security.Password = src.Security.Password
// 	}
// 	dst.Security.IsTwoFactorEnabled = src.Security.IsTwoFactorEnabled
// 	dst.Security.EnableEmailNotifications = src.Security.EnableEmailNotifications
// 	dst.Security.EnableSMSNotifications = src.Security.EnableSMSNotifications
// 	if src.Address.AddressLine1 != "" {
// 		dst.Address.AddressLine1 = src.Address.AddressLine1
// 	}
// 	if src.Address.AddressLine2 != "" {
// 		dst.Address.AddressLine2 = src.Address.AddressLine2
// 	}
// 	if src.Address.City != "" {
// 		dst.Address.City = src.Address.City
// 	}
// 	if src.Address.State != "" {
// 		dst.Address.State = src.Address.State
// 	}
// 	if src.Address.ZipCode != "" {
// 		dst.Address.ZipCode = src.Address.ZipCode
// 	}
// 	if src.Address.Country != "" {
// 		dst.Address.Country = src.Address.Country
// 	}
// 	if src.Address.Timezone != "" {
// 		dst.Address.Timezone = src.Address.Timezone
// 	}
// 	dst.Notifications.ProductUpdates = src.Notifications.ProductUpdates
// 	dst.Notifications.ProjectActivity = src.Notifications.ProjectActivity
// 	dst.Notifications.TrainingAndResources = src.Notifications.TrainingAndResources
// }
