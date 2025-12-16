package product

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/validation"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

// Service provides methods to interact with the product database and sync operations.
type Service struct {
	dbService     DatabaseService
	version       string
	validator     *validation.FieldValidator
	validationCfg *config.Validation
	processingCfg *config.Processing
}

// DatabaseService defines the interface for database operations related to products and sync.
type DatabaseService interface {
	// Product query operations
	SelectByID(ctx context.Context, id string, version string) (*types.SingleProductResponse, error)
	SelectAll(ctx context.Context, version string) (*types.ProductResponse, error)
	GetPricesByProductID(ctx context.Context, productID int, currency string, variant string) (*types.PriceResponse, error)
	GetLatestSyncVersion(ctx context.Context, syncType string) (string, error)

	// Product sync operations
	Insert(ctx context.Context, product *types.DBProduct) error
	Upsert(ctx context.Context, product *types.DBProduct) error
	InsertBatch(ctx context.Context, products []*types.DBProduct) error
	InsertWithRetry(ctx context.Context, product *types.DBProduct, maxRetries int, retryDelay time.Duration) error
	LookupProductIDBySKU(ctx context.Context, sku int) (int, bool, error)
	BatchLookupExistingProductIDs(ctx context.Context, productIDs []int) (map[int]bool, error)
	GetProductTimestamps(ctx context.Context, productIDs []int) (map[int]*int64, error)
	GetExistingProduct(ctx context.Context, productID int) (*types.DBProduct, error)

	// Price operations
	UpsertPrice(ctx context.Context, price *types.DBPrice) error
	UpsertBatch(ctx context.Context, prices []*types.DBPrice) error
	InsertPriceBatch(ctx context.Context, prices []*types.DBPrice) error
	GetPriceByProductID(ctx context.Context, productID int) (*types.DBPrice, error)
	GetPriceTimestamps(ctx context.Context, priceKeys []types.PriceKey) (map[types.PriceKey]*int64, error)

	// Job operations
	Create(ctx context.Context, syncOperation, syncType, version, sourcePath, s3Bucket, s3Key string) (string, error)
	UpdateStatus(ctx context.Context, jobID, status string, startedAt *time.Time, errorMsg *string) error
	UpdateWithResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error
	UpdateStatusAndResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error
	GetByID(ctx context.Context, jobID string) (*types.SyncJobResult, error)
	StoreValidationErrors(ctx context.Context, jobID string, errorCollector *errors.ErrorCollector) error
}

// NewService creates a new product service.
func NewService(dbService DatabaseService, version string, validationCfg *config.Validation, processingCfg *config.Processing) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if validationCfg == nil {
		panic("validationCfg cannot be nil")
	}
	if processingCfg == nil {
		panic("processingCfg cannot be nil")
	}

	return &Service{
		dbService:     dbService,
		version:       version,
		validator:     validation.NewFieldValidator(),
		validationCfg: validationCfg,
		processingCfg: processingCfg,
	}
}

// DataSource represents a data source interface
type DataSource = cloudfs.DataSource

// createDataSource creates a data source based on type
func (s *Service) createDataSource(sourceType, sourcePath, s3Bucket, s3Key, region string) (DataSource, error) {
	switch sourceType {
	case "local":
		return s.createLocalFileSource(sourcePath)
	case "s3":
		return s.createS3Source(s3Bucket, s3Key, region)
	default:
		return nil, fmt.Errorf("invalid source type: %s", sourceType)
	}
}

// createLocalFileSource creates a local file data source
func (s *Service) createLocalFileSource(filePath string) (DataSource, error) {
	if _, err := os.Stat(filePath); err != nil {
		return nil, fmt.Errorf("failed to access file: %w", err)
	}
	return &LocalFileSource{filePath: filePath}, nil
}

// createS3Source creates an S3 data source
func (s *Service) createS3Source(bucket, key, region string) (DataSource, error) {
	return cloudfs.NewS3Source(bucket, key, region)
}

// CreateJob creates a new sync job
func (s *Service) CreateJob(ctx context.Context, job *types.DBSyncJob) (string, error) {
	// Extract parameters from the job structure
	syncOperation := "sync"
	syncType := job.JobType
	version := "1.0" // default
	sourcePath := ""
	s3Bucket := ""
	s3Key := ""

	// Extract from metadata if available
	if job.Metadata != nil {
		if op, ok := job.Metadata["sync_operation"].(string); ok {
			syncOperation = op
		}
		if v, ok := job.Metadata["version"].(string); ok {
			version = v
		}
		if path, ok := job.Metadata["source_path"].(string); ok {
			sourcePath = path
		}
		if bucket, ok := job.Metadata["s3_bucket"].(string); ok {
			s3Bucket = bucket
		}
		if key, ok := job.Metadata["s3_key"].(string); ok {
			s3Key = key
		}
	}

	// Use the database service to create the job with all parameters
	jobID, err := s.dbService.Create(ctx, syncOperation, syncType, version, sourcePath, s3Bucket, s3Key)
	if err != nil {
		return "", err
	}

	return jobID, nil
}

// UpdateJobStatus updates the status of a job
func (s *Service) UpdateJobStatus(ctx context.Context, jobID string, status string, startedAt *time.Time, errorMsg *string) error {
	return s.dbService.UpdateStatus(ctx, jobID, status, startedAt, errorMsg)
}

// UpdateStatusAndResults updates job status and results atomically
func (s *Service) UpdateStatusAndResults(ctx context.Context, jobID string, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	return s.dbService.UpdateWithResults(ctx, jobID, status, totalItems, successful, failed, validationWarnings, errorMsg)
}

