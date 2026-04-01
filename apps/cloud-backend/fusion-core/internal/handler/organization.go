package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
)

// OrganizationHandler handles organization management endpoints
type OrganizationHandler struct {
	organizationService fusion.Organization
	userService         fusion.User
}

// NewOrganizationHandler creates a new organization handler
func NewOrganizationHandler(organizationService fusion.Organization, userService fusion.User) *OrganizationHandler {
	return &OrganizationHandler{
		organizationService: organizationService,
		userService:         userService,
	}
}

// GetAllOrganizations retrieves all organizations with statistics and pagination
// @Summary Get all organizations
// @Description Get comprehensive overview of all organizations with statistics, filtering, and pagination
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param query query string false "Search query for organization name"
// @Param type query []string false "Filter by organization types" Enums(distributor, reseller, end_user)
// @Param region query []string false "Filter by regions"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} types.OrganizationsOverviewResponse "Successfully retrieved organizations"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to view organizations"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations [get]
func (h *OrganizationHandler) GetAllOrganizations(ctx *gin.Context) {
	// Get user authorization to exclude their own organization
	userAuth, userExists := ctx.Get("user_auth")
	var excludeAccountID string

	if userExists {
		if auth, ok := userAuth.(*types.UserAuthorizationResponse); ok {
			excludeAccountID = auth.Account.ID
		}
	}

	// Parse query parameters
	var searchParams types.OrganizationSearchRequest
	if err := ctx.ShouldBindQuery(&searchParams); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid query parameters: " + err.Error(),
		})
		return
	}

	// Set defaults
	if searchParams.Page <= 0 {
		searchParams.Page = 1
	}
	if searchParams.Limit <= 0 {
		searchParams.Limit = 10
	}

	// Get organizations (excluding user's own organization)
	response, err := h.organizationService.GetAllOrganizations(ctx, &searchParams, excludeAccountID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get organizations: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, response)
}

// GetOrganizationByID retrieves detailed information about a specific organization
// @Summary Get organization details
// @Description Get comprehensive details about a specific organization including users, projects, and statistics
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param organizationId path string true "Organization ID"
// @Success 200 {object} types.OrganizationDetailsResponse "Successfully retrieved organization details"
// @Failure 400 {object} map[string]string "Bad request - Invalid organization ID"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to view organization details"
// @Failure 404 {object} map[string]string "Not found - Organization not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations/{organizationId} [get]
func (h *OrganizationHandler) GetOrganizationByID(ctx *gin.Context) {
	// Skip JWT validation for testing
	// _, exists := ctx.Get("user_email")
	// if !exists {
	//	ctx.JSON(http.StatusUnauthorized, gin.H{
	//		"error":   "Unauthorized",
	//		"message": "User email not found in token",
	//	})
	//	return
	// }

	// Get organization ID from URL path parameter
	organizationID := ctx.Param("organizationId")
	if organizationID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Organization ID is required",
		})
		return
	}

	// Get organization details
	organizationDetails, err := h.organizationService.GetOrganizationByID(ctx, organizationID)
	if err != nil {
		// You might want to check for specific error types here
		// For now, treating all errors as internal server errors
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get organization details: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, organizationDetails)
}

// CreateOrganization creates a new organization
// @Summary Create new organization
// @Description Create a new organization with specified type, region, and details
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param organization body types.CreateOrganizationRequest true "Organization creation details"
// @Success 201 {object} types.Organization "Successfully created organization"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload or validation errors"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to create organizations"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations [post]
func (h *OrganizationHandler) CreateOrganization(ctx *gin.Context) {
	// Skip authentication for testing

	// Parse request body
	var req types.CreateOrganizationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Create the organization
	organization, err := h.organizationService.CreateOrganization(ctx, &req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to create organization: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusCreated, organization)
}

// UpdateOrganization updates an existing organization
// @Summary Update organization
// @Description Update an existing organization's details
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param organizationId path string true "Organization ID"
// @Param organization body types.UpdateOrganizationRequest true "Organization update details"
// @Success 200 {object} types.Organization "Successfully updated organization"
// @Failure 400 {object} map[string]string "Bad request - Invalid organization ID or JSON payload"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to update organizations"
// @Failure 404 {object} map[string]string "Not found - Organization not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations/{organizationId} [put]
func (h *OrganizationHandler) UpdateOrganization(ctx *gin.Context) {
	// Skip authentication for testing

	// Get organization ID from URL path parameter
	organizationID := ctx.Param("organizationId")
	if organizationID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Organization ID is required",
		})
		return
	}

	// Parse request body
	var req types.UpdateOrganizationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Update the organization
	organization, err := h.organizationService.UpdateOrganization(ctx, organizationID, &req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to update organization: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, organization)
}

// DeleteOrganization deletes an organization
// @Summary Delete organization
// @Description Delete an existing organization (soft delete recommended)
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param organizationId path string true "Organization ID"
// @Success 200 {object} map[string]string "Successfully deleted organization"
// @Failure 400 {object} map[string]string "Bad request - Invalid organization ID"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to delete organizations"
// @Failure 404 {object} map[string]string "Not found - Organization not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations/{organizationId} [delete]
func (h *OrganizationHandler) DeleteOrganization(ctx *gin.Context) {
	// Skip authentication for testing

	// Get organization ID from URL path parameter
	organizationID := ctx.Param("organizationId")
	if organizationID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Organization ID is required",
		})
		return
	}

	// Delete the organization
	err := h.organizationService.DeleteOrganization(ctx, organizationID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to delete organization: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Organization deleted successfully"})
}

// InviteUsersToOrganization invites multiple users to an organization
// @Summary Invite users to organization
// @Description Invite multiple users to join an organization with specified roles
// @Tags organizations
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param organizationId path string true "Organization ID"
// @Param invitations body types.InviteUsersToOrganizationRequest true "User invitations"
// @Success 200 {object} types.InviteUsersToOrganizationResponse "Successfully processed invitations"
// @Failure 400 {object} map[string]string "Bad request - Invalid organization ID or JSON payload"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to invite users"
// @Failure 404 {object} map[string]string "Not found - Organization not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organizations/{organizationId}/invite-users [post]
func (h *OrganizationHandler) InviteUsersToOrganization(ctx *gin.Context) {
	// Skip authentication for testing

	// Get organization ID from URL path parameter
	organizationID := ctx.Param("organizationId")
	if organizationID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Organization ID is required",
		})
		return
	}

	// Parse request body
	var req types.InviteUsersToOrganizationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Validate that users array is not empty
	if len(req.Users) == 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "At least one user invitation is required",
		})
		return
	}

	// Invite users to the organization
	response, err := h.organizationService.InviteUsersToOrganization(ctx, organizationID, &req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to invite users to organization: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, response)
}
