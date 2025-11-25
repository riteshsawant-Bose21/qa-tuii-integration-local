package db

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	models "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	syncTypes "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
)

// ProductService is a service for managing sync products in the database
type ProductService struct {
	db *Database
}

// NewProductService creates a new product database service
func NewProductService(db *Database) *ProductService {
	if db == nil {
		panic("db cannot be nil")
	}
	return &ProductService{
		db: db,
	}
}

// Insert inserts a single product into the database
func (s *ProductService) Insert(ctx context.Context, product *syncTypes.DBProduct) error {
	// Check if product exists
	existing, err := models.Products(qm.Where("product_id = ?", product.ProductID)).One(ctx, s.db.DB)

	var p *models.Product
	if err == sql.ErrNoRows {
		// Create new product
		p = &models.Product{
			ProductID:        product.ProductID,
			ProductType:      product.ProductType,
			ModelName:        product.ModelName,
			ShortDescription: null.StringFrom(product.ShortDescription),
		}

		// Set optional fields
		if product.ModelFamily != "" {
			p.ModelFamily = null.StringFrom(product.ModelFamily)
		}
		if product.Description != "" {
			p.Description = null.StringFrom(product.Description)
		}
		if product.Images != "" {
			p.Images = null.JSONFrom([]byte(product.Images))
		}
		if product.Specifications != "" {
			p.Specifications = null.JSONFrom([]byte(product.Specifications))
		}

		// Parse and set timestamps
		if product.CreatedAt != nil {
			if ts := parseTimestamp(*product.CreatedAt); ts != nil {
				p.CreatedAt = null.TimeFrom(*ts)
			}
		}
		if product.UpdatedAt != nil {
			if ts := parseTimestamp(*product.UpdatedAt); ts != nil {
				p.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if err := p.Insert(ctx, s.db.DB, boil.Infer()); err != nil {
			return fmt.Errorf("failed to insert product %d: %w", product.ProductID, err)
		}
	} else if err != nil {
		return fmt.Errorf("failed to check existing product %d: %w", product.ProductID, err)
	} else {
		// Update existing product
		existing.ModelName = product.ModelName
		existing.ProductType = product.ProductType
		existing.ShortDescription = null.StringFrom(product.ShortDescription)

		// Update optional fields
		if product.ModelFamily != "" {
			existing.ModelFamily = null.StringFrom(product.ModelFamily)
		}
		if product.Description != "" {
			existing.Description = null.StringFrom(product.Description)
		}
		if product.Images != "" {
			existing.Images = null.JSONFrom([]byte(product.Images))
		}
		if product.Specifications != "" {
			existing.Specifications = null.JSONFrom([]byte(product.Specifications))
		}
		// Parse and update timestamps
		if product.UpdatedAt != nil {
			if ts := parseTimestamp(*product.UpdatedAt); ts != nil {
				existing.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if _, err := existing.Update(ctx, s.db.DB, boil.Infer()); err != nil {
			return fmt.Errorf("failed to update product %d: %w", product.ProductID, err)
		}
	}

	return nil
}

// InsertBatch inserts multiple products within a single transaction
// If any product fails to insert/update, the entire batch is rolled back
func (s *ProductService) InsertBatch(ctx context.Context, products []*syncTypes.DBProduct) error {
	if len(products) == 0 {
		return nil
	}

	return s.db.WithTransaction(ctx, func(tx *sql.Tx) error {
		for _, product := range products {
			if err := s.insertInTx(ctx, tx, product); err != nil {
				return err
			}
		}
		return nil
	})
}

// insertInTx inserts or updates a single product using a transaction executor
func (s *ProductService) insertInTx(ctx context.Context, exec boil.ContextExecutor, product *syncTypes.DBProduct) error {
	// Check if product exists
	existing, err := models.Products(qm.Where("product_id = ?", product.ProductID)).One(ctx, exec)

	var p *models.Product
	if err == sql.ErrNoRows {
		// Create new product
		p = &models.Product{
			ProductID:        product.ProductID,
			ProductType:      product.ProductType,
			ModelName:        product.ModelName,
			ShortDescription: null.StringFrom(product.ShortDescription),
		}

		// Set optional fields
		if product.ModelFamily != "" {
			p.ModelFamily = null.StringFrom(product.ModelFamily)
		}
		if product.Description != "" {
			p.Description = null.StringFrom(product.Description)
		}
		if product.Images != "" {
			p.Images = null.JSONFrom([]byte(product.Images))
		}
		if product.Specifications != "" {
			p.Specifications = null.JSONFrom([]byte(product.Specifications))
		}

		// Parse and set timestamps
		if product.CreatedAt != nil {
			if ts := parseTimestamp(*product.CreatedAt); ts != nil {
				p.CreatedAt = null.TimeFrom(*ts)
			}
		}
		if product.UpdatedAt != nil {
			if ts := parseTimestamp(*product.UpdatedAt); ts != nil {
				p.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if err := p.Insert(ctx, exec, boil.Infer()); err != nil {
			return fmt.Errorf("failed to insert product %d: %w", product.ProductID, err)
		}
	} else if err != nil {
		return fmt.Errorf("failed to check existing product %d: %w", product.ProductID, err)
	} else {
		// Update existing product
		existing.ModelName = product.ModelName
		existing.ProductType = product.ProductType
		existing.ShortDescription = null.StringFrom(product.ShortDescription)

		// Update optional fields
		if product.ModelFamily != "" {
			existing.ModelFamily = null.StringFrom(product.ModelFamily)
		}
		if product.Description != "" {
			existing.Description = null.StringFrom(product.Description)
		}
		if product.Images != "" {
			existing.Images = null.JSONFrom([]byte(product.Images))
		}
		if product.Specifications != "" {
			existing.Specifications = null.JSONFrom([]byte(product.Specifications))
		}
		// Parse and update timestamps
		if product.UpdatedAt != nil {
			if ts := parseTimestamp(*product.UpdatedAt); ts != nil {
				existing.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if _, err := existing.Update(ctx, exec, boil.Infer()); err != nil {
			return fmt.Errorf("failed to update product %d: %w", product.ProductID, err)
		}
	}

	return nil
}

// parseTimestamp parses various timestamp formats to time.Time
func parseTimestamp(timestamp string) *time.Time {
	// Handle empty timestamp
	if strings.TrimSpace(timestamp) == "" {
		return nil
	}

	layouts := []string{
		time.RFC3339,
		"2006-01-02T15:04:05Z",
		"2006-01-02 15:04:05",
		"1136239445", // Unix timestamp as string
	}

	for _, layout := range layouts {
		if t, err := time.Parse(layout, timestamp); err == nil {
			return &t
		}
	}

	return nil
}

// InsertWithRetry inserts a product with retry logic
func (s *ProductService) InsertWithRetry(ctx context.Context, product *syncTypes.DBProduct, maxRetries int, retryDelay time.Duration) error {
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
func (s *ProductService) LookupProductIDBySKU(ctx context.Context, sku int) (int, bool, error) {
	product, err := models.Products(qm.Where("product_id = ?", sku)).One(ctx, s.db.DB)
	if err == sql.ErrNoRows {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return product.ProductID, true, nil
}

// GetProductTimestamps retrieves updated_at timestamps for multiple products
func (s *ProductService) GetProductTimestamps(ctx context.Context, productIDs []int) (map[int]*int64, error) {
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

	rows, err := s.db.DB.QueryContext(ctx, query, args...)
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