// Execute performs the complete sync operation from start to finish
func (s *Service) Execute(ctx context.Context, request *types.SyncRequest) (*types.SyncResult, error) {
	startTime := time.Now().UTC()

	// 1. Create data source directly
	dataSource, err := s.createDataSource(request.SourceType, request.FilePath, request.S3Bucket, request.S3Key, request.Region)
	if err != nil {
		return nil, fmt.Errorf("failed to create data source: %w", err)
	}
	defer dataSource.Close()

	// 2. Read data from source (single read to avoid stream consumption issues)
	data, err := dataSource.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("failed to read data: %w", err)
	}

	// 3. Extract version from data
	version := s.validationCfg.DefaultVersion // use config default
	if extractedVersion, err := s.extractVersionFromData(data); err == nil {
		version = extractedVersion
	}
	// Note: We don't fail if version extraction fails, just use default

	// 4. Validate version against supported versions
	if err := s.validateVersion(version); err != nil {
		return nil, fmt.Errorf("version validation failed: %w", err)
	}

	// 5. Create sync job with proper metadata
	// Determine sync operation type - if called via CLI it's manual, if via scheduler it would be scheduled
	syncOperation := "manual_sync" // Default for CLI usage
	if request.SyncOperation != "" {
		syncOperation = request.SyncOperation
	}

	jobMetadata := map[string]interface{}{
		"sync_operation": syncOperation,
		"version":        version,
	}

	// Add source-specific metadata
	if request.SourceType == "local" {
		jobMetadata["source_path"] = request.FilePath
	} else if request.SourceType == "s3" {
		jobMetadata["s3_bucket"] = request.S3Bucket
		jobMetadata["s3_key"] = request.S3Key
		jobMetadata["region"] = request.Region
	}

	jobID, err := s.CreateJob(ctx, &types.DBSyncJob{
		JobType:     request.SyncType,
		Status:      "pending",
		Source:      request.SourceType,
		SourceJobID: nil,
		Metadata:    jobMetadata,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create sync job: %w", err)
	}

	// 6. Update job status to in_progress
	if err := s.UpdateJobStatus(ctx, jobID, "in_progress", &startTime, nil); err != nil {
		// Log warning but don't fail
	}

	// 7. Execute sync based on type (data already read above)
	var syncResult *types.SyncResult
	switch request.SyncType {
	case "product":
		syncResult, err = s.SyncProducts(ctx, data, jobID, request.EnableValidation)
	case "price":
		syncResult, err = s.SyncPrices(ctx, data, s.validationCfg)
	default:
		errMsg := fmt.Sprintf("invalid sync type: %s", request.SyncType)
		s.UpdateJobStatus(ctx, jobID, "failed", nil, &errMsg)
		return nil, fmt.Errorf("unsupported sync type: %s", request.SyncType)
	}

	if err != nil {
		errMsg := fmt.Sprintf("processing failed: %v", err)
		s.UpdateJobStatus(ctx, jobID, "failed", &startTime, &errMsg)
		return nil, fmt.Errorf("sync processing failed: %w", err)
	}

	// 7. Update result metadata
	syncResult.Duration = time.Since(startTime)
	if jobID != "" {
		syncResult.JobID = jobID
	}

	// 8. Update job status with final results
	var errMsg *string
	if syncResult.Failed > 0 {
		msg := fmt.Sprintf("Completed with %d failures out of %d items", syncResult.Failed, syncResult.TotalItems)
		errMsg = &msg
	}

	s.UpdateStatusAndResults(
		ctx,
		jobID,
		"completed",
		syncResult.TotalItems,
		syncResult.Successful,
		syncResult.Failed,
		syncResult.ValidationWarnings,
		errMsg,
	)

	return syncResult, nil
}

// extractVersionFromDataSource attempts to extract version from data source
func (s *Service) extractVersionFromDataSource(dataSource DataSource) (string, error) {
	// For local files, try to extract from file path
	path := dataSource.GetPath()
	if path != "" {
		data, err := os.ReadFile(path)
		if err != nil {
			return "", fmt.Errorf("failed to read file: %w", err)
		}
		return s.extractVersionFromData(data)
	}

	// For S3 and other sources, read the data directly and parse it
	data, err := dataSource.ReadAll()
	if err != nil {
		return "1.0", fmt.Errorf("failed to read data source: %w", err)
	}

	return s.extractVersionFromData(data)
}

// extractVersionFromData extracts version from JSON data bytes
func (s *Service) extractVersionFromData(data []byte) (string, error) {
	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return "1.0", fmt.Errorf("failed to parse JSON: %w", err)
	}

	version, ok := jsonData["version"]
	if !ok {
		return "unknown", nil // default version if not found
	}

	versionStr, ok := version.(string)
	if !ok {
		return "unknown", nil // default version if not a string
	}

	return versionStr, nil
}

// validateVersion checks if the extracted version is supported according to config
func (s *Service) validateVersion(version string) error {
	if !s.validationCfg.RequireVersion {
		return nil // Version validation is disabled
	}

	// Check if version is in supported versions list
	for _, supportedVersion := range s.validationCfg.SupportedVersions {
		if version == supportedVersion {
			return nil // Version is supported
		}
	}

	return fmt.Errorf("unsupported version '%s'. Supported versions: %v", version, s.validationCfg.SupportedVersions)
}

// LocalFileSource implements DataSource for local filesystem
type LocalFileSource struct {
	filePath string
}

