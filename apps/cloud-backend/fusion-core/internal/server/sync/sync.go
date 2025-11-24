package sync

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/validation"
	"go.uber.org/zap"
)

// ProductTypeResult represents the result of processing a specific product type
type ProductTypeResult struct {
	ProductType        string
	Successful         int
	Failed             int
	Skipped            int
	Errors             []string
	ValidationWarnings []string
}

// Product represents a product from the JSON data (matching sync_data structure)
type Product struct {
	ProductID        int                   `json:"id"`
	ModelName        string                `json:"model_name"`
	ModelFamily      string                `json:"model_family"`
	ShortDescription string                `json:"short_description"`
	Description      string                `json:"description"`
	Images           []map[string][]string `json:"images"`
	UpdatedAt        string                `json:"updated_at,omitempty"` // Epoch timestamp as string
	// All other fields will be captured as specifications
	RawData map[string]interface{} `json:"-"`
}

// ProductData represents the top-level structure of the JSON data (matching sync_data structure)
type ProductData struct {
	Version                 string    `json:"version"`
	Title                   string    `json:"title,omitempty"`
	Description             string    `json:"description,omitempty"`
	Speakers                []Product `json:"speakers"`
	Amplifiers              []Product `json:"amplifiers"`
	DigitalSignalProcessors []Product `json:"digital_signal_processors"`
	Controllers             []Product `json:"controllers"`
	IOEndpoints             []Product `json:"i_o_endpoints"`
	AdditionalAccessories   []Product `json:"additional_accessories"`
}

// PriceData represents the JSON structure for price sync
type PriceData struct {
	ProductID int     `json:"product_id"`
	SKU       int     `json:"sku"`
	Currency  string  `json:"currency"`
	Price     float64 `json:"price"`
	Amount    float64 `json:"amount"`
	Variant   *string `json:"variant,omitempty"`
	UpdatedAt *string `json:"updated_at,omitempty"`
	CreatedAt *string `json:"created_at,omitempty"`
}

// PriceContainer represents price data with variants
type PriceContainer struct {
	Version string     `json:"version,omitempty"`
	RRPData []RRPEntry `json:"rrp_data,omitempty"`
}

// RRPEntry represents a product with multiple price variants
type RRPEntry struct {
	SKU      int         `json:"sku"`
	Variants []PriceData `json:"variants"`
}

// SyncProducts syncs product data from source to database with advanced features
func (s *Service) SyncProducts(ctx context.Context, data []byte, jobID string) (*types.SyncResult, error) {
	startTime := time.Now()

	// Create logger for error collection
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	result := &types.SyncResult{
		SyncType:           "product",
		TotalItems:         0,
		Successful:         0,
		Failed:             0,
		Skipped:            0,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
		Duration:           0,
		JobID:              jobID,
	}

	errorCollector := errors.NewErrorCollector(logger, jobID, "product")
	validator := validation.NewFieldValidator()

	// Parse JSON using same approach as sync_data
	jsonData, err := s.parseProductJSON(data)
	if err != nil {
		syncErr := errors.NewError(errors.ParseError, errors.SeverityCritical, "Failed to parse product JSON").
			WithOriginalError(err).
			WithContext(errors.ErrorContext{
				JobID:    jobID,
				SyncType: "product",
			}).
			Build()
		errorCollector.Add(syncErr)
		result.Duration = time.Since(startTime)
		result.ErrorSummary = s.getErrorSummary(errorCollector)
		result.DetailedErrors = errorCollector.GetAllErrors()
		return result, fmt.Errorf("invalid JSON: %w", err)
	}

	// Load configuration for validation settings
	cfg, err := config.Load()
	if err != nil {
		logger.Warn("Failed to load config for validation, using defaults", zap.Error(err))
	}

	// Validate version before proceeding with data validation
	if cfg != nil {
		if err := s.validateVersion(jsonData, cfg); err != nil {
			syncErr := errors.NewError(errors.ValidationError, errors.SeverityCritical, "Data version validation failed").
				WithOriginalError(err).
				WithContext(errors.ErrorContext{
					JobID:    jobID,
					SyncType: "product",
				}).
				Build()
			errorCollector.Add(syncErr)
			result.Duration = time.Since(startTime)
			result.ErrorSummary = s.getErrorSummary(errorCollector)
			result.DetailedErrors = errorCollector.GetAllErrors()
			return result, fmt.Errorf("version validation failed: %w", err)
		}
	}

	// Validate JSON structure
	if err := s.validateProductJSON(jsonData); err != nil {
		syncErr := errors.NewError(errors.ValidationError, errors.SeverityCritical, "Product JSON validation failed").
			WithOriginalError(err).
			WithContext(errors.ErrorContext{
				JobID:    jobID,
				SyncType: "product",
			}).
			Build()
		errorCollector.Add(syncErr)
		result.Duration = time.Since(startTime)
		result.ErrorSummary = s.getErrorSummary(errorCollector)
		result.DetailedErrors = errorCollector.GetAllErrors()
		return result, fmt.Errorf("validation failed: %w", err)
	}

	// Gather all products from different categories
	allProducts := s.gatherAllProducts(jsonData)

	// Extract SKU from skus array in RawData for each product and override ProductID
	for i := range allProducts {
		if sku := s.extractSKUFromRawData(allProducts[i].RawData); sku > 0 {
			allProducts[i].ProductID = sku
		} else {
			// If no SKU found, log warning but continue with existing ID
			logger.Warn("No SKU found for product",
				zap.Int("product_id", allProducts[i].ProductID),
				zap.String("model_name", allProducts[i].ModelName),
			)
		}
	}

	result.TotalItems = len(allProducts)

	allProductIDs := make([]int, len(allProducts))
	productMap := make(map[int]Product)
	for i, product := range allProducts {
		allProductIDs[i] = product.ProductID
		productMap[product.ProductID] = product
	}

	dbTimestamps, err := s.productDBService.GetProductTimestamps(ctx, allProductIDs)
	if err != nil {
		logger.Warn("Failed to get database timestamps, processing all products", zap.Error(err))
		dbTimestamps = make(map[int]*int64)
	}

	var changedProducts []Product
	var newProducts, updatedProducts, skippedProducts int

	for _, product := range allProducts {
		needsUpdate, reason := s.shouldUpdateProduct(product, dbTimestamps[product.ProductID])
		if needsUpdate {
			changedProducts = append(changedProducts, product)
			if reason == "new_product" {
				newProducts++
			} else {
				updatedProducts++
			}
		} else {
			skippedProducts++
		}
	}

	logger.Info("Timestamp-based change detection completed",
		zap.Int("total_products", len(allProducts)),
		zap.Int("changed_products", len(changedProducts)),
		zap.Int("new_products", newProducts),
		zap.Int("updated_products", updatedProducts),
		zap.Int("skipped_products", skippedProducts),
		zap.Float64("optimization_efficiency", float64(skippedProducts)/float64(len(allProducts))*100),
	)

	if len(changedProducts) == 0 {
		logger.Info("No products require updates based on timestamp analysis")
		result.Duration = time.Since(startTime)
		return result, nil
	}

	// Group changed products by type for category-level processing
	changedByType := s.groupProductsByType(changedProducts, jsonData)

	// Debug: log which categories we found
	for categoryName, products := range changedByType {
		logger.Info("Category processing info",
			zap.String("category", categoryName),
			zap.Int("products_count", len(products)),
		)
	}

	// Process each product type concurrently (category-level goroutines)
	typeResults := make(chan *ProductTypeResult, 6)
	var wg sync.WaitGroup

	// Process each category in its own goroutine
	for productType, products := range changedByType {
		if len(products) > 0 {
			wg.Add(1)
			go func(prods []Product, pType string) {
				defer wg.Done()
				res := s.processProductType(ctx, prods, pType, errorCollector, validator, logger)
				typeResults <- res
			}(products, productType)
		}
	}

	// Wait for all category goroutines to complete
	go func() {
		wg.Wait()
		close(typeResults)
	}()

	// Aggregate results from all categories
	var totalSuccessful, totalFailed, totalSkipped int
	var allValidationWarnings []string
	for typeResult := range typeResults {
		totalSuccessful += typeResult.Successful
		totalFailed += typeResult.Failed
		totalSkipped += typeResult.Skipped
		result.Errors = append(result.Errors, typeResult.Errors...)
		allValidationWarnings = append(allValidationWarnings, typeResult.ValidationWarnings...)
	}

	result.Successful = totalSuccessful
	result.Failed = totalFailed
	result.Skipped = totalSkipped + skippedProducts // Include timestamp-based skipping
	result.ValidationWarnings = allValidationWarnings
	result.Duration = time.Since(startTime)

	result.ErrorSummary = s.getErrorSummary(errorCollector)
	result.DetailedErrors = errorCollector.GetAllErrors()

	// Log comprehensive summary like sync_data
	errorCollector.LogSummary()

	if len(errorCollector.GetAllErrors()) > 0 && jobID != "" {
		if err := s.jobDBService.StoreValidationErrors(jobID, errorCollector); err != nil {
			logger.Error("Failed to store validation errors", zap.Error(err))
		}
	}

	logger.Info("Product sync completed",
		zap.String("sync_type", result.SyncType),
		zap.Int("total_products_in_file", len(allProducts)),
		zap.Int("changed_products_processed", len(changedProducts)),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Int("skipped", result.Skipped),
		zap.Duration("duration", result.Duration),
		zap.Int("total_errors", len(result.DetailedErrors)),
		zap.Float64("success_rate", float64(result.Successful)/float64(len(changedProducts))*100),
	)

	return result, nil
}

