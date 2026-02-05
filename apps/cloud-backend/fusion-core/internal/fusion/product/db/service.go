package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	sqltypes "github.com/aarondl/sqlboiler/v4/types"
	"github.com/ericlagergren/decimal"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Service is a service for managing products using SQLBoiler ORM.
type Service struct {
	db     *sql.DB
	logger *zap.Logger
}

// NewService creates a new database service.
func NewService(db *sql.DB, logger *zap.Logger) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db:     db,
		logger: logger,
	}
}

// ============================================================================
// CORE PRODUCT OPERATIONS
// ============================================================================

// SelectByID retrieves a product by ID using SQLBoiler.
func (s *Service) SelectByID(ctx context.Context, id string, version string, logger *zap.Logger) (*types.SingleProductResponse, error) {
	// Convert id string to int
	productID, err := strconv.Atoi(id)
	if err != nil {
		logger.Error("invalid product ID", zap.String("id", id), zap.Error(err))
		return nil, fmt.Errorf("invalid product ID: %w", err)
	}

	// Query using SQLBoiler
	product, err := models.Products(
		models.ProductWhere.ProductID.EQ(productID),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errorutil.ErrProductNotFound
		}
		logger.Error("failed to get product by ID", zap.Int("product_id", productID), zap.Error(err))
		return nil, fmt.Errorf("failed to get product: %w", err)
	}
	logger.Info("retrieved product by ID", zap.Int("product_id", productID))
	// Transform to API response format
	return s.transformToSingleProductResponse(product, version, logger)
}

// SelectAll retrieves all products using SQLBoiler.
func (s *Service) SelectAll(ctx context.Context, version string, logger *zap.Logger) (*types.ProductResponse, error) {
	// Query all products using SQLBoiler
	products, err := models.Products(
		qm.OrderBy(models.ProductColumns.ProductID),
	).All(ctx, s.db)

	if err != nil {
		logger.Error("failed to query products", zap.Error(err))
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
		err = s.appendToProductResponse(response, product, logger)
		if err != nil {
			logger.Error("failed to transform product", zap.Int("product_id", product.ProductID), zap.Error(err))
			return nil, fmt.Errorf("failed to transform product %d: %w", product.ProductID, err)
		}
	}
	logger.Info("retrieved all products", zap.Int("count", len(products)))
	return response, nil
}

// ============================================================================
// PRICING OPERATIONS
// ============================================================================

// GetPricesByProductID retrieves prices for a product by product ID, optionally filtered by currency and variant
func (s *Service) GetPricesByProductID(ctx context.Context, productID int, currency, variant string, logger *zap.Logger) (*types.PriceResponse, error) {
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
		logger.Error("failed to query prices", zap.Int("product_id", productID), zap.Error(err))
		return nil, fmt.Errorf("failed to query prices for product %d: %w", productID, err)
	}

	// Check if any prices were found
	if len(prices) == 0 {
		return nil, errorutil.ErrNoPricesFound
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
	version, err := s.GetLatestSyncVersion(ctx, "price", logger)
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
	logger.Info("retrieved prices for product", zap.Int("product_id", productID), zap.Int("price_count", len(priceDetails)))
	return response, nil
}

// ============================================================================
// SYNC OPERATIONS
// ============================================================================

// GetLatestSyncVersion retrieves the latest successful sync version for a given sync type
func (s *Service) GetLatestSyncVersion(ctx context.Context, syncType string, logger *zap.Logger) (string, error) {
	// Query the latest successful sync job for the given type
	job, err := models.ProductSyncJobs(
		models.ProductSyncJobWhere.SyncType.EQ(null.StringFrom(syncType)),
		models.ProductSyncJobWhere.Status.EQ("completed"),
		qm.OrderBy("completed_at DESC"),
		qm.Limit(1),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			logger.Warn("no successful sync found", zap.String("sync_type", syncType))
			return "", fmt.Errorf("no successful sync found for type: %s", syncType)
		}
		logger.Error("failed to get latest sync version", zap.String("sync_type", syncType), zap.Error(err))
		return "", fmt.Errorf("failed to get latest sync version: %w", err)
	}

	// Return the version if available
	if job.Version != "" {
		logger.Info("retrieved latest sync version", zap.String("sync_type", syncType), zap.String("version", job.Version))
		return job.Version, nil
	}
	logger.Warn("no version information found in sync job", zap.String("sync_type", syncType))
	return "", fmt.Errorf("no version information found in sync job")
}

// ============================================================================
// TRANSFORMATION HELPERS
// ============================================================================