func (l *LocalFileSource) ReadAll() ([]byte, error) {
	data, err := os.ReadFile(l.filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}
	return data, nil
}

func (l *LocalFileSource) GetPath() string {
	return l.filePath
}

func (l *LocalFileSource) GetSize() (*int64, error) {
	info, err := os.Stat(l.filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to stat file: %w", err)
	}
	size := info.Size()
	return &size, nil
}

func (l *LocalFileSource) Close() error {
	// No resources to close for local file source
	return nil
}

// SyncProducts processes product data from JSON and syncs to database with comprehensive error handling
func (s *Service) SyncProducts(ctx context.Context, jsonData []byte, jobID string, validationEnabled bool) (*types.SyncResult, error) {
	startTime := time.Now()

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

	// Parse JSON using comprehensive approach
	productData, err := s.parseProductJSON(jsonData)
	if err != nil {
		result.Duration = time.Since(startTime)
		result.Errors = append(result.Errors, fmt.Sprintf("Failed to parse product JSON: %v", err))
		return result, fmt.Errorf("invalid JSON: %w", err)
	}

	// Validate JSON structure
	if err := s.validateProductJSON(productData); err != nil {
		result.Duration = time.Since(startTime)
		result.Errors = append(result.Errors, fmt.Sprintf("Product JSON validation failed: %v", err))
		return result, fmt.Errorf("validation failed: %w", err)
	}

	// Gather all products from different categories
	allProducts := s.gatherAllProducts(productData)

	// Extract SKU from skus array and update ProductID
	for i := range allProducts {
		if sku := s.extractSKUFromRawData(allProducts[i].RawData); sku > 0 {
			allProducts[i].ProductID = sku
		}
	}

	result.TotalItems = len(allProducts)

	if len(allProducts) == 0 {
		result.Duration = time.Since(startTime)
		return result, nil
	}

	// Get existing product timestamps to check for updates needed
	productIDs := make([]int, len(allProducts))
	for i, product := range allProducts {
		productIDs[i] = product.ProductID
	}

	existingTimestamps, err := s.dbService.GetProductTimestamps(ctx, productIDs)
	if err != nil {
		// Log warning but continue with full sync
		result.ValidationWarnings = append(result.ValidationWarnings, fmt.Sprintf("Failed to get existing timestamps: %v", err))
	}

	// Filter products that need syncing (new or updated)
	productsToSync := []types.Product{}
	for _, product := range allProducts {
		needsSync := s.shouldUpdateProduct(product, existingTimestamps)
		if needsSync {
			productsToSync = append(productsToSync, product)
		} else {
			result.Skipped++
		}
	}

	if len(productsToSync) == 0 {
		result.Duration = time.Since(startTime)
		return result, nil
	}

	// Group products by category for concurrent processing
	productGroups := s.groupProductsByCategory(productsToSync, productData)

	// Process product categories concurrently using goroutines
	results := make([]*types.CategoryResult, len(productGroups))
	var wg sync.WaitGroup
	var mu sync.Mutex // For thread-safe result updates

	for i, group := range productGroups {
		wg.Add(1)
		go func(index int, categoryGroup types.ProductCategoryGroup) {
			defer wg.Done()

			categoryResult := s.processCategoryGroup(ctx, categoryGroup, validationEnabled)

			// Thread-safe update of results
			mu.Lock()
			results[index] = categoryResult
			result.Successful += categoryResult.Successful
			result.Failed += categoryResult.Failed
			result.Errors = append(result.Errors, categoryResult.Errors...)
			result.ValidationWarnings = append(result.ValidationWarnings, categoryResult.ValidationWarnings...)
			mu.Unlock()
		}(i, group)
	}

	wg.Wait()

	// Store validation warnings and errors in sync job if any were collected
	if len(result.ValidationWarnings) > 0 || len(result.Errors) > 0 {
		// Log validation details for debugging
		// In a real implementation, this would update the sync job record
	}

	result.Duration = time.Since(startTime)
	return result, nil
}

// extractSpecificationsFromProductData extracts specification fields from product data using field validator
func (s *Service) extractSpecificationsFromProductData(itemMap map[string]interface{}, productType string) (string, error) {
	// Get field definitions for the product type from validator
	fieldDefinitions, exists := s.validator.ProductTypeDefinitions[productType]
	if !exists {
		// Use generic definitions if specific type not found
		fieldDefinitions = s.validator.ProductTypeDefinitions["generic"]
	}

	// Extract specification fields (excluding basic product info fields)
	specifications := make(map[string]interface{})
	basicFields := map[string]bool{
		"id": true, "product_id": true, "model_name": true, "model_family": true,
		"description": true, "short_description": true, "images": true, "skus": true,
		"updated_at": true, "created_at": true,
	}

	// Collect all specification-related fields based on field definitions
	for _, fieldDef := range fieldDefinitions {
		// Skip basic product information fields
		if basicFields[fieldDef.JSONPath] {
			continue
		}

		// Extract the field value if it exists
		if value, exists := itemMap[fieldDef.JSONPath]; exists {
			specifications[fieldDef.JSONPath] = value
		}
	}

	// Convert to JSON string if we found any specifications
	if len(specifications) > 0 {
		specsJSON, err := json.Marshal(specifications)
		if err != nil {
			return "", fmt.Errorf("failed to marshal specifications: %w", err)
		}
		return string(specsJSON), nil
	}

	return "", nil
}