// SyncPrices syncs price data from source to database with timestamp-based optimization
func (s *Service) SyncPrices(ctx context.Context, data []byte) (*types.SyncResult, error) {
	startTime := time.Now()

	// Create logger for error collection
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	result := &types.SyncResult{
		SyncType:           "price",
		TotalItems:         0,
		Successful:         0,
		Failed:             0,
		Skipped:            0,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
		Duration:           0,
	}

	errorCollector := errors.NewErrorCollector(logger, "", "price")
	validator := validation.NewFieldValidator()

	var prices []PriceData

	arrayErr := json.Unmarshal(data, &prices)
	if arrayErr != nil {
		var container PriceContainer
		containerErr := json.Unmarshal(data, &container)
		if containerErr != nil {
			errMsg := fmt.Sprintf("failed to parse JSON data as array (%v) or container (%v)", arrayErr, containerErr)
			result.Errors = append(result.Errors, errMsg)
			syncErr := errors.NewError(errors.ParseError, errors.SeverityCritical, errMsg).
				WithOriginalError(arrayErr).
				WithContext(errors.ErrorContext{
					SyncType: "price",
				}).
				Build()
			errorCollector.Add(syncErr)
			result.Duration = time.Since(startTime)
			result.ErrorSummary = s.getErrorSummary(errorCollector)
			result.DetailedErrors = errorCollector.GetAllErrors()
			return result, arrayErr
		}

		// Validate version if container format is used
		if err := s.validatePriceVersion(&container); err != nil {
			syncErr := errors.NewError(errors.ValidationError, errors.SeverityCritical, "Price data version validation failed").
				WithOriginalError(err).
				WithContext(errors.ErrorContext{
					SyncType: "price",
				}).
				Build()
			errorCollector.Add(syncErr)
			result.Duration = time.Since(startTime)
			result.ErrorSummary = s.getErrorSummary(errorCollector)
			result.DetailedErrors = errorCollector.GetAllErrors()
			return result, fmt.Errorf("price version validation failed: %w", err)
		}

		prices = s.extractPricesFromContainer(&container)
	} else {
		prices = s.normalizePrices(prices)
	}

	result.TotalItems = len(prices)

	// Apply timestamp-based change detection optimization
	changedPrices, err := s.DetectChangedPricesByTimestamp(ctx, prices, logger)
	if err != nil {
		logger.Warn("Timestamp detection failed, processing all prices", zap.Error(err))
		changedPrices = prices
	}

	// If no prices need updating, return early
	if len(changedPrices) == 0 {
		logger.Info("No prices require updates based on timestamp analysis")
		result.Duration = time.Since(startTime)
		result.ErrorSummary = s.getErrorSummary(errorCollector)
		result.DetailedErrors = errorCollector.GetAllErrors()
		return result, nil
	}

	maxWorkers := 5
	semaphore := make(chan struct{}, maxWorkers)
	var wg sync.WaitGroup
	var successCount, failCount, skippedCount int64

	var validationWarnings []string
	var warningsMutex sync.Mutex

	for i, price := range changedPrices {
		select {
		case <-ctx.Done():
			// Add context cancellation error
			syncErr := errors.NewError(errors.SystemError, errors.SeverityHigh, "Processing cancelled due to context timeout").
				WithContext(errors.ErrorContext{
					SyncType:  "price",
					Goroutine: i,
				}).
				Build()
			errorCollector.Add(syncErr)
			result.Duration = time.Since(startTime)
			result.ErrorSummary = s.getErrorSummary(errorCollector)
			result.DetailedErrors = errorCollector.GetAllErrors()
			return result, ctx.Err()
		default:
		}

		semaphore <- struct{}{} // Acquire semaphore
		wg.Add(1)

		go func(p PriceData, goroutineID int) {
			defer func() {
				<-semaphore // Release semaphore
				wg.Done()
			}()

			if err := s.processPrice(ctx, p, goroutineID, errorCollector, validator, &validationWarnings, &warningsMutex); err != nil {
				if isSkipError(err) {
					atomic.AddInt64(&skippedCount, 1)
					logger.Info("Price skipped",
						zap.Int("product_id", p.ProductID),
						zap.String("reason", err.Error()),
						zap.Int("goroutine_id", goroutineID),
					)
				} else {
					atomic.AddInt64(&failCount, 1)
					result.Errors = append(result.Errors, fmt.Sprintf("Price for product %d: %v", p.ProductID, err))
					logger.Error("Failed to process price",
						zap.Int("product_id", p.ProductID),
						zap.String("currency", p.Currency),
						zap.Float64("price", p.Price),
						zap.Int("goroutine_id", goroutineID),
						zap.Error(err),
					)
				}
			} else {
				atomic.AddInt64(&successCount, 1)
				logger.Debug("Successfully processed price",
					zap.Int("product_id", p.ProductID),
					zap.String("currency", p.Currency),
					zap.Float64("price", p.Price),
					zap.Int("goroutine_id", goroutineID),
				)
			}
		}(price, i)
	}

	wg.Wait()

	result.Successful = int(successCount)
	result.Failed = int(failCount)
	result.Skipped = int(skippedCount) + (len(prices) - len(changedPrices))
	result.ValidationWarnings = validationWarnings
	result.Duration = time.Since(startTime)

	// Set error summary
	result.ErrorSummary = s.getErrorSummary(errorCollector)
	result.DetailedErrors = errorCollector.GetAllErrors()

	logger.Info("Price sync completed with timestamp optimization",
		zap.String("sync_type", result.SyncType),
		zap.Int("total_prices_in_file", len(prices)),
		zap.Int("changed_prices_processed", len(changedPrices)),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Int("skipped", result.Skipped),
		zap.Duration("duration", result.Duration),
		zap.Int("total_errors", len(result.DetailedErrors)),
		zap.Float64("optimization_efficiency", float64(len(prices)-len(changedPrices))/float64(len(prices))*100),
		zap.Float64("success_rate", float64(result.Successful)/float64(len(changedPrices))*100),
	)

	return result, nil
}

