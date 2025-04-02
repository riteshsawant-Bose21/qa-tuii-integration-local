package utils

import "net/http"

func IsDeleteRequest(r *http.Request) bool {
	return r.Method == http.MethodDelete
}

func IsGetRequest(r *http.Request) bool {
	return r.Method == http.MethodGet
}

func IsPatchRequest(r *http.Request) bool {
	return r.Method == http.MethodPatch
}

func IsPostRequest(r *http.Request) bool {
	return r.Method == http.MethodPost
}

func IsPutRequest(r *http.Request) bool {
	return r.Method == http.MethodPut
}