// convertJSONToDBProduct converts a raw JSON product item to types.DBProduct
func (s *Service) convertJSONToDBProduct(item interface{}, category string) *types.DBProduct {
	itemMap, ok := item.(map[string]interface{})
	if !ok {
		return nil
	}

	// Extract product ID from 'id' field
	productID, ok := itemMap["id"].(float64)
	if !ok {
		return nil
	}

	// Extract model name
	modelName, _ := itemMap["model_name"].(string)
	if modelName == "" {
		return nil
	}

	// Map category names to database enum values
	var productType string
	switch category {
	case "speakers":
		productType = "speaker"
	case "amplifiers":
		productType = "amplifier"
	case "digital_signal_processors":
		productType = "dsp"
	case "controllers":
		productType = "controller"
	case "i_o_endpoints":
		productType = "io_endpoint"
	case "additional_accessories":
		productType = "accessory"
	default:
		productType = "unknown"
	}

	// Create DBProduct
	product := &types.DBProduct{
		ProductID:   int(productID),
		ProductType: productType,
		ModelName:   modelName,
	}

	// Extract optional fields
	if modelFamily, ok := itemMap["model_family"].(string); ok {
		product.ModelFamily = modelFamily
	}

	if description, ok := itemMap["description"].(string); ok {
		product.Description = description
	}

	if shortDesc, ok := itemMap["short_description"].(string); ok {
		product.ShortDescription = shortDesc
	}

	// Convert complex fields to JSON strings
	if images, ok := itemMap["images"]; ok {
		if imagesJSON, err := json.Marshal(images); err == nil {
			product.Images = string(imagesJSON)
		}
	}

	// Extract specifications using field validator
	// Map category to validation product type
	validationProductType := validation.GetProductTypeFromCategory(category)
	if specificationsJSON, err := s.extractSpecificationsFromProductData(itemMap, validationProductType); err == nil && specificationsJSON != "" {
		product.Specifications = specificationsJSON
	}

	return product
}