// Helper functions

func (s *Service) convertProductToMap(product Product) map[string]interface{} {
	// Use RawData directly for validation
	if product.RawData != nil {
		return product.RawData
	}

	// Fallback: build from Product fields
	result := map[string]interface{}{
		"id":           product.ProductID,
		"model_name":   product.ModelName,
		"model_family": product.ModelFamily,
		"description":  product.Description,
		"images":       product.Images,
		"updated_at":   product.UpdatedAt,
	}

	if product.ShortDescription != "" {
		result["short_description"] = product.ShortDescription
	}

	return result
}

func (s *Service) convertPriceToMap(price PriceData) map[string]interface{} {
	result := map[string]interface{}{
		"product_id": price.ProductID,
		"sku":        price.SKU,
		"currency":   price.Currency,
		"price":      price.Price,
	}

	if price.Variant != nil {
		result["variant"] = *price.Variant
	}
	if price.UpdatedAt != nil {
		result["updated_at"] = *price.UpdatedAt
	}
	if price.CreatedAt != nil {
		result["created_at"] = *price.CreatedAt
	}

	return result
}

// convertToDBProduct converts Product to database format (matching sync_data implementation)
func (s *Service) convertToDBProduct(product Product, productType string) *DBProduct {
	// Extract specifications from RawData, excluding main fields
	specifications := make(map[string]interface{})
	excludeFields := map[string]bool{
		"id":           true,
		"model_name":   true,
		"model_family": true,
		"description":  true,
		"images":       true,
		"created_at":   true,
		"updated_at":   true,
	}

	for key, value := range product.RawData {
		if !excludeFields[key] {
			specifications[key] = value
		}
	}

	// Convert specifications to JSON string
	specBytes, _ := json.Marshal(specifications)

	// Convert images to JSON string
	imagesBytes, _ := json.Marshal(product.Images)

	// Extract timestamps from RawData
	var createdAt, updatedAt *string
	if ca, ok := product.RawData["created_at"].(string); ok && ca != "" {
		createdAt = &ca
	}
	if ua, ok := product.RawData["updated_at"].(string); ok && ua != "" {
		updatedAt = &ua
	}

	return &DBProduct{
		ProductID:        product.ProductID,
		ProductType:      s.getProductTypeFromCategory(productType),
		ModelName:        product.ModelName,
		ModelFamily:      product.ModelFamily,
		ShortDescription: product.ShortDescription,
		Description:      product.Description,
		Images:           string(imagesBytes),
		Specifications:   string(specBytes),
		CreatedAt:        createdAt,
		UpdatedAt:        updatedAt,
	}
}

// parseImagesArray converts raw images array to proper structure
func (s *Service) parseImagesArray(images []interface{}) []map[string][]string {
	var result []map[string][]string

	for _, img := range images {
		if imgMap, ok := img.(map[string]interface{}); ok {
			colorMap := make(map[string][]string)
			for color, files := range imgMap {
				if fileArray, ok := files.([]interface{}); ok {
					var fileNames []string
					for _, file := range fileArray {
						if fileName, ok := file.(string); ok {
							fileNames = append(fileNames, fileName)
						}
					}
					colorMap[color] = fileNames
				}
			}
			result = append(result, colorMap)
		}
	}

	return result
}

