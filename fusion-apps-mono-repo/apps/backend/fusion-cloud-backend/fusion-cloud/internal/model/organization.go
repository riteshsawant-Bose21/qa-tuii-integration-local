package model

import "time"

// Organization represents the structure of an organization in the system.
type Organization struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	CreatedAt    time.Time `json:"created_at"`
	Lab          bool      `json:"lab"`
	Partner      string    `json:"partner"`
	Domain       string    `json:"domain"`
	MobileDomain string    `json:"mobile_domain"`
	PricingPlan  string    `json:"pricing_plan"`
	Contacts     struct {
		AdminEmail   string `json:"admin_email"`
		AdminName    string `json:"admin_name"`
		FinanceEmail string `json:"finance_email"`
		FinanceName  string `json:"finance_name"`
	} `json:"contacts"`
	Statistics struct {
		Devices         int `json:"devices"`
		Users           int `json:"users"`
		Groups          int `json:"groups"`
		Spaces          int `json:"spaces"`
		OpenTickets     int `json:"open_tickets"`
		OpenIncidents   int `json:"open_incidents"`
		PendingInvoices int `json:"pending_invoices"`
	} `json:"statistics"`
}

type OrganizationRequest struct {
	Name        string `json:"name" validate:"required"`
	Description string `json:"description,omitempty"`
	MetaData    string `json:"metadata,omitempty"` // JSON string for additional project data
}

type OrganizationResponse struct {
	ID          int64  `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	MetaData    string `json:"metadata,omitempty"` // JSON string for additional project data
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}
