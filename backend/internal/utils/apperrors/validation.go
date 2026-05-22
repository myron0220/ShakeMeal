package apperrors

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
)

// friendlyFieldNames maps struct field names to human-readable API param names.
var friendlyFieldNames = map[string]string{
	"Lat":         "lat",
	"Lng":         "lng",
	"RadiusM":     "radius",
	"Cuisines":    "cuisine",
	"PriceLevels": "price",
	"Exclude":     "exclude",
}

// friendlyTagMessages maps validator tags to readable messages.
var friendlyTagMessages = map[string]string{
	"required": "is required",
	"min":      "is too small",
	"max":      "is too large",
}

// FormatValidationError converts go-playground/validator errors into
// clean, user-facing messages that don't expose struct internals.
//
// Input:  "Key: 'ShakeRequest.Lat' Error:Field validation for 'Lat' failed on the 'required' tag"
// Output: "lat is required"
func FormatValidationError(err error) string {
	var ve validator.ValidationErrors
	// Not a validation error — return as-is but sanitised
	if !isValidationError(err, &ve) {
		return "invalid request"
	}

	msgs := make([]string, 0, len(ve))
	for _, fe := range ve {
		field := fe.Field()
		if friendly, ok := friendlyFieldNames[field]; ok {
			field = friendly
		} else {
			field = strings.ToLower(field)
		}

		tag := fe.Tag()
		msgSuffix := fmt.Sprintf("is invalid (failed %s)", tag)
		if friendly, ok := friendlyTagMessages[tag]; ok {
			msgSuffix = friendly
		}

		msgs = append(msgs, fmt.Sprintf("%s %s", field, msgSuffix))
	}
	return strings.Join(msgs, ", ")
}

func isValidationError(err error, out *validator.ValidationErrors) bool {
	if ve, ok := err.(validator.ValidationErrors); ok {
		*out = ve
		return true
	}
	return false
}