// parseImagesObject converts raw images object to proper structure
func (s *Service) parseImagesObject(images map[string]interface{}) []map[string][]string {
	var result []map[string][]string
	colorMap := make(map[string][]string)

	for key, value := range images {
		if fileArray, ok := value.([]interface{}); ok {
			var fileNames []string
			for _, file := range fileArray {
				if fileName, ok := file.(string); ok {
					fileNames = append(fileNames, fileName)
				}
			}
			colorMap[key] = fileNames
		} else if fileName, ok := value.(string); ok {
			// Handle single file as array
			colorMap[key] = []string{fileName}
		}
	}

	if len(colorMap) > 0 {
		result = append(result, colorMap)
	}

	return result
}

func (s *Service) convertToDBPrice(price PriceData) *DBPrice {
	dbPrice := &DBPrice{
		ProductID: price.ProductID,
		Currency:  price.Currency,
		Amount:    price.Price,
	}

	dbPrice.Variant = price.Variant
	dbPrice.UpdatedAt = price.UpdatedAt
	dbPrice.CreatedAt = price.CreatedAt

	return dbPrice
}

// parseProductJSON parses the JSON data into ProductData structure (matching sync_data)
func (s *Service) parseProductJSON(data []byte) (*ProductData, error) {
	// First, parse into a flexible structure to capture all fields
	var rawData map[string]interface{}
	if err := json.Unmarshal(data, &rawData); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	result := &ProductData{}

	// Extract metadata fields first
	if version, ok := rawData["version"].(string); ok {
		result.Version = version
	}
	if title, ok := rawData["title"].(string); ok {
		result.Title = title
	}
	if description, ok := rawData["description"].(string); ok {
		result.Description = description
	}

	// Define which categories to process (required fields)
	allowedCategories := map[string]bool{
		"speakers":                  true,
		"amplifiers":                true,
		"digital_signal_processors": true,
		"controllers":               true,
		"i_o_endpoints":             true,
		"additional_accessories":    true,
	}

	// Process each product category, skipping unwanted ones
	for category, items := range rawData {
		// Skip categories that are not in our allowed list
		if !allowedCategories[category] {
			// Silently skip unwanted categories
			continue
		}

		if itemsArray, ok := items.([]interface{}); ok {
			products, err := s.parseProductArray(itemsArray)
			if err != nil {
				return nil, fmt.Errorf("failed to parse %s: %w", category, err)
			}

			switch category {
			case "speakers":
				result.Speakers = products
			case "amplifiers":
				result.Amplifiers = products
			case "digital_signal_processors":
				result.DigitalSignalProcessors = products
			case "controllers":
				result.Controllers = products
			case "i_o_endpoints":
				result.IOEndpoints = products
			case "additional_accessories":
				result.AdditionalAccessories = products
			}
		}
	}

	return result, nil
}

// parseProductArray converts raw interface{} array to Product array (matching sync_data)
func (s *Service) parseProductArray(items []interface{}) ([]Product, error) {
	var products []Product

	for _, item := range items {
		if itemMap, ok := item.(map[string]interface{}); ok {
			product := Product{
				RawData: itemMap,
			}

			// Extract known fields
			if id, ok := itemMap["id"].(float64); ok {
				product.ProductID = int(id)
			}
			// Handle both 'model_name' and 'name' fields - name is more common in this data
			if name, ok := itemMap["name"].(string); ok {
				product.ModelName = name
			} else if modelName, ok := itemMap["model_name"].(string); ok {
				product.ModelName = modelName
			} // Handle model_family with default for accessories
			if modelFamily, ok := itemMap["model_family"].(string); ok {
				product.ModelFamily = modelFamily
			} else {
				// Provide default model_family for accessories that don't have one
				const DefaultModelFamily = "Model Family"
				product.ModelFamily = DefaultModelFamily // Default family for accessories
			}
			if description, ok := itemMap["description"].(string); ok {
				product.Description = description
			}
			if shortDescription, ok := itemMap["short_description"].(string); ok {
				product.ShortDescription = shortDescription
			}

			// Extract timestamp (handle both string and numeric formats)
			if updatedAt, ok := itemMap["updated_at"].(string); ok {
				product.UpdatedAt = updatedAt
			} else if updatedAt, ok := itemMap["updated_at"].(float64); ok {
				product.UpdatedAt = fmt.Sprintf("%.0f", updatedAt)
			}

			// Handle both array and object image formats
			if images, ok := itemMap["images"].([]interface{}); ok {
				// Array format (speakers, controllers, etc.)
				product.Images = s.parseImagesArray(images)
			} else if images, ok := itemMap["images"].(map[string]interface{}); ok {
				// Object format (amplifiers, DSPs, etc.)
				product.Images = s.parseImagesObject(images)
			}

			products = append(products, product)
		}
	}

	return products, nil
}

// gatherAllProducts combines all products from different categories into a single slice (matching sync_data)
func (s *Service) gatherAllProducts(data *ProductData) []Product {
	var allProducts []Product

	allProducts = append(allProducts, data.Speakers...)
	allProducts = append(allProducts, data.Amplifiers...)
	allProducts = append(allProducts, data.DigitalSignalProcessors...)
	allProducts = append(allProducts, data.Controllers...)
	allProducts = append(allProducts, data.IOEndpoints...)
	allProducts = append(allProducts, data.AdditionalAccessories...)

	return allProducts
}

// extractSKUFromRawData extracts the first SKU from the skus array in RawData
func (s *Service) extractSKUFromRawData(rawData map[string]interface{}) int {
	if rawData == nil {
		return 0
	}

	if skusField, exists := rawData["skus"]; exists {
		return s.extractSKUFromArray(skusField)
	}

	return 0
}

// getProductTypeFromCategory maps category to database enum value (matching sync_data)
func (s *Service) getProductTypeFromCategory(category string) string {
	switch category {
	// Handle both singular (from goroutines) and plural (from JSON) forms
	case "speaker", "speakers":
		return "speaker"
	case "amplifier", "amplifiers":
		return "amplifier"
	case "dsp", "digital_signal_processors":
		return "dsp"
	case "controller", "controllers":
		return "controller"
	case "io_endpoint", "i_o_endpoints":
		return "io_endpoint"
	case "accessory", "additional_accessories":
		return "accessory"
	default:
		return "accessory" // Default fallback
	}
}

