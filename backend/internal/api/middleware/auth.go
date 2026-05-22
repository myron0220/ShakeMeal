package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/myron0220/shakemeal/internal/utils/jwtutil"
)

// UserIDKey is the gin context key where the verified user ID is stored.
const UserIDKey = "user_id"

// RequireAuth is a Gin middleware that validates a Bearer access token.
// On success it sets UserIDKey in the context and calls Next.
// On failure it aborts with 401.
func RequireAuth(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized,
				gin.H{"message": "authorization header required"})
			return
		}

		tokenStr := strings.TrimPrefix(header, "Bearer ")
		claims, err := jwtutil.Verify(tokenStr, jwtSecret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized,
				gin.H{"message": "invalid or expired token"})
			return
		}
		if claims.TokenType != "access" {
			c.AbortWithStatusJSON(http.StatusUnauthorized,
				gin.H{"message": "access token required"})
			return
		}

		c.Set(UserIDKey, claims.UserID)
		c.Next()
	}
}
