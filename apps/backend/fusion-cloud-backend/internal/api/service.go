package api

import (
	"errors"

	// "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/api/handler"

	// "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/api/handler"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion/product"
	"github.com/gin-gonic/gin"
)

// API is a service for the main API.
type API struct {
	engine  *gin.Engine
	product product.Product
}

// New returns a new API from the given services.
func New(
	productSvc product.Product,
) (*API, error) {
	engine := gin.Default()
	if productSvc == nil {
		return nil, errors.New("missing product service")
	}

	api := &API{
		engine:  engine,
		product: productSvc,
	}

	api.registerRoutes()
	return api, nil
}

func (a *API) Engine() *gin.Engine {
	return a.engine
}

// type Product interface {
// 	GetProductByID(ctx context.Context, id string) (*fusion.Product, error)
// 	GetAllProducts(ctx context.Context) (*fusion.Product, error)
// }

// func (a *API) Product() product.Product {
// 	return a.product
// }

// Router manages all API routes
// type Router struct {
// 	productHandler *handler.ProductHandler
// }

// func NewRouter(productService productService) *Router {
// 	return &Router{
// 		productHandler: handler.NewProductHandler(productService),
// 	}
// }

// // RegisterRoutes wires up all routes and handlers
// func (r *Router) RegisterRoutes(engine *gin.Engine) {

// 	v1 := engine.Group("/api/v1")
// 	{
// 		products := v1.Group("/products")
// 		{
// 			products.GET("", r.productHandler.GetAllProducts)
// 		}
// 	}
// }