// extractSKUFromArray extracts the first SKU from a skus array (handles both root level and nested)
func (s *Service) extractSKUFromArray(skus interface{}) int {
	if skus == nil {
		return 0
	}

	// Handle array of numbers directly
	if skusArray, ok := skus.([]interface{}); ok && len(skusArray) > 0 {
		// Get first SKU from array
		if firstSKU, ok := skusArray[0].(float64); ok {
			return int(firstSKU)
		}
		// Handle string SKUs
		if firstSKUStr, ok := skusArray[0].(string); ok {
			var sku int
			if _, err := fmt.Sscanf(firstSKUStr, "%d", &sku); err == nil {
				return sku
			}
		}
		// Handle integer SKUs (if already converted)
		if firstSKU, ok := skusArray[0].(int); ok {
			return firstSKU
		}
	}

	// Handle array of integers (if unmarshaled as []int)
	if skusArray, ok := skus.([]int); ok && len(skusArray) > 0 {
		return skusArray[0]
	}

	return 0
}

// extractPricesFromContainer extracts prices from RRP container format
func (s *Service) extractPricesFromContainer(container *PriceContainer) []PriceData {
	var allPrices []PriceData

	for _, rrpEntry := range container.RRPData {
		for _, variant := range rrpEntry.Variants {
			variant.ProductID = rrpEntry.SKU
			variant.SKU = rrpEntry.SKU
			allPrices = append(allPrices, variant)
		}
	}

	return s.normalizePrices(allPrices)
}

// normalizePrices normalizes price data fields to handle different JSON field names
func (s *Service) normalizePrices(prices []PriceData) []PriceData {
	for i := range prices {
		price := &prices[i]

		if price.ProductID == 0 && price.SKU != 0 {
			price.ProductID = price.SKU
		}

		if price.Price == 0 && price.Amount != 0 {
			price.Price = price.Amount
		}
	}

	return prices
}

// getErrorSummary extracts error summary from error collector
func (s *Service) getErrorSummary(errorCollector *errors.ErrorCollector) *errors.ErrorSummary {
	summary := errorCollector.GetSummary()
	return &summary
}

// shouldUpdateProduct determines if a product needs to be updated based on timestamps (matching sync_data)
func (s *Service) shouldUpdateProduct(product Product, dbEpoch *int64) (bool, string) {
	// If no timestamp in file, always update (could be legacy data)
	if product.UpdatedAt == "" {
		if dbEpoch == nil {
			return true, "new_product"
		}
		return true, "no_timestamp_in_file"
	}

	// Parse file timestamp (handle multiple timestamp formats)
	var fileEpoch int64
	var err error

	// Try multiple timestamp formats in order of preference
	formats := []string{
		time.RFC3339,              // "2006-01-02T15:04:05Z07:00"
		"2006-01-02 15:04:05",     // "2025-11-01 12:25:55"
		"2006-01-02T15:04:05",     // "2025-11-01T12:25:55"
		"2006-01-02 15:04:05 MST", // "2025-11-01 12:25:55 UTC"
	}

	parsed := false
	for _, format := range formats {
		if fileTime, parseErr := time.Parse(format, product.UpdatedAt); parseErr == nil {
			fileEpoch = fileTime.Unix()
			parsed = true
			break
		}
	}

	if !parsed {
		// Fallback: try parsing as epoch seconds (legacy format)
		fileEpoch, err = strconv.ParseInt(product.UpdatedAt, 10, 64)
		if err != nil {
			// Invalid timestamp format, always update
			if dbEpoch == nil {
				return true, "new_product"
			}
			return true, "invalid_timestamp_format"
		}
	}

	// Product doesn't exist in database
	if dbEpoch == nil {
		return true, "new_product"
	}

	// Compare timestamps
	if fileEpoch > *dbEpoch {
		return true, "timestamp_newer"
	}

	return false, "no_change"
}

// DetectChangedPricesByTimestamp compares file timestamps with database timestamps to identify changed prices
func (s *Service) DetectChangedPricesByTimestamp(ctx context.Context, prices []PriceData, logger *zap.Logger) ([]PriceData, error) {
	if len(prices) == 0 {
		return nil, nil
	}

	// Build price keys for batch timestamp lookup
	var priceKeys []PriceKey
	priceMap := make(map[PriceKey]PriceData)

	for _, price := range prices {
		variantKey := ""
		if price.Variant != nil {
			variantKey = *price.Variant
		}

		key := PriceKey{
			ProductID: price.ProductID,
			Currency:  price.Currency,
			Variant:   variantKey,
		}

		priceKeys = append(priceKeys, key)
		priceMap[key] = price
	}

	// Batch query existing timestamps
	dbTimestamps, err := s.priceDBService.GetPriceTimestamps(ctx, priceKeys)
	if err != nil {
		logger.Warn("Failed to get database price timestamps, processing all prices", zap.Error(err))
		return prices, nil // Fallback to processing all prices
	}

	// Compare and filter changed prices
	var changedPrices []PriceData
	var newPrices, updatedPrices, skippedPrices int

	for _, key := range priceKeys {
		price := priceMap[key]
		needsUpdate, reason := s.shouldUpdatePrice(price, dbTimestamps[key])

		if needsUpdate {
			changedPrices = append(changedPrices, price)
			if reason == "new_price" {
				newPrices++
			} else {
				updatedPrices++
			}
		} else {
			skippedPrices++
		}
	}

	logger.Info("Price timestamp-based change detection completed",
		zap.Int("total_prices", len(prices)),
		zap.Int("changed_prices", len(changedPrices)),
		zap.Int("new_prices", newPrices),
		zap.Int("updated_prices", updatedPrices),
		zap.Int("skipped_prices", skippedPrices),
		zap.Float64("change_rate", float64(len(changedPrices))/float64(len(prices))*100),
	)

	return changedPrices, nil
}

