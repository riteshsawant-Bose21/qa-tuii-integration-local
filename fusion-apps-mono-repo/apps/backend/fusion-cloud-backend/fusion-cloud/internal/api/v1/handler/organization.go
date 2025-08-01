package handler

import (
	"fmt"
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
	"net/http"

	"github.com/go-chi/chi/v5"
)

type Organization struct {
	svc *service.Organization
}

func NewOrganizationHandler(svc *service.Organization) *Organization {
	return &Organization{
		svc: svc,
	}
}

func (o *Organization) RegisterRoutes(r chi.Router) {
	r.Get("/", o.GetOrganization)
}

// GetOrganization godoc
// @Summary      get Organization details
// @Description  Fetch all organization available to the authenticated user
// @Tags         organization
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /organization [get]
func (o *Organization) GetOrganization(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	orgs, err := o.svc.GETOrganization()
	if err != nil {
		fmt.Println("Error response returned")
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgOrganizationListFetchFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgOrganizationListFetched, orgs)
}
