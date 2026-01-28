package ptr

// AssignIfNotNull assigns the value from source to target if source is not nil.
// Eg. used to update only the fields which are present in the request payload and are not null
func AssignIfNotNull[T any](target *T, source *T) {
	if source != nil {
		*target = *source
	}
}
