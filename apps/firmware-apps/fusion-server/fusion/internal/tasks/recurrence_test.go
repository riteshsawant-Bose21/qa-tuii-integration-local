package tasks

import (
	"testing"
	"time"

	"fusion/internal/api"
)

func TestParseHHMM_Valid(t *testing.T) {
	tests := []struct {
		input string
		hour  int
		min   int
	}{
		{"00:00", 0, 0},
		{"09:15", 9, 15},
		{"23:59", 23, 59},
	}

	for _, tt := range tests {
		ct, err := parseHHMM(tt.input)
		if err != nil {
			t.Fatalf("parseHHMM(%q) returned error: %v", tt.input, err)
		}
		if ct.H != tt.hour || ct.M != tt.min {
			t.Fatalf("parseHHMM(%q) = {%d:%d}, want {%d:%d}", tt.input, ct.H, ct.M, tt.hour, tt.min)
		}
	}
}

func TestParseHHMM_Invalid(t *testing.T) {
	invalid := []string{
		"", "9:00", "24:00", "12:60", "aa:bb", "12-00", "12:", ":30", "123:45",
	}

	for _, s := range invalid {
		if _, err := parseHHMM(s); err == nil {
			t.Fatalf("parseHHMM(%q) expected error, got nil", s)
		}
	}
}

func TestValidateRecurringWindow_Valid(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "17:00",
		Days:      []int{1, 2, 3, 4, 5},
	}
	if err := validateRecurringWindow(r); err != nil {
		t.Fatalf("validateRecurringWindow returned error for valid window: %v", err)
	}
}

func TestValidateRecurringWindow_InvalidTimes(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "9:00", // invalid format
		EndTime:   "17:00",
		Days:      []int{1},
	}
	if err := validateRecurringWindow(r); err == nil {
		t.Fatal("validateRecurringWindow expected error for invalid start_time, got nil")
	}

	r = &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "25:00", // invalid hour
		Days:      []int{1},
	}
	if err := validateRecurringWindow(r); err == nil {
		t.Fatal("validateRecurringWindow expected error for invalid end_time, got nil")
	}
}

func TestValidateRecurringWindow_InvalidDays(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "17:00",
		Days:      []int{-1, 0, 7},
	}
	if err := validateRecurringWindow(r); err == nil {
		t.Fatal("validateRecurringWindow expected error for invalid days, got nil")
	}
}

// helper to build a time with specific weekday and clock time
func makeTime(weekday time.Weekday, hour, min int) time.Time {
	// Use a fixed date with the requested weekday.
	// Start from a known Monday and offset.
	base := time.Date(2024, 1, 1, hour, min, 0, 0, time.UTC) // 2024-01-01 is Monday
	for base.Weekday() != weekday {
		base = base.AddDate(0, 0, 1)
	}
	return base
}

func TestWithinRecurringWindow_NilWindow(t *testing.T) {
	now := time.Now()
	if !withinRecurringWindow(nil, now) {
		t.Fatal("withinRecurringWindow(nil, now) should be true (no constraints)")
	}
}

func TestWithinRecurringWindow_SimpleDayWindow(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "17:00",
		// Days empty => all days allowed
	}

	in := makeTime(time.Wednesday, 10, 0)
	if !withinRecurringWindow(r, in) {
		t.Fatalf("Expected in-window at %v", in)
	}

	before := makeTime(time.Wednesday, 8, 59)
	if withinRecurringWindow(r, before) {
		t.Fatalf("Expected out-of-window before start at %v", before)
	}

	after := makeTime(time.Wednesday, 17, 0)
	if withinRecurringWindow(r, after) {
		t.Fatalf("Expected out-of-window at or after end at %v", after)
	}
}

func TestWithinRecurringWindow_DaysOfWeek(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "17:00",
		Days:      []int{1, 2, 3, 4, 5}, // Mon–Fri
	}

	tuesday := makeTime(time.Tuesday, 10, 0)
	if !withinRecurringWindow(r, tuesday) {
		t.Fatalf("Expected in-window on allowed day (Tuesday) at %v", tuesday)
	}

	sunday := makeTime(time.Sunday, 10, 0)
	if withinRecurringWindow(r, sunday) {
		t.Fatalf("Expected out-of-window on disallowed day (Sunday) at %v", sunday)
	}
}

func TestWithinRecurringWindow_OvernightWindow(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "22:00", // 10 PM
		EndTime:   "06:00", // 6 AM (next day)
		// Days empty => all days
	}

	late := makeTime(time.Friday, 23, 0) // 23:00
	if !withinRecurringWindow(r, late) {
		t.Fatalf("Expected in-window at %v (late night)", late)
	}

	early := makeTime(time.Saturday, 2, 0) // 02:00
	if !withinRecurringWindow(r, early) {
		t.Fatalf("Expected in-window at %v (early morning)", early)
	}

	day := makeTime(time.Saturday, 12, 0) // 12:00
	if withinRecurringWindow(r, day) {
		t.Fatalf("Expected out-of-window at %v (daytime)", day)
	}
}

func TestWithinRecurringWindow_DegenerateStartEqualsEnd(t *testing.T) {
	r := &api.RecurringWindow{
		StartTime: "09:00",
		EndTime:   "09:00",
	}

	now := makeTime(time.Monday, 9, 0)
	if withinRecurringWindow(r, now) {
		t.Fatalf("Expected degenerate window (start==end) to be treated as closed at %v", now)
	}
}