// parseProductJSON parses JSON data into ProductData structure
func (s *Service) parseProductJSON(data []byte) (*types.ProductData, error) {
	// First, parse into a flexible structure to capture all fields
	var rawData map[string]interface{}
	if err := json.Unmarshal(data, &rawData); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	result := &types.ProductData{}

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

// parseProductArray parses an array of products from JSON
func (s *Service) parseProductArray(items []interface{}) ([]types.Product, error) {
	var products []types.Product

	for i, item := range items {
		itemMap, ok := item.(map[string]interface{})
		if !ok {
			return nil, fmt.Errorf("item %d is not a valid object", i)
		}

		product := types.Product{
			RawData: itemMap,
		}

		// Extract basic fields
		if id, ok := itemMap["id"].(float64); ok {
			product.ProductID = int(id)
		}
		if modelName, ok := itemMap["model_name"].(string); ok {
			product.ModelName = modelName
		}
		if modelFamily, ok := itemMap["model_family"].(string); ok {
			product.ModelFamily = modelFamily
		}
		if description, ok := itemMap["description"].(string); ok {
			product.Description = description
		}
		if shortDesc, ok := itemMap["short_description"].(string); ok {
			product.ShortDescription = shortDesc
		}
		if updatedAt, ok := itemMap["updated_at"].(string); ok {
			product.UpdatedAt = updatedAt
		}

		// Extract images array
		if images, ok := itemMap["images"].([]interface{}); ok {
			for _, img := range images {
				if imgMap, ok := img.(map[string]interface{}); ok {
					imageEntry := make(map[string][]string)
					for key, val := range imgMap {
						if arr, ok := val.([]interface{}); ok {
							strArr := make([]string, len(arr))
							for i, v := range arr {
								if str, ok := v.(string); ok {
									strArr[i] = str
								}
							}
							imageEntry[key] = strArr
						}
					}
					product.Images = append(product.Images, imageEntry)
				}
			}
		}

		products = append(products, product)
	}

	return products, nil
}

// validateProductJSON validates the structure of ProductData
func (s *Service) validateProductJSON(data *types.ProductData) error {
	if data == nil {
		return fmt.Errorf("product data is nil")
	}

	// Check if at least one product category exists
	totalProducts := len(data.Speakers) + len(data.Amplifiers) + len(data.DigitalSignalProcessors) +
		len(data.Controllers) + len(data.IOEndpoints) + len(data.AdditionalAccessories)

	if totalProducts == 0 {
		return fmt.Errorf("no products found in any category")
	}

	return nil
}

// gatherAllProducts collects all products from different categories
func (s *Service) gatherAllProducts(data *types.ProductData) []types.Product {
	var allProducts []types.Product

	allProducts = append(allProducts, data.Speakers...)
	allProducts = append(allProducts, data.Amplifiers...)
	allProducts = append(allProducts, data.DigitalSignalProcessors...)
	allProducts = append(allProducts, data.Controllers...)
	allProducts = append(allProducts, data.IOEndpoints...)
	allProducts = append(allProducts, data.AdditionalAccessories...)

	return allProducts
}

// groupProductsByCategory groups products by their original categories for concurrent processing
func (s *Service) groupProductsByCategory(products []types.Product, data *types.ProductData) []types.ProductCategoryGroup {
	categoryMap := make(map[string][]types.Product)

	for _, product := range products {
		// Determine category based on product ID presence in each category
		category := s.determineCategoryForProduct(product, data)
		categoryMap[category] = append(categoryMap[category], product)
	}

	var groups []types.ProductCategoryGroup
	for categoryName, categoryProducts := range categoryMap {
		groups = append(groups, types.ProductCategoryGroup{
			CategoryName: categoryName,
			CategoryType: s.mapCategoryToDBType(categoryName),
			Products:     categoryProducts,
		})
	}

	return groups
}

// determineCategoryForProduct determines which category a product belongs to
func (s *Service) determineCategoryForProduct(product types.Product, data *types.ProductData) string {
	// Check each category for the product ID
	for _, speaker := range data.Speakers {
		if speaker.ProductID == product.ProductID {
			return "speakers"
		}
	}
	for _, amplifier := range data.Amplifiers {
		if amplifier.ProductID == product.ProductID {
			return "amplifiers"
		}
	}
	for _, dsp := range data.DigitalSignalProcessors {
		if dsp.ProductID == product.ProductID {
			return "digital_signal_processors"
		}
	}
	for _, controller := range data.Controllers {
		if controller.ProductID == product.ProductID {
			return "controllers"
		}
	}
	for _, endpoint := range data.IOEndpoints {
		if endpoint.ProductID == product.ProductID {
			return "i_o_endpoints"
		}
	}
	for _, accessory := range data.AdditionalAccessories {
		if accessory.ProductID == product.ProductID {
			return "additional_accessories"
		}
	}
	return "unknown"
}

// mapCategoryToDBType maps JSON category names to database enum types
func (s *Service) mapCategoryToDBType(category string) string {
	switch category {
	case "speakers":
		return "speaker"
	case "amplifiers":
		return "amplifier"
	case "digital_signal_processors":
		return "dsp"
	case "controllers":
		return "controller"
	case "i_o_endpoints":
		return "io_endpoint"
	case "additional_accessories":
		return "accessory"
	default:
		return "unknown"
	}
}

// extractSKUFromRawData extracts SKU from raw data
func (s *Service) extractSKUFromRawData(rawData map[string]interface{}) int {
	if skus, ok := rawData["skus"].([]interface{}); ok && len(skus) > 0 {
		if sku, ok := skus[0].(float64); ok {
			return int(sku)
		}
	}
	return 0
}

// shouldUpdateProduct determines if a product needs to be updated
func (s *Service) shouldUpdateProduct(product types.Product, existingTimestamps map[int]*int64) bool {
	// If no existing timestamp data, product is new and should be synced
	_, exists := existingTimestamps[product.ProductID]
	if !exists {
		return true // Product doesn't exist in DB, needs to be inserted
	}

	// Product exists in DB - for now skip to avoid unnecessary updates
	// In a real implementation, you would compare updated timestamps
	return false
}

// validateSyncFields validates product fields using the comprehensive field validator
func (s *Service) validateSyncFields(product types.Product) []string {
	var warnings []string

	// Convert product to map for validation (using RawData if available)
	var productData map[string]interface{}
	if product.RawData != nil {
		productData = product.RawData
	} else {
		// Fallback: create map from product fields
		productData = map[string]interface{}{
			"id":                product.ProductID,
			"model_name":        product.ModelName,
			"model_family":      product.ModelFamily,
			"description":       product.Description,
			"short_description": product.ShortDescription,
			"updated_at":        product.UpdatedAt,
			"images":            product.Images,
		}
	}

	// Determine product type for validation (need to infer from category or type)
	productType := "generic" // default fallback
	if typeValue, exists := productData["type"]; exists {
		if typeStr, ok := typeValue.(string); ok {
			productType = validation.GetProductTypeFromCategory(typeStr)
		}
	}

	// Use field validator for comprehensive validation
	validationResult := s.validator.ValidateProductFields(productData, productType, product.ProductID)

	// Convert validation results to warning strings
	// Include required errors as warnings (since sync shouldn't fail completely)
	for _, reqError := range validationResult.RequiredErrors {
		warnings = append(warnings, fmt.Sprintf("Product %d: %s - %s (REQUIRED)",
			product.ProductID, reqError.FieldName, reqError.Suggestion))
	}

	// Include optional warnings
	for _, optWarning := range validationResult.OptionalWarnings {
		warnings = append(warnings, fmt.Sprintf("Product %d: %s - %s (optional)",
			product.ProductID, optWarning.FieldName, optWarning.Suggestion))
	}

	// Add compliance score as informational warning if low
	if validationResult.ComplianceScore < 80.0 {
		warnings = append(warnings, fmt.Sprintf("Product %d: Low compliance score %.1f%% (%d/%d fields)",
			product.ProductID, validationResult.ComplianceScore,
			validationResult.TotalIssues, len(s.validator.ProductTypeDefinitions[productType])))
	}

	return warnings
}

// BatchResult represents the result of processing a batch of products
type BatchResult struct {
	Successful         int
	Failed             int
	Errors             []string
	ValidationWarnings []string
}

// createProductBatches splits products into batches for processing
func (s *Service) createProductBatches(products []types.Product, batchSize int) [][]types.Product {
	if len(products) == 0 {
		return nil
	}

	var batches [][]types.Product
	for i := 0; i < len(products); i += batchSize {
		end := i + batchSize
		if end > len(products) {
			end = len(products)
		}
		batches = append(batches, products[i:end])
	}
	return batches
}

// processBatch processes a batch of products using database transactions for better performance
func (s *Service) processBatch(ctx context.Context, products []types.Product, productType string, validationEnabled bool, batchIndex int) *BatchResult {
	result := &BatchResult{
		Successful:         0,
		Failed:             0,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
	}

	// First, validate all products in the batch
	validProducts := make([]*types.DBProduct, 0, len(products))

	for _, product := range products {
		// Perform validation only for fields that are actually being synced
		if validationEnabled {
			// Validate only the fields we're actually processing in the sync
			syncValidationWarnings := s.validateSyncFields(product)
			result.ValidationWarnings = append(result.ValidationWarnings, syncValidationWarnings...)
		}

		// Transform to DBProduct
		dbProduct, err := s.convertProductToDBProduct(product, productType)
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Product %d transformation failed: %v", product.ProductID, err))
			result.Failed++
			continue
		}

		// Basic product validation
		if validationEnabled {
			if err := s.validateProduct(dbProduct); err != nil {
				result.ValidationWarnings = append(result.ValidationWarnings, fmt.Sprintf("Product %d basic validation: %v", product.ProductID, err))
			}
		}

		validProducts = append(validProducts, dbProduct)
	}

	// Process valid products in a single batch transaction
	if len(validProducts) > 0 {
		if err := s.dbService.InsertBatch(ctx, validProducts); err != nil {
			// If batch fails, fall back to individual processing with retry
			for _, dbProduct := range validProducts {
				if err := s.upsertProductWithRetry(dbProduct, 3); err != nil {
					result.Failed++
					result.Errors = append(result.Errors, fmt.Sprintf("Product %d individual insert failed: %v", dbProduct.ProductID, err))
				} else {
					result.Successful++
				}
			}
		} else {
			// Batch insert succeeded
			result.Successful += len(validProducts)
		}
	}

	return result
}

