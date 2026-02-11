package tasks

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"fusion/internal/api"
)

type clockTime struct {
	H int
	M int
}

func parseHHMM(s string) (clockTime, error) {
	var ct clockTime

	if len(s) != 5 {
		return ct, fmt.Errorf("time %q must be exactly HH:MM", s)
	}
	parts := strings.Split(s, ":")
	if len(parts) != 2 {
		return ct, fmt.Errorf("time %q must be in HH:MM format", s)
	}

	h, err := strconv.Atoi(parts[0])
	if err != nil || h < 0 || h > 23 {
		return ct, fmt.Errorf("invalid hour in time %q", s)
	}

	m, err := strconv.Atoi(parts[1])
	if err != nil || m < 0 || m > 59 {
		return ct, fmt.Errorf("invalid minute in time %q", s)
	}

	ct.H = h
	ct.M = m
	return ct, nil
}

// validateRecurringWindow performs basic validation on a RecurringWindow.
func validateRecurringWindow(r *api.RecurringWindow) error {
	if r == nil {
		return nil
	}

	if strings.TrimSpace(r.StartTime) == "" {
		return fmt.Errorf("recurrence.start_time is required")
	}
	if strings.TrimSpace(r.EndTime) == "" {
		return fmt.Errorf("recurrence.end_time is required")
	}

	if _, err := parseHHMM(r.StartTime); err != nil {
		return fmt.Errorf("recurrence.start_time: %w", err)
	}
	if _, err := parseHHMM(r.EndTime); err != nil {
		return fmt.Errorf("recurrence.end_time: %w", err)
	}

	for _, d := range r.Days {
		if d < 0 || d > 6 {
			return fmt.Errorf("recurrence.days contains invalid day %d (must be 0–6)", d)
		}
	}

	return nil
}

// withinRecurringWindow returns true if now falls inside the given recurring window.
func withinRecurringWindow(r *api.RecurringWindow, now time.Time) bool {
	if r == nil {
		return true
	}

	// Day-of-week check
	if len(r.Days) > 0 {
		dow := int(now.Weekday()) // 0=Sunday
		ok := false
		for _, d := range r.Days {
			if d == dow {
				ok = true
				break
			}
		}
		if !ok {
			return false
		}
	}

	startCT, err := parseHHMM(r.StartTime)
	if err != nil {
		// Invalid windows are treated as "closed"
		return false
	}
	endCT, err := parseHHMM(r.EndTime)
	if err != nil {
		return false
	}

	nowMinutes := now.Hour()*60 + now.Minute()
	startMinutes := startCT.H*60 + startCT.M
	endMinutes := endCT.H*60 + endCT.M

	// Normal window: start < end (e.g. 09:00–17:00)
	if startMinutes < endMinutes {
		return nowMinutes >= startMinutes && nowMinutes < endMinutes
	}

	// Overnight window: start > end (e.g. 22:00–06:00)
	// In that case, we are in-window if:
	// now >= start OR now < end (wraps across midnight)
	if startMinutes > endMinutes {
		return nowMinutes >= startMinutes || nowMinutes < endMinutes
	}

	// start == end → degenerate; treat as "always closed"
	return false
}
