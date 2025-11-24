package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
)

// RoleManagementHandler handles role and permission management endpoints
type RoleManagementHandler struct {
	userService           fusion.User
	roleManagementService *userdb.RoleManagementService
}

// NewRoleManagementHandler creates a new role management handler
func NewRoleManagementHandler(userService fusion.User, roleManagementService *userdb.RoleManagementService) *RoleManagementHandler {
	return &RoleManagementHandler{
		userService:           userService,
		roleManagementService: roleManagementService,
	}
}

// GetOrganizationRoleManagement retrieves role management data for the organization.
// @Summary Get organization role management data
// @Description Get comprehensive role management data including roles, features, access levels, and users for the organization
// @Tags role-management
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.RoleManagementResponse "Successfully retrieved role management data"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions for role management"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organization/role-management [get]
func (h *RoleManagementHandler) GetOrganizationRoleManagement(ctx *gin.Context) {
	// Get user email from JWT token (added by auth middleware)
	userEmail, exists := ctx.Get("user_email")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "User email not found in token",
		})
		return
	}

	emailStr, ok := userEmail.(string)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Invalid email format",
		})
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get user authorization: " + err.Error(),
		})
		return
	}

	// Check if user has admin permissions for role management
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(ctx, emailStr, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to check admin permissions: " + err.Error(),
		})
		return
	}

	if !hasAdminPermission {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions for role management",
		})
		return
	}

	// Get role management data for the organization
	roleManagementData, err := h.roleManagementService.GetOrganizationRoleManagement(ctx, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get role management data: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, roleManagementData)
}

// CreateRole creates a new role in the organization.
// @Summary Create a new role
// @Description Create a new role with the specified name and description in the organization
// @Tags role-management
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param role body types.CreateRoleRequest true "Role creation details"
// @Success 201 {object} types.RoleWithPermissions "Successfully created role"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to create roles"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organization/roles [post]
func (h *RoleManagementHandler) CreateRole(ctx *gin.Context) {
	// Get user email from JWT token
	userEmail, exists := ctx.Get("user_email")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "User email not found in token",
		})
		return
	}

	emailStr, ok := userEmail.(string)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Invalid email format",
		})
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get user authorization: " + err.Error(),
		})
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(ctx, emailStr, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to check admin permissions: " + err.Error(),
		})
		return
	}

	if !hasAdminPermission {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions to create roles",
		})
		return
	}

	// Parse request body
	var req types.CreateRoleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Create the role
	role, err := h.roleManagementService.CreateRole(ctx, userAuth.Account.ID, &req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to create role: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusCreated, role)
}

// UpdateUserRole updates a user's role within the organization.
// @Summary Update user role
// @Description Update the role assignment for a specific user within the organization
// @Tags role-management
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param userID path string true "User ID"
// @Param roleAssignment body types.AssignRoleRequest true "Role assignment details"
// @Success 200 {object} map[string]string "Successfully updated user role"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload or missing user ID"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to update user roles"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organization/users/{userID}/role [put]
func (h *RoleManagementHandler) UpdateUserRole(ctx *gin.Context) {
	// Get user email from JWT token
	userEmail, exists := ctx.Get("user_email")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "User email not found in token",
		})
		return
	}

	emailStr, ok := userEmail.(string)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Invalid email format",
		})
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get user authorization: " + err.Error(),
		})
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(ctx, emailStr, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to check admin permissions: " + err.Error(),
		})
		return
	}

	if !hasAdminPermission {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions to update user roles",
		})
		return
	}

	// Get user ID from URL path parameter
	userID := ctx.Param("userID")
	if userID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "User ID is required",
		})
		return
	}

	// Parse request body
	var req types.AssignRoleRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Update user role
	err = h.roleManagementService.UpdateUserRole(ctx, userID, userAuth.Account.ID, req.RoleID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to update user role: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User role updated successfully"})
}

// UpdateRolePermissions updates the permissions for a specific role.
// @Summary Update role permissions
// @Description Update the permissions assigned to a specific role within the organization
// @Tags role-management
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param roleID path string true "Role ID"
// @Param permissions body []types.PermissionUpdateRequest true "Permission updates"
// @Success 200 {object} map[string]string "Successfully updated role permissions"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload or invalid role ID"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to update role permissions"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organization/roles/{roleID}/permissions [put]
func (h *RoleManagementHandler) UpdateRolePermissions(ctx *gin.Context) {
	// Get user email from JWT token
	userEmail, exists := ctx.Get("user_email")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "User email not found in token",
		})
		return
	}

	emailStr, ok := userEmail.(string)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Invalid email format",
		})
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get user authorization: " + err.Error(),
		})
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(ctx, emailStr, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to check admin permissions: " + err.Error(),
		})
		return
	}

	if !hasAdminPermission {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions to update role permissions",
		})
		return
	}

	// Get role ID from URL path parameter
	roleIDStr := ctx.Param("roleID")
	if roleIDStr == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Role ID is required",
		})
		return
	}

	roleID, err := strconv.Atoi(roleIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid role ID",
		})
		return
	}

	// Parse request body
	var permissions []types.PermissionUpdateRequest
	if err := ctx.ShouldBindJSON(&permissions); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Update role permissions
	err = h.roleManagementService.UpdateRolePermissions(ctx, roleID, userAuth.Account.ID, permissions)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to update role permissions: " + err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Role permissions updated successfully"})
}

// GetOrganizationUsers retrieves all users within the organization.
// @Summary Get organization users
// @Description Get all users within the organization along with their role information
// @Tags role-management
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.OrganizationUsersResponse "Successfully retrieved organization users"
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 403 {object} map[string]string "Forbidden - Insufficient permissions to view organization users"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /organization/users [get]
func (h *RoleManagementHandler) GetOrganizationUsers(ctx *gin.Context) {
	// Get user email from JWT token
	userEmail, exists := ctx.Get("user_email")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "User email not found in token",
		})
		return
	}

	emailStr, ok := userEmail.(string)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Invalid email format",
		})
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get user authorization: " + err.Error(),
		})
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(ctx, emailStr, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to check admin permissions: " + err.Error(),
		})
		return
	}

	if !hasAdminPermission {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "Insufficient permissions to view organization users",
		})
		return
	}

	// Get organization users via role management data
	roleManagementData, err := h.roleManagementService.GetOrganizationRoleManagement(ctx, userAuth.Account.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Internal Server Error",
			"message": "Failed to get organization users: " + err.Error(),
		})
		return
	}

	response := types.OrganizationUsersResponse{
		Users:   convertToUserWithRole(roleManagementData.Users),
		Account: userAuth.Account,
	}

	ctx.JSON(http.StatusOK, response)
}

// Helper function to convert UserBasicInfo to UserWithRole
func convertToUserWithRole(users []types.UserBasicInfo) []types.UserWithRole {
	result := make([]types.UserWithRole, len(users))
	for i, user := range users {
		result[i] = types.UserWithRole{
			ID:       user.ID,
			Email:    user.Email,
			FullName: user.FullName,
			Role: types.RoleInfo{
				ID:       user.RoleID,
				RoleName: user.RoleName,
			},
			Status: "active", // Default status
		}
	}
	return result
}