// transformToSingleProductResponse transforms a SQLBoiler Product model to SingleProductResponse
func (s *Service) transformToSingleProductResponse(product *models.Product, version string, logger *zap.Logger) (*types.SingleProductResponse, error) {
	// Parse images JSON
	var imagesData interface{}
	if product.Images.Valid {
		var jsonData interface{}
		if err := json.Unmarshal(product.Images.JSON, &jsonData); err != nil {
			imagesData = []map[string]interface{}{{"black": []string{""}}}
		} else {
			imagesData = jsonData
		}
	} else {
		imagesData = []map[string]interface{}{{"black": []string{""}}}
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
		logger.Error("unknown product type", zap.String("product_type", product.ProductType))
		return nil, fmt.Errorf("unknown product type: %s", product.ProductType)
	}
}

// appendToProductResponse adds a product to the appropriate slice in ProductResponse
func (s *Service) appendToProductResponse(response *types.ProductResponse, product *models.Product, logger *zap.Logger) error {
	itemResponse := s.buildProductItemResponse(product, logger)

	switch product.ProductType {
	case "speaker":
		response.Speaker = append(response.Speaker, *itemResponse)
	case "amplifier":
		response.Amplifier = append(response.Amplifier, *itemResponse)
	case "dsp":
		response.DSP = append(response.DSP, *itemResponse)
	case "controller":
		response.Controller = append(response.Controller, *itemResponse)
	case "io_endpoint":
		response.IOEndpoint = append(response.IOEndpoint, *itemResponse)
	case "accessory":
		response.Accessory = append(response.Accessory, *itemResponse)
	default:
		logger.Error("unknown product type", zap.String("product_type", product.ProductType))
		return fmt.Errorf("unknown product type: %s", product.ProductType)
	}
	logger.Info("appended product to response", zap.Int("product_id", product.ProductID), zap.String("product_type", product.ProductType))
	return nil
}

// buildProductItemResponse creates a ProductItemResponse from a SQLBoiler model
func (s *Service) buildProductItemResponse(product *models.Product, logger *zap.Logger) *types.ProductItemResponse {
	imagesData := s.parseJSONField(product.Images, []map[string]interface{}{{"black": []string{""}}}, logger)
	specs := s.parseJSONField(product.Specifications, make(map[string]interface{}), logger)
	logger.Info("built product item response", zap.Int("product_id", product.ProductID))
	return &types.ProductItemResponse{
		ProductID:          product.ProductID,
		Assets:             imagesData,
		ModelName:          product.ModelName,
		ModelFamily:        s.getStringValue(product.ModelFamily, logger),
		Description:        s.getStringValue(product.Description, logger),
		Specifications:     specs,
		IsFusionCompatible: s.getBoolValue(product.IsFusionCompatible, logger),
	}
}

// parseJSONField safely parses a null JSON field with fallback
func (s *Service) parseJSONField(field null.JSON, fallback interface{}, logger *zap.Logger) interface{} {
	if !field.Valid {
		logger.Info("JSON field is null, using fallback")
		return fallback
	}

	var jsonData interface{}
	if err := json.Unmarshal(field.JSON, &jsonData); err != nil {
		logger.Warn("failed to unmarshal JSON field, using fallback", zap.Error(err))
		return fallback
	}
	logger.Info("successfully parsed JSON field")
	return jsonData
}

// getStringValue safely extracts string from null.String
func (s *Service) getStringValue(field null.String, logger *zap.Logger) string {
	if field.Valid {
		logger.Info("extracted string value from null.String")
		return field.String
	}
	logger.Info("null.String is invalid, returning empty string")
	return ""
}

// getBoolValue safely extracts bool from null.Bool
func (s *Service) getBoolValue(field null.Bool, logger *zap.Logger) bool {
	if field.Valid {
		logger.Info("extracted bool value from null.Bool")
		return field.Bool
	}
	logger.Info("null.Bool is invalid, returning false")
	return false
}

// ============================================================================
// SYNC OPERATIONS - Product Operations
// ============================================================================

// Insert inserts a single product into the database
func (s *Service) Insert(ctx context.Context, product *types.DBProduct, logger *zap.Logger) error {
	logger.Info("inserting product", zap.Int("product_id", product.ProductID))
	return s.insertProduct(ctx, s.db, product, logger)
}

// Upsert inserts or updates a single product in the database
func (s *Service) Upsert(ctx context.Context, product *types.DBProduct, logger *zap.Logger) error {
	logger.Info("upserting product", zap.Int("product_id", product.ProductID))
	return s.insertProduct(ctx, s.db, product, logger)
}

