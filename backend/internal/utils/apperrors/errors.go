package apperrors

import (
	"errors"
	"net/http"
)

type AppError struct {
	Code    int    `json:"-"`
	Message string `json:"message"`
	Err     error  `json:"-"`
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return e.Err.Error()
	}
	return e.Message
}

func (e *AppError) Unwrap() error { return e.Err }

// Constructors
func BadRequest(msg string) *AppError {
	return &AppError{Code: http.StatusBadRequest, Message: msg}
}

func NotFound(msg string) *AppError {
	return &AppError{Code: http.StatusNotFound, Message: msg}
}

func Internal(err error) *AppError {
	return &AppError{Code: http.StatusInternalServerError, Message: "internal server error", Err: err}
}

func Unauthorized() *AppError {
	return &AppError{Code: http.StatusUnauthorized, Message: "unauthorized"}
}

// Sentinel errors
var (
	ErrNoRestaurantsFound = errors.New("no restaurants found for the given location and filters")
	ErrPlacesAPIFailed    = errors.New("places API request failed")
)
