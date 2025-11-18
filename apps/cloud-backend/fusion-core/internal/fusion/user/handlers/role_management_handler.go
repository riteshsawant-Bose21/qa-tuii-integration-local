package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
)

// RoleManagementHandler handles role and permission management endpoints
type RoleManagementHandler struct {
	userService           *db.Service
	roleManagementService *db.RoleManagementService
}

// NewRoleManagementHandler creates a new role management handler
func NewRoleManagementHandler(userService *db.Service, roleManagementService *db.RoleManagementService) *RoleManagementHandler {
	return &RoleManagementHandler{
		userService:           userService,
		roleManagementService: roleManagementService,
	}
}

// GetOrganizationRoleManagement handles GET /api/v1/organization/role-management
func (h *RoleManagementHandler) GetOrganizationRoleManagement(w http.ResponseWriter, r *http.Request) {
	// Get user email from JWT token (added by auth middleware)
	userEmail, ok := r.Context().Value("user_email").(string)
	if !ok {
		http.Error(w, "User email not found in token", http.StatusUnauthorized)
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(r.Context(), userEmail)
	if err != nil {
		http.Error(w, "Failed to get user authorization: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Check if user has admin permissions for role management
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(r.Context(), userEmail, userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to check admin permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if !hasAdminPermission {
		http.Error(w, "Insufficient permissions for role management", http.StatusForbidden)
		return
	}

	// Get role management data for the organization
	roleManagementData, err := h.roleManagementService.GetOrganizationRoleManagement(r.Context(), userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to get role management data: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(roleManagementData)
}

// CreateRole handles POST /api/v1/organization/roles
func (h *RoleManagementHandler) CreateRole(w http.ResponseWriter, r *http.Request) {
	// Get user email from JWT token
	userEmail, ok := r.Context().Value("user_email").(string)
	if !ok {
		http.Error(w, "User email not found in token", http.StatusUnauthorized)
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(r.Context(), userEmail)
	if err != nil {
		http.Error(w, "Failed to get user authorization: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(r.Context(), userEmail, userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to check admin permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if !hasAdminPermission {
		http.Error(w, "Insufficient permissions to create roles", http.StatusForbidden)
		return
	}

	// Parse request body
	var req types.CreateRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Create the role
	role, err := h.roleManagementService.CreateRole(r.Context(), userAuth.Account.ID, &req)
	if err != nil {
		http.Error(w, "Failed to create role: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(role)
}

// UpdateUserRole handles PUT /api/v1/organization/users/{userID}/role
func (h *RoleManagementHandler) UpdateUserRole(w http.ResponseWriter, r *http.Request) {
	// Get user email from JWT token
	userEmail, ok := r.Context().Value("user_email").(string)
	if !ok {
		http.Error(w, "User email not found in token", http.StatusUnauthorized)
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(r.Context(), userEmail)
	if err != nil {
		http.Error(w, "Failed to get user authorization: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(r.Context(), userEmail, userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to check admin permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if !hasAdminPermission {
		http.Error(w, "Insufficient permissions to update user roles", http.StatusForbidden)
		return
	}

	// Get user ID from URL path (assuming it's passed as a path parameter)
	// Extract userID from the URL path - you'll need to implement this based on your router
	userID := r.URL.Query().Get("userID")
	if userID == "" {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	// Parse request body
	var req types.AssignRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Update user role
	err = h.roleManagementService.UpdateUserRole(r.Context(), userID, userAuth.Account.ID, req.RoleID)
	if err != nil {
		http.Error(w, "Failed to update user role: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "User role updated successfully"})
}

// UpdateRolePermissions handles PUT /api/v1/organization/roles/{roleID}/permissions
func (h *RoleManagementHandler) UpdateRolePermissions(w http.ResponseWriter, r *http.Request) {
	// Get user email from JWT token
	userEmail, ok := r.Context().Value("user_email").(string)
	if !ok {
		http.Error(w, "User email not found in token", http.StatusUnauthorized)
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(r.Context(), userEmail)
	if err != nil {
		http.Error(w, "Failed to get user authorization: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(r.Context(), userEmail, userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to check admin permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if !hasAdminPermission {
		http.Error(w, "Insufficient permissions to update role permissions", http.StatusForbidden)
		return
	}

	// Get role ID from URL query parameter
	roleIDStr := r.URL.Query().Get("roleID")
	if roleIDStr == "" {
		http.Error(w, "Role ID is required", http.StatusBadRequest)
		return
	}

	roleID, err := strconv.Atoi(roleIDStr)
	if err != nil {
		http.Error(w, "Invalid role ID", http.StatusBadRequest)
		return
	}

	// Parse request body
	var permissions []types.PermissionUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&permissions); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Update role permissions
	err = h.roleManagementService.UpdateRolePermissions(r.Context(), roleID, userAuth.Account.ID, permissions)
	if err != nil {
		http.Error(w, "Failed to update role permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Role permissions updated successfully"})
}

// GetOrganizationUsers handles GET /api/v1/organization/users
func (h *RoleManagementHandler) GetOrganizationUsers(w http.ResponseWriter, r *http.Request) {
	// Get user email from JWT token
	userEmail, ok := r.Context().Value("user_email").(string)
	if !ok {
		http.Error(w, "User email not found in token", http.StatusUnauthorized)
		return
	}

	// Get user authorization to find their account
	userAuth, err := h.userService.GetUserAuthorization(r.Context(), userEmail)
	if err != nil {
		http.Error(w, "Failed to get user authorization: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Check admin permissions
	hasAdminPermission, err := h.roleManagementService.CheckAdminPermission(r.Context(), userEmail, userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to check admin permissions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if !hasAdminPermission {
		http.Error(w, "Insufficient permissions to view organization users", http.StatusForbidden)
		return
	}

	// Get organization users via role management data
	roleManagementData, err := h.roleManagementService.GetOrganizationRoleManagement(r.Context(), userAuth.Account.ID)
	if err != nil {
		http.Error(w, "Failed to get organization users: "+err.Error(), http.StatusInternalServerError)
		return
	}

	response := types.OrganizationUsersResponse{
		Users:   convertToUserWithRole(roleManagementData.Users),
		Account: userAuth.Account,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
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
