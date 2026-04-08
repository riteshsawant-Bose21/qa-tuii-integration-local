package api

// String implements fmt.Stringer for SWUpdateStatus.
func (s SWUpdateStatus) String() string {
	switch s {
	case SWUpdateStatusIdle:
		return "IDLE"
	case SWUpdateStatusStart:
		return "STARTING"
	case SWUpdateStatusRun:
		return "IN_PROGRESS"
	case SWUpdateStatusSuccess:
		return "SUCCESS"
	case SWUpdateStatusFailure:
		return "FAILED"
	case SWUpdateStatusDownload:
		return "DOWNLOADING"
	case SWUpdateStatusDone:
		return "COMPLETED"
	case SWUpdateStatusSubprocess:
		return "SUBPROCESS"
	case SWUpdateStatusProgress:
		return "PROGRESS"
	default:
		return "UNKNOWN"
	}
}