// InsertBatch inserts multiple products within a single transaction
func (s *Service) InsertBatch(ctx context.Context, products []*types.DBProduct, logger *zap.Logger) error {
	if len(products) == 0 {
		logger.Info("no products to insert in batch")
		return nil
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		logger.Error("failed to begin transaction for batch insert", zap.Error(err))
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, product := range products {
		if err := s.insertProduct(ctx, tx, product, logger); err != nil {
			logger.Error("failed to insert product in batch", zap.Int("product_id", product.ProductID), zap.Error(err))
			return err
		}
	}
	logger.Info("successfully inserted batch of products", zap.Int("count", len(products)))
	return tx.Commit()
}

// InsertWithRetry inserts a product with retry logic
func (s *Service) InsertWithRetry(ctx context.Context, product *types.DBProduct, maxRetries int, retryDelay time.Duration, logger *zap.Logger) error {
	var lastErr error
	for i := 0; i <= maxRetries; i++ {
		err := s.Insert(ctx, product, logger)
		if err == nil {
			logger.Info("successfully inserted product with retry", zap.Int("product_id", product.ProductID), zap.Int("attempt", i+1))
			return nil
		}
		lastErr = err

		if i < maxRetries {
			time.Sleep(retryDelay)
		}
	}
	logger.Error("failed to insert product after retries", zap.Int("product_id", product.ProductID), zap.Int("max_retries", maxRetries), zap.Error(lastErr))
	return lastErr
}

// LookupProductIDBySKU looks up a product ID by SKU
func (s *Service) LookupProductIDBySKU(ctx context.Context, sku int, logger *zap.Logger) (int, bool, error) {
	product, err := models.Products(qm.Where("product_id = ?", sku)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		logger.Info("product not found by SKU", zap.Int("sku", sku))
		return 0, false, nil
	}
	if err != nil {
		logger.Error("failed to lookup product by SKU", zap.Int("sku", sku), zap.Error(err))
		return 0, false, err
	}
	logger.Info("found product by SKU", zap.Int("sku", sku), zap.Int("product_id", product.ProductID))
	return product.ProductID, true, nil
}

// BatchLookupExistingProductIDs checks which product IDs exist in the database
// Returns a set (map) of existing product IDs for O(1) lookups
func (s *Service) BatchLookupExistingProductIDs(ctx context.Context, productIDs []int, logger *zap.Logger) (map[int]bool, error) {
	result := make(map[int]bool)

	if len(productIDs) == 0 {
		logger.Info("no product IDs provided for batch lookup")
		return result, nil
	}

	// De-duplicate product IDs
	uniqueIDs := make(map[int]bool)
	for _, id := range productIDs {
		uniqueIDs[id] = true
	}

	// Convert to slice for query
	ids := make([]int, 0, len(uniqueIDs))
	for id := range uniqueIDs {
		ids = append(ids, id)
	}

	// Process in batches of 500 to avoid query size limits
	const batchSize = 500

	for i := 0; i < len(ids); i += batchSize {
		end := i + batchSize
		if end > len(ids) {
			end = len(ids)
		}
		batch := ids[i:end]

		// Build placeholders for IN clause
		placeholders := make([]string, len(batch))
		args := make([]interface{}, len(batch))
		for j, id := range batch {
			placeholders[j] = fmt.Sprintf("$%d", j+1)
			args[j] = id
		}

		query := fmt.Sprintf("SELECT product_id FROM product WHERE product_id IN (%s)", strings.Join(placeholders, ","))

		rows, err := s.db.QueryContext(ctx, query, args...)
		if err != nil {
			logger.Error("failed to batch lookup product IDs", zap.Error(err))
			return nil, fmt.Errorf("failed to batch lookup product IDs: %w", err)
		}

		for rows.Next() {
			var productID int
			if err := rows.Scan(&productID); err != nil {
				rows.Close()
				logger.Error("failed to scan product ID during batch lookup", zap.Error(err))
				return nil, fmt.Errorf("failed to scan product ID: %w", err)
			}
			result[productID] = true
		}
		rows.Close()

		if err := rows.Err(); err != nil {
			logger.Error("error iterating product IDs during batch lookup", zap.Error(err))
			return nil, fmt.Errorf("error iterating product IDs: %w", err)
		}
	}
	logger.Info("completed batch lookup of product IDs", zap.Int("requested_count", len(productIDs)), zap.Int("found_count", len(result)))
	return result, nil
}

// GetProductTimestamps retrieves updated_at timestamps for multiple products
func (s *Service) GetProductTimestamps(ctx context.Context, productIDs []int, logger *zap.Logger) (map[int]*int64, error) {
	if len(productIDs) == 0 {
		logger.Info("no product IDs provided for timestamp retrieval")
		return make(map[int]*int64), nil
	}

	// Build placeholders for IN clause
	placeholders := make([]string, len(productIDs))
	args := make([]interface{}, len(productIDs))
	for i, id := range productIDs {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = id
	}

	query := fmt.Sprintf("SELECT product_id, updated_at FROM product WHERE product_id IN (%s)", strings.Join(placeholders, ","))

	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		logger.Error("failed to query product timestamps", zap.Error(err))
		return nil, fmt.Errorf("failed to query product timestamps: %w", err)
	}
	defer rows.Close()

	result := make(map[int]*int64)
	for rows.Next() {
		var productID int
		var updatedAt null.Time

		if err := rows.Scan(&productID, &updatedAt); err != nil {
			logger.Error("failed to scan product timestamp", zap.Error(err))
			return nil, fmt.Errorf("failed to scan product timestamp: %w", err)
		}

		if updatedAt.Valid {
			epoch := updatedAt.Time.Unix()
			result[productID] = &epoch
		} else {
			result[productID] = nil
		}
	}

	if err := rows.Err(); err != nil {
		logger.Error("error iterating product timestamp rows", zap.Error(err))
		return nil, fmt.Errorf("error iterating product timestamp rows: %w", err)
	}
	logger.Info("retrieved product timestamps", zap.Int("count", len(result)))
	return result, nil
}