// upsertProductWithRetry upserts a product with retry logic
func (s *Service) upsertProductWithRetry(product *types.DBProduct, maxRetries int) error {
	for i := 0; i < maxRetries; i++ {
		if err := s.dbService.Upsert(context.Background(), product); err != nil {
			if i == maxRetries-1 {
				return err
			}
			time.Sleep(time.Millisecond * 100 * time.Duration(i+1)) // Exponential backoff
			continue
		}
		return nil
	}
	return fmt.Errorf("max retries exceeded")
}

// processCategoryGroup processes a group of products by category with comprehensive validation and batch processing
func (s *Service) processCategoryGroup(ctx context.Context, group types.ProductCategoryGroup, validationEnabled bool) *types.CategoryResult {
	startTime := time.Now()

	result := &types.CategoryResult{
		CategoryName:       group.CategoryName,
		Successful:         0,
		Failed:             0,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
	}

	// Use batch processing for better performance
	batchSize := s.processingCfg.BatchSize
	maxConcurrentBatches := s.processingCfg.MaxWorkers

	batches := s.createProductBatches(group.Products, batchSize)

	// Process batches concurrently up to maxConcurrentBatches
	batchResults := make([]*BatchResult, len(batches))
	semaphore := make(chan struct{}, maxConcurrentBatches)
	var wg sync.WaitGroup

	for i, batch := range batches {
		wg.Add(1)
		go func(batchIndex int, batchProducts []types.Product) {
			defer wg.Done()
			semaphore <- struct{}{}        // Acquire semaphore
			defer func() { <-semaphore }() // Release semaphore

			batchResult := s.processBatch(ctx, batchProducts, group.CategoryType, validationEnabled, batchIndex)
			batchResults[batchIndex] = batchResult
		}(i, batch)
	}

	// Wait for all batches to complete
	wg.Wait()

	// Aggregate batch results
	for _, batchResult := range batchResults {
		result.Successful += batchResult.Successful
		result.Failed += batchResult.Failed
		result.Errors = append(result.Errors, batchResult.Errors...)
		result.ValidationWarnings = append(result.ValidationWarnings, batchResult.ValidationWarnings...)
	}

	result.Duration = time.Since(startTime)
	return result
}

// convertProductToDBProduct converts a Product to DBProduct
func (s *Service) convertProductToDBProduct(product types.Product, productType string) (*types.DBProduct, error) {
	// Only require ProductID for conversion - let validation handle other missing fields
	if product.ProductID == 0 {
		return nil, fmt.Errorf("product ID is required")
	}

	dbProduct := &types.DBProduct{
		ProductID:        product.ProductID,
		ProductType:      productType,
		ModelName:        product.ModelName,        // Can be empty - validation will catch it
		ModelFamily:      product.ModelFamily,      // Can be empty - validation will catch it
		Description:      product.Description,      // Can be empty - validation will catch it
		ShortDescription: product.ShortDescription, // Can be empty - validation will catch it
	}

	// Convert images to JSON
	if len(product.Images) > 0 {
		if imagesJSON, err := json.Marshal(product.Images); err == nil {
			dbProduct.Images = string(imagesJSON)
		}
	}

	// Convert specifications from raw data (excluding metadata fields)
	if len(product.RawData) > 0 {
		// Create specifications object by copying raw data and excluding metadata fields
		specifications := make(map[string]interface{})
		excludeFields := map[string]bool{
			"id":                true,
			"skus":              true,
			"images":            true,
			"model_name":        true,
			"model_family":      true,
			"type":              true,
			"name":              true,
			"description":       true,
			"short_description": true,
			"created_at":        true,
			"updated_at":        true,
		}

		// Copy all fields except the excluded ones to specifications
		for key, value := range product.RawData {
			if !excludeFields[key] {
				specifications[key] = value
			}
		}

		// Debug: log what specifications we found
		fmt.Printf("DEBUG: Product ID %d - RawData keys: %d, Specifications keys: %d\n",
			product.ProductID, len(product.RawData), len(specifications))
		if len(specifications) > 0 {
			specKeys := make([]string, 0, len(specifications))
			for k := range specifications {
				specKeys = append(specKeys, k)
			}
			fmt.Printf("DEBUG: Product ID %d - Specification keys: %v\n", product.ProductID, specKeys)
		}

		// Only set specifications if there's actual specification data
		if len(specifications) > 0 {
			if specsJSON, err := json.Marshal(specifications); err == nil {
				dbProduct.Specifications = string(specsJSON)
				fmt.Printf("DEBUG: Product ID %d - Specifications JSON length: %d\n",
					product.ProductID, len(dbProduct.Specifications))
			} else {
				fmt.Printf("DEBUG: Product ID %d - Failed to marshal specifications: %v\n",
					product.ProductID, err)
			}
		} else {
			fmt.Printf("DEBUG: Product ID %d - No specifications found after filtering\n", product.ProductID)
		}
	} else {
		fmt.Printf("DEBUG: Product ID %d - No RawData available\n", product.ProductID)
	}

	return dbProduct, nil
}

