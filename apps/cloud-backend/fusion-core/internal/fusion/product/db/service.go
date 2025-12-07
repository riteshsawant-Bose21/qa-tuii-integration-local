package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	errorspkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
)

// Service is a service for managing products using SQLBoiler ORM.
type Service struct {
	db *sql.DB
}

// NewService creates a new SQLBoiler-based product service.
func NewService(db *sql.DB) *Service {
	return &Service{
		db: db,
	}
}

// SelectByID retrieves a product by ID using SQLBoiler.
func (s *Service) SelectByID(ctx context.Context, id string, version string) (*types.SingleProductResponse, error) {
	// Convert id string to int
	productID, err := strconv.Atoi(id)
	if err != nil {
		return nil, fmt.Errorf("invalid product ID: %w", err)
	}

	// Query using SQLBoiler
	product, err := models.Products(
		models.ProductWhere.ProductID.EQ(productID),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errorspkg.ErrProductNotFound
		}
		return nil, fmt.Errorf("failed to get product: %w", err)
	}

	// Transform to API response format
	return s.transformToSingleProductResponse(product, version)
}

// SelectAll retrieves all products using SQLBoiler.
func (s *Service) SelectAll(ctx context.Context, version string) (*types.ProductResponse, error) {
	// Query all products using SQLBoiler
	products, err := models.Products(
		qm.OrderBy(models.ProductColumns.ProductID),
	).All(ctx, s.db)

	if err != nil {
		return nil, fmt.Errorf("failed to query products: %w", err)
	}

	response := &types.ProductResponse{
		Version:    version,
		Speaker:    []types.ProductItemResponse{},
		Amplifier:  []types.ProductItemResponse{},
		Controller: []types.ProductItemResponse{},
		DSP:        []types.ProductItemResponse{},
		Accessory:  []types.ProductItemResponse{},
	}

	for _, product := range products {
		err = s.appendToProductResponse(response, product)
		if err != nil {
			return nil, fmt.Errorf("failed to transform product %d: %w", product.ProductID, err)
		}
	}

	return response, nil
}

// GetPricesByProductID retrieves prices for a product by product ID, optionally filtered by currency and variant
func (s *Service) GetPricesByProductID(ctx context.Context, productID int, currency, variant string) (*types.PriceResponse, error) {
	// Build query conditions
	queryMods := []qm.QueryMod{
		models.ProductPriceWhere.ProductID.EQ(productID),
	}

	// Add currency filter if provided
	if currency != "" {
		queryMods = append(queryMods, models.ProductPriceWhere.Currency.EQ(currency))
	}

	// Add variant filter if provided
	if variant != "" {
		queryMods = append(queryMods, models.ProductPriceWhere.Variant.EQ(null.StringFrom(variant)))
	}

	// Order by currency and variant for consistent results
	queryMods = append(queryMods, qm.OrderBy(models.ProductPriceColumns.Currency))
	queryMods = append(queryMods, qm.OrderBy(models.ProductPriceColumns.Variant))

	// Query using SQLBoiler
	prices, err := models.ProductPrices(queryMods...).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to query prices for product %d: %w", productID, err)
	}

	// Check if any prices were found
	if len(prices) == 0 {
		return nil, errorspkg.ErrNoPricesFound
	}

	// Transform to API response format
	priceDetails := make([]types.PriceDetail, 0, len(prices))
	for _, price := range prices {
		priceFloat, _ := price.Price.Float64()

		priceDetail := types.PriceDetail{
			Currency: price.Currency,
			Price:    priceFloat,
		}

		// Add variant if it exists
		if price.Variant.Valid && price.Variant.String != "" {
			priceDetail.Variant = price.Variant.String
		}

		priceDetails = append(priceDetails, priceDetail)
	}

	// Get the latest sync version for price data
	version, err := s.GetLatestSyncVersion(ctx, "price")
	if err != nil {
		// If we can't get the version, log a warning but continue
		// This ensures the API doesn't fail completely if version lookup fails
		version = "unknown"
	}

	response := &types.PriceResponse{
		Version:   version,
		ProductID: productID,
		Prices:    priceDetails,
	}

	return response, nil
}