// shouldUpdatePrice determines if a price needs to be updated based on timestamps
func (s *Service) shouldUpdatePrice(price PriceData, dbEpoch *int64) (bool, string) {
	// If no timestamp in price, always update (could be legacy data)
	if price.UpdatedAt == nil || *price.UpdatedAt == "" {
		if dbEpoch == nil {
			return true, "new_price"
		}
		return true, "no_timestamp_in_price"
	}

	// Parse price timestamp (handle multiple timestamp formats)
	var fileEpoch int64
	var err error

	// Try multiple timestamp formats in order of preference
	formats := []string{
		time.RFC3339,              // "2006-01-02T15:04:05Z07:00"
		"2006-01-02 15:04:05",     // "2025-11-01 12:25:55"
		"2006-01-02T15:04:05",     // "2025-11-01T12:25:55"
		"2006-01-02 15:04:05 MST", // "2025-11-01 12:25:55 UTC"
	}

	parsed := false
	for _, format := range formats {
		if variantTime, parseErr := time.Parse(format, *price.UpdatedAt); parseErr == nil {
			fileEpoch = variantTime.Unix()
			parsed = true
			break
		}
	}

	if !parsed {
		// Fallback: try parsing as epoch seconds
		fileEpoch, err = strconv.ParseInt(*price.UpdatedAt, 10, 64)
		if err != nil {
			// Invalid timestamp format, always update
			if dbEpoch == nil {
				return true, "new_price"
			}
			return true, "invalid_timestamp_format"
		}
	}

	// Price doesn't exist in database
	if dbEpoch == nil {
		return true, "new_price"
	}

	// Compare timestamps
	if fileEpoch > *dbEpoch {
		return true, "timestamp_newer"
	}

	return false, "no_change"
}

// processProduct processes an individual product with comprehensive validation and error handling
func (s *Service) processProduct(ctx context.Context, product Product, productType string, goroutineID int, errorCollector *errors.ErrorCollector, validator *validation.FieldValidator, validationWarnings *[]string, warningsMutex *sync.Mutex) error {
	// Validate product data using enhanced field validation like sync_data
	productMap := s.convertProductToMap(product)
	validationType := validation.GetProductTypeFromCategory(productType)
	validationResult := validator.ValidateProductFields(productMap, validationType, product.ProductID)

	// Process validation errors with detailed categorization
	processValidationErrors := func(errs []validation.FieldValidationError, isRequired bool) {
		for _, err := range errs {
			switch err.Issue {
			case "missing":
				if isRequired {
					errorCollector.AddMissingRequiredFieldError(
						product.ProductID,
						err.FieldName,
						err.JSONPath,
						err.Description,
					)
				} else {
					errorCollector.AddMissingOptionalFieldError(
						product.ProductID,
						err.FieldName,
						err.JSONPath,
						err.Description,
					)
					// Add to validation warnings for optional fields
					warnMsg := fmt.Sprintf("product %d: optional field '%s' missing", product.ProductID, err.FieldName)
					warningsMutex.Lock()
					*validationWarnings = append(*validationWarnings, warnMsg)
					warningsMutex.Unlock()
				}
			case "wrong_type":
				errorCollector.AddInvalidFieldTypeError(
					product.ProductID,
					err.FieldName,
					err.JSONPath,
					err.ExpectedType,
					err.ActualType,
					err.ActualValue,
				)
			case "constraint_violation":
				errorCollector.AddFieldConstraintError(
					product.ProductID,
					err.FieldName,
					err.JSONPath,
					err.Suggestion,
					err.ActualValue,
				)
			default:
				// Handle any other validation issues
				if isRequired {
					errorCollector.AddMissingRequiredFieldError(
						product.ProductID,
						err.FieldName,
						err.JSONPath,
						fmt.Sprintf("%s: %s", err.Issue, err.Description),
					)
				} else {
					warnMsg := fmt.Sprintf("product %d: field '%s' %s", product.ProductID, err.FieldName, err.Issue)
					warningsMutex.Lock()
					*validationWarnings = append(*validationWarnings, warnMsg)
					warningsMutex.Unlock()
				}
			}
		}
	}

	// Process required field errors - these block processing
	processValidationErrors(validationResult.RequiredErrors, true)
	// Process optional field warnings - these generate warnings but don't block processing
	processValidationErrors(validationResult.OptionalWarnings, false)

	// For required field failures, skip the product like sync_data does
	if len(validationResult.RequiredErrors) > 0 {
		// Extract field names for logging
		var failedFields []string
		for _, err := range validationResult.RequiredErrors {
			failedFields = append(failedFields, err.FieldName)
		}

		return &ProductSkipError{
			ProductID: product.ProductID,
			Reason:    fmt.Sprintf("required field validation failures: %v", failedFields),
		}
	}

	// Convert to database format
	dbProduct := s.convertToDBProduct(product, productType)

	// Validate transformation output
	if err := s.validateDBProduct(dbProduct); err != nil {
		syncErr := errors.NewError(errors.TransformError, errors.SeverityMedium, "Product transformation validation failed").
			WithOriginalError(err).
			WithProductID(product.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "product",
				Goroutine: goroutineID,
			}).
			Build()
		errorCollector.Add(syncErr)
		return err
	}

	// Insert into database with retry
	err := s.productDBService.InsertWithRetry(ctx, dbProduct, 3, time.Millisecond*100)
	if err != nil {
		syncErr := errors.NewError(errors.DatabaseError, errors.SeverityHigh, "Failed to insert product into database").
			WithOriginalError(err).
			WithProductID(product.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "product",
				Goroutine: goroutineID,
			}).
			AsRetryable().
			Build()
		errorCollector.Add(syncErr)
		return err
	}

	return nil
}

// validateDBProduct validates the transformed database product
func (s *Service) validateDBProduct(dbProduct *DBProduct) error {
	if dbProduct.ProductID == 0 {
		return fmt.Errorf("transformed product has invalid ID: %d", dbProduct.ProductID)
	}

	if dbProduct.ProductType == "" {
		return fmt.Errorf("transformed product has empty product type")
	}

	// Validate product type is a valid enum value
	validProductTypes := map[string]bool{
		"speaker":     true,
		"amplifier":   true,
		"dsp":         true,
		"controller":  true,
		"io_endpoint": true,
		"accessory":   true,
	}
	if !validProductTypes[dbProduct.ProductType] {
		return fmt.Errorf("invalid product type '%s' for product %d", dbProduct.ProductType, dbProduct.ProductID)
	}

	if dbProduct.ModelName == "" {
		return fmt.Errorf("transformed product %d has empty model name", dbProduct.ProductID)
	}

	// Validate JSON fields are valid JSON
	if !s.isValidJSON(dbProduct.Images) {
		return fmt.Errorf("invalid images JSON for product %d", dbProduct.ProductID)
	}

	if !s.isValidJSON(dbProduct.Specifications) {
		return fmt.Errorf("invalid specifications JSON for product %d", dbProduct.ProductID)
	}

	return nil
}