// validateProduct validates a DBProduct
func (s *Service) validateProduct(product *types.DBProduct) error {
	if product == nil {
		return fmt.Errorf("product is nil")
	}
	if product.ProductID <= 0 {
		return fmt.Errorf("invalid product ID: %d", product.ProductID)
	}
	if product.ModelName == "" {
		return fmt.Errorf("model name is required")
	}
	if product.ProductType == "" {
		return fmt.Errorf("product type is required")
	}
	return nil
}

// getErrorSummary extracts error summary from error collector
func (s *Service) getErrorSummary(errorCollector *errors.ErrorCollector) *errors.ErrorSummary {
	summary := errorCollector.GetSummary()
	return &summary
}

func (s *Service) convertPriceToMap(price validation.PriceData) map[string]interface{} {
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

func (s *Service) convertToDBPrice(price validation.PriceData) *types.DBPrice {
	dbPrice := &types.DBPrice{
		ProductID: price.ProductID,
		Currency:  price.Currency,
		Amount:    price.Price,
	}

	dbPrice.Variant = price.Variant
	dbPrice.UpdatedAt = price.UpdatedAt
	dbPrice.CreatedAt = price.CreatedAt

	return dbPrice
}

// validateDBPrice validates the transformed database price
func (s *Service) validateDBPrice(dbPrice *types.DBPrice) error {
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

// processPrice processes an individual price with comprehensive validation and error handling
func (s *Service) processPrice(ctx context.Context, price validation.PriceData, goroutineID int, errorCollector *errors.ErrorCollector, validator *validation.FieldValidator, validationWarnings *[]string, warningsMutex *sync.Mutex) error {
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
	_, exists, err := s.dbService.LookupProductIDBySKU(ctx, price.ProductID)
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
		return fmt.Errorf("product %d not found", price.ProductID)
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
	err = s.dbService.UpsertPrice(ctx, dbPrice)
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

// DetectChangedPricesByTimestamp compares file timestamps with database timestamps to identify changed prices
func (s *Service) DetectChangedPricesByTimestamp(ctx context.Context, prices []validation.PriceData, logger *zap.Logger) ([]validation.PriceData, error) {
	if len(prices) == 0 {
		return nil, nil
	}

	// Build price keys for batch timestamp lookup
	var priceKeys []types.PriceKey
	priceMap := make(map[types.PriceKey]validation.PriceData)

	for _, price := range prices {
		variantKey := ""
		if price.Variant != nil {
			variantKey = *price.Variant
		}

		key := types.PriceKey{
			ProductID: price.ProductID,
			Currency:  price.Currency,
			Variant:   variantKey,
		}

		priceKeys = append(priceKeys, key)
		priceMap[key] = price
	}

	// Batch query existing timestamps
	dbTimestamps, err := s.dbService.GetPriceTimestamps(ctx, priceKeys)
	if err != nil {
		logger.Warn("Failed to get database price timestamps, processing all prices", zap.Error(err))
		return prices, nil // Fallback to processing all prices
	}

	// Compare and filter changed prices
	var changedPrices []validation.PriceData
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

// normalizePrices normalizes price data fields to handle different JSON field names
func (s *Service) normalizePrices(prices []validation.PriceData) []validation.PriceData {
	for i := range prices {
		price := &prices[i]

		if price.ProductID == 0 && price.SKU != 0 {
			price.ProductID = price.SKU
		}

		// Handle missing timestamps - set to nil if not present
		// This allows the price sync pipeline to handle both files with and without timestamps
		if price.CreatedAt != nil && *price.CreatedAt == "" {
			price.CreatedAt = nil
		}
		if price.UpdatedAt != nil && *price.UpdatedAt == "" {
			price.UpdatedAt = nil
		}

		// Remove self-assignment - no normalization needed for Price field
	}

	return prices
}

// shouldUpdatePrice determines if a price needs to be updated based on timestamps
func (s *Service) shouldUpdatePrice(price validation.PriceData, dbEpoch *int64) (bool, string) {
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

// extractPricesFromContainer extracts prices from RRP container format
func (s *Service) extractPricesFromContainer(container *validation.PriceContainer) []validation.PriceData {
	var allPrices []validation.PriceData

	for _, rrpEntry := range container.RRPData {
		for _, variant := range rrpEntry.Variants {
			variant.ProductID = rrpEntry.SKU
			variant.SKU = rrpEntry.SKU
			allPrices = append(allPrices, variant)
		}
	}

	return s.normalizePrices(allPrices)
}

// isSkipError checks if an error indicates the operation should be skipped rather than failed
func isSkipError(err error) bool {
	errorMsg := err.Error()
	isProductNotFound := strings.Contains(errorMsg, "not found")
	isProductSkip := strings.Contains(errorMsg, "skipping")
	return isProductNotFound || isProductSkip
}

// SyncPrices processes price data from JSON and syncs to database
func (s *Service) SyncPrices(ctx context.Context, data []byte, validationCfg *config.Validation) (*types.SyncResult, error) {
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

	var prices []validation.PriceData

	arrayErr := json.Unmarshal(data, &prices)
	if arrayErr != nil {
		var container validation.PriceContainer
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
		if err := s.validatePriceVersion(&container, validationCfg); err != nil {
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

	// Use batch processing for better performance and transactional integrity
	batchResult := s.processPricesBatch(ctx, changedPrices, validator, errorCollector, logger)

	result.Successful = batchResult.Successful
	result.Failed = batchResult.Failed
	result.Skipped = batchResult.Skipped + (len(prices) - len(changedPrices))
	result.ValidationWarnings = batchResult.ValidationWarnings
	result.Errors = append(result.Errors, batchResult.Errors...)
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

// PriceBatchResult holds the results of batch price processing
type PriceBatchResult struct {
	Successful         int
	Failed             int
	Skipped            int
	Errors             []string
	ValidationWarnings []string
}

// processPricesBatch processes prices in batches with transactions for better performance
func (s *Service) processPricesBatch(ctx context.Context, prices []validation.PriceData, validator *validation.FieldValidator, errorCollector *errors.ErrorCollector, logger *zap.Logger) *PriceBatchResult {
	result := &PriceBatchResult{
		Successful:         0,
		Failed:             0,
		Skipped:            0,
		Errors:             make([]string, 0),
		ValidationWarnings: make([]string, 0),
	}

	if len(prices) == 0 {
		return result
	}

	batchSize := 100 // Process in batches of 100
	newPricesOnly := make([]*types.DBPrice, 0)

	// Pre-fetch all existing product IDs in one batch query to avoid N+1 queries
	productIDs := make([]int, len(prices))
	for i, price := range prices {
		productIDs[i] = price.ProductID
	}

	existingProducts, err := s.dbService.BatchLookupExistingProductIDs(ctx, productIDs)
	if err != nil {
		logger.Warn("Failed to batch lookup product IDs, will skip product existence validation", zap.Error(err))
		existingProducts = make(map[int]bool) // Empty map - will skip existence check
	}

	logger.Info("Batch product lookup completed",
		zap.Int("total_prices", len(prices)),
		zap.Int("unique_products_found", len(existingProducts)),
	)

	// First pass: validate and filter new prices only
	for _, price := range prices {
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
				result.ValidationWarnings = append(result.ValidationWarnings, warnMsg)
				errorCollector.AddMissingOptionalFieldError(price.ProductID, optWarn.FieldName, optWarn.JSONPath, optWarn.Description)
			}
		}

		// If there are required field errors, skip the price
		if hasErrors {
			result.Failed++
			result.Errors = append(result.Errors, fmt.Sprintf("Price for product %d has required field validation failures", price.ProductID))
			continue
		}

		// Check if product exists using the pre-fetched map (O(1) lookup)
		if len(existingProducts) > 0 && !existingProducts[price.ProductID] {
			result.Skipped++
			continue
		}

		// Convert to database format
		dbPrice := s.convertToDBPrice(price)
		if err := s.validateDBPrice(dbPrice); err != nil {
			result.Failed++
			result.Errors = append(result.Errors, fmt.Sprintf("Price validation failed for product %d: %v", price.ProductID, err))
			continue
		}

		newPricesOnly = append(newPricesOnly, dbPrice)
	}

	logger.Info("Price validation completed",
		zap.Int("prices_to_insert", len(newPricesOnly)),
		zap.Int("skipped", result.Skipped),
		zap.Int("failed", result.Failed),
	)

	// Second pass: insert new prices in batches using transactions
	for i := 0; i < len(newPricesOnly); i += batchSize {
		end := i + batchSize
		if end > len(newPricesOnly) {
			end = len(newPricesOnly)
		}
		batch := newPricesOnly[i:end]

		if err := s.dbService.InsertPriceBatch(ctx, batch); err != nil {
			// If batch insert fails, try individual inserts
			logger.Warn("Batch insert failed, falling back to individual inserts", zap.Error(err))
			for _, dbPrice := range batch {
				if err := s.dbService.UpsertPrice(ctx, dbPrice); err != nil {
					result.Failed++
					result.Errors = append(result.Errors, fmt.Sprintf("Failed to insert price for product %d: %v", dbPrice.ProductID, err))
				} else {
					result.Successful++
				}
			}
		} else {
			result.Successful += len(batch)
			logger.Debug("Successfully inserted price batch", zap.Int("batch_size", len(batch)))
		}
	}

	return result
}

// validatePriceVersion validates that the price data version is supported
func (s *Service) validatePriceVersion(container *validation.PriceContainer, validationCfg *config.Validation) error {
	if validationCfg == nil {
		// If config is nil, skip version validation
		return nil
	}

	if !validationCfg.RequireVersion {
		// Version checking is disabled
		return nil
	}

	version := strings.TrimSpace(container.Version)
	if version == "" {
		if validationCfg.DefaultVersion != "" {
			// Use default version if none provided
			container.Version = validationCfg.DefaultVersion
			return nil
		}
		return fmt.Errorf("version field is required for price data but not provided")
	}

	// Check if version is supported
	// Check if version is supported
	for _, supportedVersion := range validationCfg.SupportedVersions {
		if version == supportedVersion {
			return nil
		}
	}

	return fmt.Errorf("unsupported price data version '%s'. Supported versions: %v",
		version, validationCfg.SupportedVersions)
}
