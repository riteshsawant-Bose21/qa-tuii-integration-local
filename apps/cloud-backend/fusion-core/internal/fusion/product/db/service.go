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
	errorspkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	sqltypes "github.com/aarondl/sqlboiler/v4/types"
	"github.com/ericlagergren/decimal"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Service is a service for managing products in the database and sync operations.
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

// ============================================================================
// PRICING OPERATIONS
// ============================================================================

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

// ============================================================================
// SYNC OPERATIONS
// ============================================================================

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
	if job.Version.Valid && job.Version.String != "" {
		return job.Version.String, nil
	}

	return "", fmt.Errorf("no version information found in sync job")
}

// ============================================================================
// TRANSFORMATION HELPERS
// ============================================================================

// transformToSingleProductResponse transforms a SQLBoiler Product model to SingleProductResponse
func (s *Service) transformToSingleProductResponse(product *models.Product, version string) (*types.SingleProductResponse, error) {
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
		return nil, fmt.Errorf("unknown product type: %s", product.ProductType)
	}
}

// appendToProductResponse adds a product to the appropriate slice in ProductResponse
func (s *Service) appendToProductResponse(response *types.ProductResponse, product *models.Product) error {
	itemResponse := s.buildProductItemResponse(product)

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
		return fmt.Errorf("unknown product type: %s", product.ProductType)
	}

	return nil
}

// buildProductItemResponse creates a ProductItemResponse from a SQLBoiler model
func (s *Service) buildProductItemResponse(product *models.Product) *types.ProductItemResponse {
	imagesData := s.parseJSONField(product.Images, []map[string]interface{}{{"black": []string{""}}})
	specs := s.parseJSONField(product.Specifications, make(map[string]interface{}))

	return &types.ProductItemResponse{
		ProductID:          product.ProductID,
		Assets:             imagesData,
		ModelName:          product.ModelName,
		ModelFamily:        s.getStringValue(product.ModelFamily),
		Description:        s.getStringValue(product.Description),
		Specifications:     specs,
		IsFusionCompatible: s.getBoolValue(product.Isfusioncompatible),
	}
}

// parseJSONField safely parses a null JSON field with fallback
func (s *Service) parseJSONField(field null.JSON, fallback interface{}) interface{} {
	if !field.Valid {
		return fallback
	}

	var jsonData interface{}
	if err := json.Unmarshal(field.JSON, &jsonData); err != nil {
		return fallback
	}

	return jsonData
}

// getStringValue safely extracts string from null.String
func (s *Service) getStringValue(field null.String) string {
	if field.Valid {
		return field.String
	}
	return ""
}

// getBoolValue safely extracts bool from null.Bool
func (s *Service) getBoolValue(field null.Bool) bool {
	if field.Valid {
		return field.Bool
	}
	return false
}

// ============================================================================
// SYNC OPERATIONS - Product Operations
// ============================================================================

// Insert inserts a single product into the database
func (s *Service) Insert(ctx context.Context, product *types.DBProduct) error {
	return s.insertProduct(ctx, s.db, product)
}

// Upsert inserts or updates a single product in the database
func (s *Service) Upsert(ctx context.Context, product *types.DBProduct) error {
	return s.insertProduct(ctx, s.db, product)
}

