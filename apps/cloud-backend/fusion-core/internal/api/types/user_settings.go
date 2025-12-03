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