// isValidJSON checks if a string is valid JSON
func (s *Service) isValidJSON(jsonStr string) bool {
	if jsonStr == "" {
		return true // Empty string is considered valid
	}
	var js json.RawMessage
	return json.Unmarshal([]byte(jsonStr), &js) == nil
}

// processPrice processes an individual price with comprehensive validation and error handling
func (s *Service) processPrice(ctx context.Context, price PriceData, goroutineID int, errorCollector *errors.ErrorCollector, validator *validation.FieldValidator, validationWarnings *[]string, warningsMutex *sync.Mutex) error {
	// Validate price data
	priceMap := s.convertPriceToMap(price)
	validationResult := validator.ValidatePriceFields(priceMap)

	// Check for validation errors
	hasErrors := false
	if validationResult != nil && !validationResult.IsValid {
		for _, reqErr := range validationResult.RequiredErrors {
			errorCollector.AddMissingRequiredFieldError(price.ProductID, reqErr.FieldName, reqErr.JSONPath, reqErr.Description)
			hasErrors = true
		}

		for _, optWarn := range validationResult.OptionalWarnings {
			warnMsg := fmt.Sprintf("price for product %d: optional field '%s' %s", price.ProductID, optWarn.FieldName, optWarn.Issue)
			warningsMutex.Lock()
			*validationWarnings = append(*validationWarnings, warnMsg)
			warningsMutex.Unlock()
			errorCollector.AddMissingOptionalFieldError(price.ProductID, optWarn.FieldName, optWarn.JSONPath, optWarn.Description)
		}
	}

	// If there are required field errors, skip the price
	if hasErrors {
		return fmt.Errorf("price for product %d has required field validation failures", price.ProductID)
	}

	// Check if product exists
	_, exists, err := s.productDBService.LookupProductIDBySKU(ctx, price.ProductID)
	if err != nil {
		syncErr := errors.NewError(errors.DatabaseError, errors.SeverityHigh, "Failed to lookup product for price").
			WithOriginalError(err).
			WithProductID(price.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "price",
				Goroutine: goroutineID,
			}).
			Build()
		errorCollector.Add(syncErr)
		return err
	}

	if !exists {
		syncErr := errors.NewError(errors.NotFoundError, errors.SeverityMedium, "Product not found, skipping price").
			WithProductID(price.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "price",
				Goroutine: goroutineID,
			}).
			Build()
		errorCollector.Add(syncErr)
		return &ProductNotFoundError{ProductID: price.ProductID}
	}

	// Convert to database format
	dbPrice := s.convertToDBPrice(price)

	// Validate transformation output
	if err := s.validateDBPrice(dbPrice); err != nil {
		syncErr := errors.NewError(errors.TransformError, errors.SeverityMedium, "Price transformation validation failed").
			WithOriginalError(err).
			WithProductID(price.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "price",
				Goroutine: goroutineID,
			}).
			Build()
		errorCollector.Add(syncErr)
		return err
	}

	// Upsert price into database
	err = s.priceDBService.UpsertPrice(ctx, dbPrice)
	if err != nil {
		syncErr := errors.NewError(errors.DatabaseError, errors.SeverityHigh, "Failed to upsert price into database").
			WithOriginalError(err).
			WithProductID(price.ProductID).
			WithContext(errors.ErrorContext{
				SyncType:  "price",
				Goroutine: goroutineID,
			}).
			AsRetryable().
			Build()
		errorCollector.Add(syncErr)
		return err
	}

	return nil
}

// validateDBPrice validates the transformed database price
func (s *Service) validateDBPrice(dbPrice *DBPrice) error {
	if dbPrice.ProductID == 0 {
		return fmt.Errorf("transformed price has invalid product ID: %d", dbPrice.ProductID)
	}

	if dbPrice.Currency == "" {
		return fmt.Errorf("transformed price has empty currency")
	}

	if dbPrice.Amount <= 0 {
		return fmt.Errorf("transformed price has invalid amount: %f", dbPrice.Amount)
	}

	return nil
}

// ProductNotFoundError indicates a product was not found and the operation should be skipped
type ProductNotFoundError struct {
	ProductID int
}

func (e *ProductNotFoundError) Error() string {
	return fmt.Sprintf("product %d not found", e.ProductID)
}

// ProductSkipError indicates a product should be skipped due to validation failures
type ProductSkipError struct {
	ProductID int
	Reason    string
}

func (e *ProductSkipError) Error() string {
	return fmt.Sprintf("product %d: %s", e.ProductID, e.Reason)
}

// isSkipError checks if an error indicates the operation should be skipped rather than failed
func isSkipError(err error) bool {
	_, isProductNotFound := err.(*ProductNotFoundError)
	_, isProductSkip := err.(*ProductSkipError)
	return isProductNotFound || isProductSkip
}

// groupProductsByType separates changed products back into their original categories (matching sync_data)
func (s *Service) groupProductsByType(changedProducts []Product, originalData *ProductData) map[string][]Product {
	// Create map for fast lookup using original ID from RawData
	changedOriginalIDs := make(map[int]bool)
	for _, product := range changedProducts {
		// Use the original ID from RawData, not the SKU
		if originalID, ok := product.RawData["id"].(float64); ok {
			changedOriginalIDs[int(originalID)] = true
		}
	}

	result := make(map[string][]Product)

	// Define category mappings to avoid repetition
	categories := []struct {
		name     string
		products []Product
	}{
		{"speakers", originalData.Speakers},
		{"amplifiers", originalData.Amplifiers},
		{"digital_signal_processors", originalData.DigitalSignalProcessors},
		{"controllers", originalData.Controllers},
		{"i_o_endpoints", originalData.IOEndpoints},
		{"additional_accessories", originalData.AdditionalAccessories},
	}

	// Filter each category using original IDs
	for _, cat := range categories {
		for _, product := range cat.products {
			// Check using original ID from RawData
			if originalID, ok := product.RawData["id"].(float64); ok {
				if changedOriginalIDs[int(originalID)] {
					// Find the corresponding changed product with updated ProductID (SKU)
					for _, changedProduct := range changedProducts {
						if changedOriginalID, ok := changedProduct.RawData["id"].(float64); ok && int(changedOriginalID) == int(originalID) {
							result[cat.name] = append(result[cat.name], changedProduct)
							break
						}
					}
				}
			}
		}
	}

	return result
}