// InsertBatch inserts multiple products within a single transaction
func (s *Service) InsertBatch(ctx context.Context, products []*types.DBProduct) error {
	if len(products) == 0 {
		return nil
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, product := range products {
		if err := s.insertProduct(ctx, tx, product); err != nil {
			return err
		}
	}

	return tx.Commit()
}

// InsertWithRetry inserts a product with retry logic
func (s *Service) InsertWithRetry(ctx context.Context, product *types.DBProduct, maxRetries int, retryDelay time.Duration) error {
	var lastErr error
	for i := 0; i <= maxRetries; i++ {
		err := s.Insert(ctx, product)
		if err == nil {
			return nil
		}
		lastErr = err

		if i < maxRetries {
			time.Sleep(retryDelay)
		}
	}
	return lastErr
}

// LookupProductIDBySKU looks up a product ID by SKU
func (s *Service) LookupProductIDBySKU(ctx context.Context, sku int) (int, bool, error) {
	product, err := models.Products(qm.Where("product_id = ?", sku)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return product.ProductID, true, nil
}

// BatchLookupExistingProductIDs checks which product IDs exist in the database
// Returns a set (map) of existing product IDs for O(1) lookups
func (s *Service) BatchLookupExistingProductIDs(ctx context.Context, productIDs []int) (map[int]bool, error) {
	result := make(map[int]bool)

	if len(productIDs) == 0 {
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
			return nil, fmt.Errorf("failed to batch lookup product IDs: %w", err)
		}

		for rows.Next() {
			var productID int
			if err := rows.Scan(&productID); err != nil {
				rows.Close()
				return nil, fmt.Errorf("failed to scan product ID: %w", err)
			}
			result[productID] = true
		}
		rows.Close()

		if err := rows.Err(); err != nil {
			return nil, fmt.Errorf("error iterating product IDs: %w", err)
		}
	}

	return result, nil
}

// GetProductTimestamps retrieves updated_at timestamps for multiple products
func (s *Service) GetProductTimestamps(ctx context.Context, productIDs []int) (map[int]*int64, error) {
	if len(productIDs) == 0 {
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
		return nil, fmt.Errorf("failed to query product timestamps: %w", err)
	}
	defer rows.Close()

	result := make(map[int]*int64)
	for rows.Next() {
		var productID int
		var updatedAt null.Time

		if err := rows.Scan(&productID, &updatedAt); err != nil {
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
		return nil, fmt.Errorf("error iterating product timestamp rows: %w", err)
	}

	return result, nil
}

// GetExistingProduct retrieves an existing product by product ID
func (s *Service) GetExistingProduct(ctx context.Context, productID int) (*types.DBProduct, error) {
	product, err := models.Products(qm.Where("product_id = ?", productID)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		return nil, nil // Product doesn't exist
	}
	if err != nil {
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

	return dbProduct, nil
}

// ============================================================================
// SYNC OPERATIONS - Price Operations
// ============================================================================

// UpsertPrice inserts or updates a price record
func (s *Service) UpsertPrice(ctx context.Context, price *types.DBPrice) error {
	return s.upsertPrice(ctx, s.db, price)
}

// UpsertBatch inserts or updates multiple price records within a single transaction
func (s *Service) UpsertBatch(ctx context.Context, prices []*types.DBPrice) error {
	if len(prices) == 0 {
		return nil
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, price := range prices {
		if err := s.upsertPrice(ctx, tx, price); err != nil {
			return err
		}
	}

	return tx.Commit()
}

// InsertPriceBatch inserts multiple new price records using a single bulk INSERT statement
// Uses ON CONFLICT DO UPDATE to handle existing prices (upsert behavior)
func (s *Service) InsertPriceBatch(ctx context.Context, prices []*types.DBPrice) error {
	if len(prices) == 0 {
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

		if err := s.bulkInsertPrices(ctx, batch); err != nil {
			return err
		}
	}

	return nil
}

// bulkInsertPrices inserts a batch of prices using a single SQL statement
// Since there's no unique constraint, we use DELETE + INSERT pattern
func (s *Service) bulkInsertPrices(ctx context.Context, prices []*types.DBPrice) error {
	if len(prices) == 0 {
		return nil
	}

	// Start a transaction for atomicity
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
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
		return fmt.Errorf("failed to bulk insert prices: %w", err)
	}

	return tx.Commit()
}

// GetPriceByProductID retrieves a price by product ID (implements the interface requirement)
func (s *Service) GetPriceByProductID(ctx context.Context, productID int) (*types.DBPrice, error) {
	price, err := models.ProductPrices(qm.Where("product_id = ?", productID)).One(ctx, s.db)
	if err == sql.ErrNoRows {
		return nil, nil // Price doesn't exist
	}
	if err != nil {
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

	return dbPrice, nil
}

// GetPriceTimestamps retrieves updated_at timestamps for multiple prices using batch queries
// This is optimized to avoid N+1 query problem by fetching all prices in batches
func (s *Service) GetPriceTimestamps(ctx context.Context, priceKeys []types.PriceKey) (map[types.PriceKey]*int64, error) {
	result := make(map[types.PriceKey]*int64)

	if len(priceKeys) == 0 {
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
			return nil, fmt.Errorf("failed to batch query price timestamps: %w", err)
		}

		for rows.Next() {
			var productID int
			var currency string
			var variant string
			var updatedAt null.Time

			if err := rows.Scan(&productID, &currency, &variant, &updatedAt); err != nil {
				rows.Close()
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
			return nil, fmt.Errorf("error iterating price timestamp rows: %w", err)
		}
	}

	// Keys not found in DB will not be in result map - caller handles this as nil
	return result, nil
}

// ============================================================================
// SYNC OPERATIONS - Job Operations
// ============================================================================

// Create creates a new sync job and returns the job ID
func (s *Service) Create(ctx context.Context, syncOperation, syncType, version, sourcePath, s3Bucket, s3Key string) (string, error) {
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
		Version:       null.NewString(version, version != ""),
		S3Bucket:      s3Bucket,
		S3Key:         s3Key,
		CreatedAt:     null.TimeFrom(time.Now()),
	}

	err := job.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return "", fmt.Errorf("failed to create sync job: %w", err)
	}

	return jobID, nil
}

// UpdateStatus updates the status of a sync job
func (s *Service) UpdateStatus(ctx context.Context, jobID, status string, startedAt *time.Time, errorMsg *string) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
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
	return err
}

// UpdateWithResults updates a job with processing results
func (s *Service) UpdateWithResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
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
	return err
}