// transformToSingleProductResponse transforms a SQLBoiler Product model to SingleProductResponse
func (s *Service) transformToSingleProductResponse(product *models.Product, version string) (*types.SingleProductResponse, error) {
	// Parse images JSON
	var imagesData interface{}
	if product.Images.Valid {
		var jsonData interface{}
		if err := json.Unmarshal(product.Images.JSON, &jsonData); err != nil {
			imagesData = []map[string]interface{}{{"black": []string{"default.jpg"}}}
		} else {
			imagesData = jsonData
		}
	} else {
		imagesData = []map[string]interface{}{{"black": []string{"default.jpg"}}}
	}

	// Parse specifications JSON
	var specs interface{}
	if product.Specifications.Valid {
		var jsonData interface{}
		if err := json.Unmarshal(product.Specifications.JSON, &jsonData); err != nil {
			specs = make(map[string]interface{})
		} else {
			specs = jsonData
		}
	} else {
		specs = make(map[string]interface{})
	}

	// Get model_family and description
	modelFamily := ""
	if product.ModelFamily.Valid {
		modelFamily = product.ModelFamily.String
	}

	description := ""
	if product.Description.Valid {
		description = product.Description.String
	}

	switch product.ProductType {
	case "speaker":
		return &types.SingleProductResponse{
			Version: version,
			Speaker: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	case "amplifier":
		return &types.SingleProductResponse{
			Version: version,
			Amplifier: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	case "dsp":
		return &types.SingleProductResponse{
			Version: version,
			DSP: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	case "controller":
		return &types.SingleProductResponse{
			Version: version,
			Controller: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	case "io_endpoint":
		return &types.SingleProductResponse{
			Version: version,
			IOEndpoint: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	case "accessory":
		return &types.SingleProductResponse{
			Version: version,
			Accessory: &types.ProductItemResponse{
				ProductID:      product.ProductID,
				Assets:         imagesData,
				ModelName:      product.ModelName,
				ModelFamily:    modelFamily,
				Description:    description,
				Specifications: specs,
			},
		}, nil

	default:
		return nil, fmt.Errorf("unknown product type: %s", product.ProductType)
	}
}

// appendToProductResponse adds a product to the appropriate slice in ProductResponse
func (s *Service) appendToProductResponse(response *types.ProductResponse, product *models.Product) error {
	// Parse images JSON
	var imagesData interface{}
	if product.Images.Valid {
		var jsonData interface{}
		if err := json.Unmarshal(product.Images.JSON, &jsonData); err != nil {
			imagesData = []map[string]interface{}{{"black": []string{"default.jpg"}}}
		} else {
			imagesData = jsonData
		}
	} else {
		imagesData = []map[string]interface{}{{"black": []string{"default.jpg"}}}
	}

	// Parse specifications JSON
	var specs interface{}
	if product.Specifications.Valid {
		var jsonData interface{}
		if err := json.Unmarshal(product.Specifications.JSON, &jsonData); err != nil {
			specs = make(map[string]interface{})
		} else {
			specs = jsonData
		}
	} else {
		specs = make(map[string]interface{})
	}

	// Get model_family and description
	modelFamily := ""
	if product.ModelFamily.Valid {
		modelFamily = product.ModelFamily.String
	}

	description := ""
	if product.Description.Valid {
		description = product.Description.String
	}

	switch product.ProductType {
	case "speaker":
		speaker := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.Speaker = append(response.Speaker, speaker)

	case "amplifier":
		amplifier := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.Amplifier = append(response.Amplifier, amplifier)

	case "dsp":
		dsp := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.DSP = append(response.DSP, dsp)

	case "controller":
		controller := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.Controller = append(response.Controller, controller)

	case "io_endpoint":
		ioEndpoint := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.IOEndpoint = append(response.IOEndpoint, ioEndpoint)

	case "accessory":
		accessory := types.ProductItemResponse{
			ProductID:      product.ProductID,
			Assets:         imagesData,
			ModelName:      product.ModelName,
			ModelFamily:    modelFamily,
			Description:    description,
			Specifications: specs,
		}
		response.Accessory = append(response.Accessory, accessory)

	default:
		return fmt.Errorf("unknown product type: %s", product.ProductType)
	}

	return nil
}

// GetLatestSyncVersion retrieves the latest successful sync version for a given sync type
func (s *Service) GetLatestSyncVersion(ctx context.Context, syncType string) (string, error) {
	// Query the latest successful sync job for the given type
	job, err := models.ProductSyncJobs(
		models.ProductSyncJobWhere.SyncType.EQ(null.StringFrom(syncType)),
		models.ProductSyncJobWhere.Status.EQ("completed"),
		qm.OrderBy("completed_at DESC"),
		qm.Limit(1),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			return "", fmt.Errorf("no successful sync found for type: %s", syncType)
		}
		return "", fmt.Errorf("failed to get latest sync version: %w", err)
	}

	// Return the version if available
	if job.Version.Valid {
		return job.Version.String, nil
	}

	return "", fmt.Errorf("no version information found in sync job")
}