// processProductType processes products of a specific type with individual goroutines
func (s *Service) processProductType(ctx context.Context, products []Product, productType string, errorCollector *errors.ErrorCollector, validator *validation.FieldValidator, logger *zap.Logger) *ProductTypeResult {
	result := &ProductTypeResult{
		ProductType:        productType,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
	}

	maxWorkers := 5 // 5 workers per category type
	semaphore := make(chan struct{}, maxWorkers)
	var wg sync.WaitGroup
	var successCount, failCount, skippedCount int64

	// Validation warnings collection with mutex for thread safety
	var validationWarnings []string
	var warningsMutex sync.Mutex

	for i, product := range products {
		select {
		case <-ctx.Done():
			// Add context cancellation error
			syncErr := errors.NewError(errors.SystemError, errors.SeverityHigh, "Processing cancelled due to context timeout").
				WithContext(errors.ErrorContext{
					SyncType:    "product",
					ProductType: productType,
					Goroutine:   i,
				}).
				Build()
			errorCollector.Add(syncErr)
			return result
		default:
		}

		semaphore <- struct{}{} // Acquire semaphore
		wg.Add(1)

		go func(p Product, goroutineID int) {
			defer func() {
				<-semaphore // Release semaphore
				wg.Done()
			}()

			if err := s.processProduct(ctx, p, productType, goroutineID, errorCollector, validator, &validationWarnings, &warningsMutex); err != nil {
				// Check if this is a ProductSkipError (critical validation failure)
				if skipErr, ok := err.(*ProductSkipError); ok {
					atomic.AddInt64(&skippedCount, 1)
					// Don't add to errors array for skipped products - they're handled separately
					logger.Info("Product skipped due to critical validation failures",
						zap.Int("product_id", skipErr.ProductID),
						zap.String("reason", skipErr.Reason),
						zap.String("product_type", productType),
						zap.Int("goroutine_id", goroutineID),
					)
				} else {
					// Regular processing error
					atomic.AddInt64(&failCount, 1)
					result.Errors = append(result.Errors, fmt.Sprintf("Product %d: %v", p.ProductID, err))

					// Enhanced error logging with more context
					logger.Error("Failed to process product",
						zap.Int("product_id", p.ProductID),
						zap.String("product_type", productType),
						zap.String("model_name", p.ModelName),
						zap.Int("goroutine_id", goroutineID),
						zap.Error(err),
					)
				}
			} else {
				atomic.AddInt64(&successCount, 1)

				// Log successful processing for debugging
				logger.Debug("Successfully processed product",
					zap.Int("product_id", p.ProductID),
					zap.String("product_type", productType),
					zap.String("model_name", p.ModelName),
					zap.Int("goroutine_id", goroutineID),
				)
			}
		}(product, i)
	}

	wg.Wait()

	result.Successful = int(successCount)
	result.Failed = int(failCount)
	result.Skipped = int(skippedCount)
	result.ValidationWarnings = validationWarnings

	logger.Info("Product type processing completed",
		zap.String("product_type", productType),
		zap.Int("total", len(products)),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Int("skipped", result.Skipped),
		zap.Int("validation_warnings", len(result.ValidationWarnings)),
		zap.Float64("success_rate", float64(result.Successful)/float64(len(products))*100),
	)

	return result
}

// validateVersion validates that the data version is supported (matching sync_data implementation)
func (s *Service) validateVersion(data *ProductData, cfg *config.Config) error {
	if !cfg.Validation.RequireVersion {
		// Version checking is disabled
		return nil
	}

	version := strings.TrimSpace(data.Version)
	if version == "" {
		if cfg.Validation.DefaultVersion != "" {
			// Use default version if none provided
			data.Version = cfg.Validation.DefaultVersion
			return nil
		}
		return fmt.Errorf("version field is required but not provided")
	}

	// Check if version is supported
	for _, supportedVersion := range cfg.Validation.SupportedVersions {
		if version == supportedVersion {
			return nil
		}
	}

	return fmt.Errorf("unsupported data version '%s'. Supported versions: %v",
		version, cfg.Validation.SupportedVersions)
}

// validateProductJSON validates the structure of the parsed JSON (matching sync_data implementation)
func (s *Service) validateProductJSON(data *ProductData) error {
	if data == nil {
		return fmt.Errorf("data is nil")
	}

	totalProducts := len(data.Speakers) + len(data.Amplifiers) + len(data.DigitalSignalProcessors) +
		len(data.Controllers) + len(data.IOEndpoints) + len(data.AdditionalAccessories)

	if totalProducts == 0 {
		return fmt.Errorf("no products found in JSON data")
	}

	// Validate product structure
	allProducts := s.gatherAllProducts(data)

	for i, product := range allProducts {
		if product.ProductID == 0 {
			return fmt.Errorf("product at index %d has invalid product_id", i)
		}
		// Note: model_name validation moved to individual product validation
		// to allow concurrent processing to continue even if some products have missing model_name
	}

	return nil
}

// validatePriceVersion validates that the price data version is supported
func (s *Service) validatePriceVersion(container *PriceContainer) error {
	// Load configuration for validation settings
	cfg, err := config.Load()
	if err != nil {
		// If config can't be loaded, skip version validation with warning
		return nil
	}

	if !cfg.Validation.RequireVersion {
		// Version checking is disabled
		return nil
	}

	version := strings.TrimSpace(container.Version)
	if version == "" {
		if cfg.Validation.DefaultVersion != "" {
			// Use default version if none provided
			container.Version = cfg.Validation.DefaultVersion
			return nil
		}
		return fmt.Errorf("version field is required for price data but not provided")
	}

	// Check if version is supported
	for _, supportedVersion := range cfg.Validation.SupportedVersions {
		if version == supportedVersion {
			return nil
		}
	}

	return fmt.Errorf("unsupported price data version '%s'. Supported versions: %v",
		version, cfg.Validation.SupportedVersions)
}