// GetExistingProduct retrieves an existing product by product ID
func (s *Service) GetExistingProduct(ctx context.Context, productID int, logger *zap.Logger) (*types.DBProduct, error) {
	product, err := models.Products(qm.Where("product_id = ?", productID)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		logger.Info("product does not exist", zap.Int("product_id", productID))
		return nil, nil // Product doesn't exist
	}
	if err != nil {
		logger.Error("failed to get product", zap.Int("product_id", productID), zap.Error(err))
		return nil, fmt.Errorf("failed to get product %d: %w", productID, err)
	}

	// Convert model to DBProduct
	dbProduct := &types.DBProduct{
		ProductID:        product.ProductID,
		ProductType:      product.ProductType,
		ModelName:        product.ModelName,
		ModelFamily:      product.ModelFamily.String,
		ShortDescription: product.ShortDescription.String,
		Description:      product.Description.String,
	}

	// Handle JSON fields
	if product.Images.Valid {
		dbProduct.Images = string(product.Images.JSON)
	}
	if product.Specifications.Valid {
		dbProduct.Specifications = string(product.Specifications.JSON)
	}

	// Handle timestamps
	if product.CreatedAt.Valid {
		createdStr := product.CreatedAt.Time.Format(time.RFC3339)
		dbProduct.CreatedAt = &createdStr
	}
	if product.UpdatedAt.Valid {
		updatedStr := product.UpdatedAt.Time.Format(time.RFC3339)
		dbProduct.UpdatedAt = &updatedStr
	}
	logger.Info("retrieved existing product", zap.Int("product_id", productID))
	return dbProduct, nil
}

// ============================================================================
// SYNC OPERATIONS - Price Operations
// ============================================================================

// UpsertPrice inserts or updates a price record
func (s *Service) UpsertPrice(ctx context.Context, price *types.DBPrice, logger *zap.Logger) error {
	logger.Info("upserting price", zap.Int("product_id", price.ProductID), zap.String("currency", price.Currency))
	return s.upsertPrice(ctx, s.db, price, logger)
}