// UpdateStatusAndResults updates job status and results atomically
func (s *Service) UpdateStatusAndResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	return s.UpdateWithResults(ctx, jobID, status, totalItems, successful, failed, validationWarnings, errorMsg)
}

// GetByID retrieves a sync job result by ID
func (s *Service) GetByID(ctx context.Context, jobID string) (*types.SyncJobResult, error) {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
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

	return result, nil
}

// StoreValidationErrors stores validation errors for a job
func (s *Service) StoreValidationErrors(ctx context.Context, jobID string, errorCollector *errorspkg.ErrorCollector) error {
	if errorCollector == nil {
		return nil
	}

	summary := errorCollector.GetSummary()
	if summary.TotalErrors == 0 {
		return nil
	}

	// Store errors in job record with structured data to distinguish from warnings
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
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
		return fmt.Errorf("failed to marshal errors: %w", err)
	}

	job.ValidationErrors = null.JSONFrom(errorsJSON)
	_, err = job.Update(ctx, s.db, boil.Infer())

	return err
}

// StoreValidationData stores both validation warnings and errors in a combined format
func (s *Service) StoreValidationData(ctx context.Context, jobID string, validationWarnings []string, errorCollector *errorspkg.ErrorCollector) error {
	job, err := models.ProductSyncJobs(qm.Where("job_id = ?", jobID)).One(ctx, s.db)
	if err != nil {
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
			return fmt.Errorf("failed to marshal validation data: %w", err)
		}
		job.ValidationErrors = null.JSONFrom(validationJSON)
		_, err = job.Update(ctx, s.db, boil.Infer())
		return err
	}

	return nil
}

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

// insertProduct handles the actual product insertion logic
func (s *Service) insertProduct(ctx context.Context, exec boil.ContextExecutor, product *types.DBProduct) error {
	if product == nil {
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
		Isfusioncompatible: null.NewBool(product.IsFusionCompatible, true),
	}

	// Debug: Log fusion compatibility value
	s.logger.Info("DEBUG: Inserting product with fusion compatibility",
		zap.Int("product_id", product.ProductID),
		zap.Bool("is_fusion_compatible", product.IsFusionCompatible),
		zap.Bool("fusion_compatible_valid", modelProduct.Isfusioncompatible.Valid),
		zap.Bool("fusion_compatible_value", modelProduct.Isfusioncompatible.Bool))

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
		return fmt.Errorf("failed to upsert product %d: %w", product.ProductID, err)
	}

	return nil
}

// upsertPrice handles the actual price upsert logic
func (s *Service) upsertPrice(ctx context.Context, exec boil.ContextExecutor, price *types.DBPrice) error {
	if price == nil {
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
		return fmt.Errorf("failed to upsert price for product %d: %w", price.ProductID, err)
	}

	return nil
}
