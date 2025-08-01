package handler

import (
	"net/http"

	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"

	"github.com/go-chi/chi/v5"
)

type ProductHandler struct {
	service service.ProductService
}

func NewProductHandler(s service.ProductService) *ProductHandler {
	return &ProductHandler{service: s}
}

func (h *ProductHandler) RegisterRoutes(r chi.Router) {
	r.Get("/", h.GetProducts)
	r.Get("/filtered", h.GetFilteredProducts)
}

// GetProducts godoc
// @Summary      List all products
// @Description  Fetch all products available to the authenticated user
// @Tags         product
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /products [get]
func (h *ProductHandler) GetProducts(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}
	products, err := h.service.GetProducts()
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProductListFetchFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProductListFetched, products)
}

// GetFilteredProducts godoc
// @Summary      List filtered products
// @Description  Fetch products whose name matches predefined keyword filters
// @Tags         product
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /products/filtered [get]
func (h *ProductHandler) GetFilteredProducts(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}
	products, err := h.service.GetFilteredByKeywords()
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProductListFetchFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProductListFetched, products)
}