// UpsertBatch inserts or updates multiple price records within a single transaction
func (s *Service) UpsertBatch(ctx context.Context, prices []*types.DBPrice, logger *zap.Logger) error {
	if len(prices) == 0 {
		logger.Info("no prices to upsert in batch")
		return nil
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		logger.Error("failed to begin transaction for batch upsert", zap.Error(err))
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, price := range prices {
		if err := s.upsertPrice(ctx, tx, price, logger); err != nil {
			logger.Error("failed to upsert price in batch", zap.Int("product_id", price.ProductID), zap.String("currency", price.Currency), zap.Error(err))
			return err
		}
	}
	logger.Info("successfully upserted batch of prices", zap.Int("count", len(prices)))
	return tx.Commit()
}

// InsertPriceBatch inserts multiple new price records using a single bulk INSERT statement
// Uses ON CONFLICT DO UPDATE to handle existing prices (upsert behavior)
func (s *Service) InsertPriceBatch(ctx context.Context, prices []*types.DBPrice, logger *zap.Logger) error {
	if len(prices) == 0 {
		logger.Info("no prices to insert in batch")
		return nil
	}

	// Process in smaller batches to avoid query size limits
	const batchSize = 100

	for i := 0; i < len(prices); i += batchSize {
		end := i + batchSize
		if end > len(prices) {
			end = len(prices)
		}
		batch := prices[i:end]

		if err := s.bulkInsertPrices(ctx, batch, logger); err != nil {
			logger.Error("failed to bulk insert prices", zap.Int("batch_size", len(batch)), zap.Error(err))
			return err
		}
	}
	logger.Info("successfully inserted batch of prices", zap.Int("total_count", len(prices)))
	return nil
}

// bulkInsertPrices inserts a batch of prices using a single SQL statement
// Since there's no unique constraint, we use DELETE + INSERT pattern
func (s *Service) bulkInsertPrices(ctx context.Context, prices []*types.DBPrice, logger *zap.Logger) error {
	if len(prices) == 0 {
		logger.Info("no prices to bulk insert")
		return nil
	}

	// Start a transaction for atomicity
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		logger.Error("failed to begin transaction for bulk insert", zap.Error(err))
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Build DELETE statement to remove existing prices for these product/currency/variant combinations
	// Then INSERT new prices
	var deleteConditions []string
	var deleteArgs []interface{}
	argIndex := 1

	for _, price := range prices {
		var variantCondition string
		if price.Variant != nil && *price.Variant != "" {
			variantCondition = fmt.Sprintf("(product_id = $%d AND currency = $%d AND variant = $%d)", argIndex, argIndex+1, argIndex+2)
			deleteArgs = append(deleteArgs, price.ProductID, price.Currency, *price.Variant)
			argIndex += 3
		} else {
			variantCondition = fmt.Sprintf("(product_id = $%d AND currency = $%d AND variant IS NULL)", argIndex, argIndex+1)
			deleteArgs = append(deleteArgs, price.ProductID, price.Currency)
			argIndex += 2
		}
		deleteConditions = append(deleteConditions, variantCondition)
	}

	// Delete existing prices
	deleteQuery := fmt.Sprintf("DELETE FROM product_price WHERE %s", strings.Join(deleteConditions, " OR "))
	_, err = tx.ExecContext(ctx, deleteQuery, deleteArgs...)
	if err != nil {
		logger.Error("failed to delete existing prices before bulk insert", zap.Error(err))
		return fmt.Errorf("failed to delete existing prices: %w", err)
	}

	// Build bulk INSERT statement
	var valueStrings []string
	var insertArgs []interface{}
	insertArgIndex := 1

	for _, price := range prices {
		var variantVal interface{}
		if price.Variant != nil && *price.Variant != "" {
			variantVal = *price.Variant
		} else {
			variantVal = nil
		}

		valueStrings = append(valueStrings, fmt.Sprintf("($%d, $%d, $%d, $%d, NOW(), NOW())", insertArgIndex, insertArgIndex+1, insertArgIndex+2, insertArgIndex+3))
		insertArgs = append(insertArgs, price.ProductID, variantVal, price.Currency, price.Amount)
		insertArgIndex += 4
	}

	insertQuery := fmt.Sprintf(`
		INSERT INTO product_price (product_id, variant, currency, price, created_at, updated_at)
		VALUES %s
	`, strings.Join(valueStrings, ", "))

	_, err = tx.ExecContext(ctx, insertQuery, insertArgs...)
	if err != nil {
		logger.Error("failed to bulk insert prices", zap.Error(err))
		return fmt.Errorf("failed to bulk insert prices: %w", err)
	}
	logger.Info("successfully bulk inserted prices", zap.Int("count", len(prices)))
	return tx.Commit()
}

// GetPriceByProductID retrieves a price by product ID (implements the interface requirement)
func (s *Service) GetPriceByProductID(ctx context.Context, productID int, logger *zap.Logger) (*types.DBPrice, error) {
	price, err := models.ProductPrices(qm.Where("product_id = ?", productID)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		logger.Info("price does not exist for product", zap.Int("product_id", productID))
		return nil, nil // Price doesn't exist
	}
	if err != nil {
		logger.Error("failed to get price for product", zap.Int("product_id", productID), zap.Error(err))
		return nil, fmt.Errorf("failed to get price for product %d: %w", productID, err)
	}

	// Convert to DBPrice
	priceFloat, _ := price.Price.Float64()
	dbPrice := &types.DBPrice{
		ProductID: price.ProductID,
		Currency:  price.Currency,
		Amount:    priceFloat,
	}

	if price.Variant.Valid {
		variantStr := price.Variant.String
		dbPrice.Variant = &variantStr
	}
	logger.Info("retrieved price for product", zap.Int("product_id", productID))
	return dbPrice, nil
}

// GetPriceTimestamps retrieves updated_at timestamps for multiple prices using batch queries
// This is optimized to avoid N+1 query problem by fetching all prices in batches
func (s *Service) GetPriceTimestamps(ctx context.Context, priceKeys []types.PriceKey, logger *zap.Logger) (map[types.PriceKey]*int64, error) {
	result := make(map[types.PriceKey]*int64)

	if len(priceKeys) == 0 {
		logger.Info("no price keys provided for timestamp retrieval")
		return result, nil
	}

	// Process in batches of 500 to avoid query size limits
	const batchSize = 500

	for i := 0; i < len(priceKeys); i += batchSize {
		end := i + batchSize
		if end > len(priceKeys) {
			end = len(priceKeys)
		}
		batch := priceKeys[i:end]

		// Build a single batch query using UNION ALL for each price key
		// This allows us to fetch all timestamps in one round trip
		var queryParts []string
		var args []interface{}
		argIndex := 1

		for _, key := range batch {
			var part string
			if key.Variant == "" {
				part = fmt.Sprintf(
					"SELECT $%d::int as product_id, $%d::text as currency, ''::text as variant, updated_at FROM product_price WHERE product_id = $%d AND currency = $%d AND variant IS NULL",
					argIndex, argIndex+1, argIndex, argIndex+1,
				)
				args = append(args, key.ProductID, key.Currency)
				argIndex += 2
			} else {
				part = fmt.Sprintf(
					"SELECT $%d::int as product_id, $%d::text as currency, $%d::text as variant, updated_at FROM product_price WHERE product_id = $%d AND currency = $%d AND variant = $%d",
					argIndex, argIndex+1, argIndex+2, argIndex, argIndex+1, argIndex+2,
				)
				args = append(args, key.ProductID, key.Currency, key.Variant)
				argIndex += 3
			}
			queryParts = append(queryParts, part)
		}

		query := strings.Join(queryParts, " UNION ALL ")

		rows, err := s.db.QueryContext(ctx, query, args...)
		if err != nil {
			logger.Error("failed to batch query price timestamps", zap.Error(err))
			return nil, fmt.Errorf("failed to batch query price timestamps: %w", err)
		}

		for rows.Next() {
			var productID int
			var currency string
			var variant string
			var updatedAt null.Time

			if err := rows.Scan(&productID, &currency, &variant, &updatedAt); err != nil {
				rows.Close()
				logger.Error("failed to scan price timestamp", zap.Error(err))
				return nil, fmt.Errorf("failed to scan price timestamp: %w", err)
			}

			key := types.PriceKey{
				ProductID: productID,
				Currency:  currency,
				Variant:   variant,
			}

			if updatedAt.Valid {
				epoch := updatedAt.Time.Unix()
				result[key] = &epoch
			} else {
				result[key] = nil
			}
		}
		rows.Close()

		if err := rows.Err(); err != nil {
			logger.Error("error iterating price timestamp rows", zap.Error(err))
			return nil, fmt.Errorf("error iterating price timestamp rows: %w", err)
		}
	}
	logger.Info("retrieved price timestamps", zap.Int("count", len(result)))
	// Keys not found in DB will not be in result map - caller handles this as nil
	return result, nil
}

// ============================================================================
// SYNC OPERATIONS - Job Operations
// ============================================================================

// Create creates a new sync job and returns the job ID
func (s *Service) Create(ctx context.Context, syncOperation, syncType, version, sourcePath, s3Bucket, s3Key string, logger *zap.Logger) (string, error) {
	jobID := uuid.New().String()

	// Use a default sync operation if empty
	if syncOperation == "" {
		syncOperation = "manual_sync"
	}

	// Handle required S3 fields for local files by providing defaults
	if s3Bucket == "" {
		s3Bucket = "local-file" // Default value for local files
	}
	if s3Key == "" {
		// Use the source path as s3_key for local files, or a default
		if sourcePath != "" {
			s3Key = sourcePath
		} else {
			s3Key = "local-source"
		}
	}

	job := &models.ProductSyncJob{
		JobID:         jobID,
		SyncOperation: syncOperation,
		SyncType:      null.NewString(syncType, syncType != ""),
		Status:        "pending",
		Version:       version,
		S3Bucket:      s3Bucket,
		S3Key:         s3Key,
		CreatedAt:     null.TimeFrom(time.Now()),
	}

	err := job.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		logger.Error("failed to create sync job", zap.Error(err))
		return "", fmt.Errorf("failed to create sync job: %w", err)
	}
	logger.Info("created new sync job", zap.String("job_id", jobID), zap.String("sync_type", syncType))
	return jobID, nil
}

// UpdateStatus updates the status of a sync job
func (s *Service) UpdateStatus(ctx context.Context, jobID, status string, startedAt *time.Time, errorMsg *string, logger *zap.Logger) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
		logger.Error("failed to find sync job for status update", zap.String("job_id", jobID), zap.Error(err))
		return fmt.Errorf("failed to find job %s: %w", jobID, err)
	}

	job.Status = status
	if startedAt != nil {
		job.StartedAt = null.TimeFrom(*startedAt)
	}
	if errorMsg != nil {
		job.ErrorMessage = null.StringFrom(*errorMsg)
	}
	if status == "completed" || status == "failed" {
		job.CompletedAt = null.TimeFrom(time.Now())
	}

	_, err = job.Update(ctx, s.db, boil.Infer())
	logger.Info("updated sync job status", zap.String("job_id", jobID), zap.String("status", status))
	return err
}

// UpdateWithResults updates a job with processing results
func (s *Service) UpdateWithResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string, logger *zap.Logger) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
		logger.Error("failed to find sync job for results update", zap.String("job_id", jobID), zap.Error(err))
		return fmt.Errorf("failed to find job %s: %w", jobID, err)
	}

	job.Status = status
	job.TotalItems = null.IntFrom(totalItems)
	job.SuccessfulItems = null.IntFrom(successful)
	job.FailedItems = null.IntFrom(failed)

	// Store validation warnings in the validation_errors JSONB field with structured data
	if len(validationWarnings) > 0 {
		validationData := map[string]interface{}{
			"type":           "warnings",
			"warnings":       validationWarnings,
			"total_warnings": len(validationWarnings),
			"timestamp":      time.Now().UTC(),
			"source":         "sync_process",
		}
		if validationJSON, err := json.Marshal(validationData); err == nil {
			job.ValidationErrors = null.JSONFrom(validationJSON)
		}
	}

	if errorMsg != nil {
		job.ErrorMessage = null.StringFrom(*errorMsg)
	}

	if status == "completed" || status == "failed" {
		job.CompletedAt = null.TimeFrom(time.Now())
	}

	_, err = job.Update(ctx, s.db, boil.Infer())
	logger.Info("updated sync job with results", zap.String("job_id", jobID), zap.String("status", status))
	return err
}

// UpdateStatusAndResults updates job status and results atomically
func (s *Service) UpdateStatusAndResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string, logger *zap.Logger) error {
	logger.Info("updating sync job status and results", zap.String("job_id", jobID), zap.String("status", status))
	return s.UpdateWithResults(ctx, jobID, status, totalItems, successful, failed, validationWarnings, errorMsg, logger)
}

// GetByID retrieves a sync job result by ID
func (s *Service) GetByID(ctx context.Context, jobID string, logger *zap.Logger) (*types.SyncJobResult, error) {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
		logger.Error("failed to find sync job by ID", zap.String("job_id", jobID), zap.Error(err))
		return nil, fmt.Errorf("failed to find job %s: %w", jobID, err)
	}

	result := &types.SyncJobResult{
		JobID:     job.JobID,
		Status:    types.SyncStatus(job.Status),
		CreatedAt: job.CreatedAt.Time,
	}

	if job.StartedAt.Valid {
		result.StartedAt = &job.StartedAt.Time
	}
	if job.CompletedAt.Valid {
		result.CompletedAt = &job.CompletedAt.Time
	}
	if job.TotalItems.Valid {
		total := job.TotalItems.Int
		result.TotalItems = &total
	}
	if job.SuccessfulItems.Valid {
		success := job.SuccessfulItems.Int
		result.SuccessfulItems = &success
	}
	if job.FailedItems.Valid {
		failed := job.FailedItems.Int
		result.FailedItems = &failed
	}
	logger.Info("retrieved sync job by ID", zap.String("job_id", jobID))
	return result, nil
}

// StoreValidationErrors stores validation errors for a job
func (s *Service) StoreValidationErrors(ctx context.Context, jobID string, errorCollector *errorutil.ErrorCollector, logger *zap.Logger) error {
	if errorCollector == nil {
		logger.Info("no error collector provided, skipping storing validation errors", zap.String("job_id", jobID))
		return nil
	}

	summary := errorCollector.GetSummary()
	if summary.TotalErrors == 0 {
		logger.Info("no validation errors to store", zap.String("job_id", jobID))
		return nil
	}

	// Store errors in job record with structured data to distinguish from warnings
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
		logger.Error("failed to find sync job for storing validation errors", zap.String("job_id", jobID), zap.Error(err))
		return fmt.Errorf("failed to find job %s: %w", jobID, err)
	}

	// Create structured error data
	errorData := map[string]interface{}{
		"type":         "errors",
		"errors":       errorCollector.GetAllErrors(),
		"summary":      summary,
		"total_errors": summary.TotalErrors,
		"timestamp":    time.Now().UTC(),
		"source":       "validation_process",
	}

	errorsJSON, err := json.Marshal(errorData)
	if err != nil {
		logger.Error("failed to marshal validation errors", zap.String("job_id", jobID), zap.Error(err))
		return fmt.Errorf("failed to marshal errors: %w", err)
	}

	job.ValidationErrors = null.JSONFrom(errorsJSON)
	_, err = job.Update(ctx, s.db, boil.Infer())
	logger.Info("stored validation errors for sync job", zap.String("job_id", jobID))
	return err
}

// StoreValidationData stores both validation warnings and errors in a combined format
func (s *Service) StoreValidationData(ctx context.Context, jobID string, validationWarnings []string, errorCollector *errorutil.ErrorCollector, logger *zap.Logger) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
		logger.Error("failed to find sync job for storing validation data", zap.String("job_id", jobID), zap.Error(err))
		return fmt.Errorf("failed to find job %s: %w", jobID, err)
	}

	// Create combined validation data structure
	validationData := map[string]interface{}{
		"timestamp": time.Now().UTC(),
		"source":    "sync_process",
	}

	// Add warnings if any
	if len(validationWarnings) > 0 {
		validationData["warnings"] = validationWarnings
		validationData["total_warnings"] = len(validationWarnings)
	}

	// Add errors if any
	if errorCollector != nil {
		summary := errorCollector.GetSummary()
		if summary.TotalErrors > 0 {
			validationData["errors"] = errorCollector.GetAllErrors()
			validationData["error_summary"] = summary
			validationData["total_errors"] = summary.TotalErrors
		}
	}

	// Only store if there's actual data
	if len(validationWarnings) > 0 || (errorCollector != nil && errorCollector.GetSummary().TotalErrors > 0) {
		validationJSON, err := json.Marshal(validationData)
		if err != nil {
			logger.Error("failed to marshal validation data", zap.String("job_id", jobID), zap.Error(err))
			return fmt.Errorf("failed to marshal validation data: %w", err)
		}
		job.ValidationErrors = null.JSONFrom(validationJSON)
		_, err = job.Update(ctx, s.db, boil.Infer())
		logger.Info("stored validation data for sync job", zap.String("job_id", jobID))
		return err
	}
	logger.Info("no validation data to store", zap.String("job_id", jobID))
	return nil
}

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

// insertProduct handles the actual product insertion logic
func (s *Service) insertProduct(ctx context.Context, exec boil.ContextExecutor, product *types.DBProduct, logger *zap.Logger) error {
	if product == nil {
		logger.Error("product cannot be nil")
		return fmt.Errorf("product cannot be nil")
	}

	// Convert types.DBProduct to models.Product
	modelProduct := &models.Product{
		ProductID:          product.ProductID,
		ProductType:        product.ProductType,
		ModelName:          product.ModelName,
		ModelFamily:        null.NewString(product.ModelFamily, product.ModelFamily != ""),
		Description:        null.NewString(product.Description, product.Description != ""),
		ShortDescription:   null.NewString(product.ShortDescription, product.ShortDescription != ""),
		IsFusionCompatible: null.NewBool(product.IsFusionCompatible, true),
	}

	// Debug: Log fusion compatibility value
	s.logger.Info("DEBUG: Inserting product with fusion compatibility",
		zap.Int("product_id", product.ProductID),
		zap.Bool("is_fusion_compatible", product.IsFusionCompatible),
		zap.Bool("fusion_compatible_valid", modelProduct.IsFusionCompatible.Valid),
		zap.Bool("fusion_compatible_value", modelProduct.IsFusionCompatible.Bool))

	// Handle JSON fields - convert string to null.JSON
	if product.Images != "" {
		modelProduct.Images = null.JSONFrom([]byte(product.Images))
	}

	if product.Specifications != "" {
		modelProduct.Specifications = null.JSONFrom([]byte(product.Specifications))
	}

	// Use Upsert to handle both insert and update cases
	// Conflict on product_id column, update all fields if conflict occurs
	err := modelProduct.Upsert(
		ctx,
		exec,
		true,                               // updateOnConflict
		[]string{"product_id"},             // conflict columns
		boil.Blacklist("id", "created_at"), // updateColumns - don't update these
		boil.Infer(),                       // insertColumns - infer from struct
	)

	if err != nil {
		logger.Error("failed to upsert product", zap.Int("product_id", product.ProductID), zap.Error(err))
		return fmt.Errorf("failed to upsert product %d: %w", product.ProductID, err)
	}
	logger.Info("successfully upserted product", zap.Int("product_id", product.ProductID))
	return nil
}

// upsertPrice handles the actual price upsert logic
func (s *Service) upsertPrice(ctx context.Context, exec boil.ContextExecutor, price *types.DBPrice, logger *zap.Logger) error {
	if price == nil {
		logger.Error("price cannot be nil")
		return fmt.Errorf("price cannot be nil")
	}

	// Convert float64 to types.Decimal for SQLBoiler
	var bigDecimal decimal.Big
	bigDecimal.SetFloat64(price.Amount)
	priceDecimal := sqltypes.NewDecimal(&bigDecimal)

	// Convert types.DBPrice to models.ProductPrice
	var variantNullString null.String
	if price.Variant != nil {
		variantNullString = null.NewString(*price.Variant, *price.Variant != "")
	} else {
		variantNullString = null.NewString("", false) // null variant
	}

	modelPrice := &models.ProductPrice{
		ProductID: price.ProductID,
		Variant:   variantNullString,
		Currency:  price.Currency,
		Price:     priceDecimal,
	}

	// Use Upsert to handle both insert and update cases
	// Conflict on product_id, variant, currency combination
	err := modelPrice.Upsert(
		ctx,
		exec,
		true, // updateOnConflict
		[]string{"product_id", "variant", "currency"}, // conflict columns
		boil.Blacklist("id", "created_at"),            // updateColumns - don't update these
		boil.Infer(),                                  // insertColumns - infer from struct
	)

	if err != nil {
		logger.Error("failed to upsert price", zap.Int("product_id", price.ProductID), zap.String("currency", price.Currency), zap.Error(err))
		return fmt.Errorf("failed to upsert price for product %d: %w", price.ProductID, err)
	}
	logger.Info("successfully upserted price", zap.Int("product_id", price.ProductID), zap.String("currency", price.Currency))
	return nil
}
