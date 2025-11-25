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
	"github.com/aarondl/sqlboiler/v4/types"
	"github.com/ericlagergren/decimal"
)

// PriceService is a service for managing sync prices in the database
type PriceService struct {
	db *Database
}

// NewPriceService creates a new price database service
func NewPriceService(db *Database) *PriceService {
	if db == nil {
		panic("db cannot be nil")
	}
	return &PriceService{
		db: db,
	}
}

// UpsertPrice inserts or updates a price record with variant support
func (s *PriceService) UpsertPrice(ctx context.Context, price *syncTypes.DBPrice) error {
	// Build query conditions for variant support
	var conditions []qm.QueryMod
	conditions = append(conditions, qm.Where("product_id = ?", price.ProductID))
	conditions = append(conditions, qm.Where("currency = ?", price.Currency))

	// Handle variant: check for null or specific value
	if price.Variant != nil && *price.Variant != "" {
		conditions = append(conditions, qm.Where("variant = ?", *price.Variant))
	} else {
		conditions = append(conditions, qm.Where("variant IS NULL"))
	}

	// Check if price exists
	existing, err := models.ProductPrices(conditions...).One(ctx, s.db.DB)

	// Convert amount to types.Decimal
	var bigDecimal decimal.Big
	bigDecimal.SetFloat64(price.Amount)
	amount := types.NewDecimal(&bigDecimal)

	if err == sql.ErrNoRows {
		// Create new price record
		p := &models.ProductPrice{
			ProductID: price.ProductID,
			Currency:  price.Currency,
			Price:     amount,
		}

		// Set variant if provided
		if price.Variant != nil && *price.Variant != "" {
			p.Variant = null.StringFrom(*price.Variant)
		}

		// Set created_at if provided
		if price.CreatedAt != nil {
			if ts := parseTimestamp(*price.CreatedAt); ts != nil {
				p.CreatedAt = null.TimeFrom(*ts)
			}
		}

		// Set updated_at if provided
		if price.UpdatedAt != nil {
			if ts := parseTimestamp(*price.UpdatedAt); ts != nil {
				p.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if err := p.Insert(ctx, s.db.DB, boil.Infer()); err != nil {
			return fmt.Errorf("failed to insert price for product %d: %w", price.ProductID, err)
		}
	} else if err != nil {
		return fmt.Errorf("failed to check existing price for product %d: %w", price.ProductID, err)
	} else {
		// Update existing price
		existing.Price = amount

		// Update variant if provided
		if price.Variant != nil && *price.Variant != "" {
			existing.Variant = null.StringFrom(*price.Variant)
		}

		// Update timestamp if provided
		if price.UpdatedAt != nil {
			if ts := parseTimestamp(*price.UpdatedAt); ts != nil {
				existing.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if _, err := existing.Update(ctx, s.db.DB, boil.Infer()); err != nil {
			return fmt.Errorf("failed to update price for product %d: %w", price.ProductID, err)
		}
	}

	return nil
}

// UpsertBatch upserts multiple prices within a single transaction
// If any price fails to upsert, the entire batch is rolled back
func (s *PriceService) UpsertBatch(ctx context.Context, prices []*syncTypes.DBPrice) error {
	if len(prices) == 0 {
		return nil
	}

	return s.db.WithTransaction(ctx, func(tx *sql.Tx) error {
		for _, price := range prices {
			if err := s.upsertInTx(ctx, tx, price); err != nil {
				return err
			}
		}
		return nil
	})
}

// upsertInTx performs upsert using a transaction executor
func (s *PriceService) upsertInTx(ctx context.Context, exec boil.ContextExecutor, price *syncTypes.DBPrice) error {
	// Build query conditions for variant support
	var conditions []qm.QueryMod
	conditions = append(conditions, qm.Where("product_id = ?", price.ProductID))
	conditions = append(conditions, qm.Where("currency = ?", price.Currency))

	// Handle variant: check for null or specific value
	if price.Variant != nil && *price.Variant != "" {
		conditions = append(conditions, qm.Where("variant = ?", *price.Variant))
	} else {
		conditions = append(conditions, qm.Where("variant IS NULL"))
	}

	// Check if price exists
	existing, err := models.ProductPrices(conditions...).One(ctx, exec)

	// Convert amount to types.Decimal
	var bigDecimal decimal.Big
	bigDecimal.SetFloat64(price.Amount)
	amount := types.NewDecimal(&bigDecimal)

	if err == sql.ErrNoRows {
		// Create new price record
		p := &models.ProductPrice{
			ProductID: price.ProductID,
			Currency:  price.Currency,
			Price:     amount,
		}

		// Set variant if provided
		if price.Variant != nil && *price.Variant != "" {
			p.Variant = null.StringFrom(*price.Variant)
		}

		// Set created_at if provided
		if price.CreatedAt != nil {
			if ts := parseTimestamp(*price.CreatedAt); ts != nil {
				p.CreatedAt = null.TimeFrom(*ts)
			}
		}

		// Set updated_at if provided
		if price.UpdatedAt != nil {
			if ts := parseTimestamp(*price.UpdatedAt); ts != nil {
				p.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if err := p.Insert(ctx, exec, boil.Infer()); err != nil {
			return fmt.Errorf("failed to insert price for product %d: %w", price.ProductID, err)
		}
	} else if err != nil {
		return fmt.Errorf("failed to check existing price for product %d: %w", price.ProductID, err)
	} else {
		// Update existing price
		existing.Price = amount

		// Update variant if provided
		if price.Variant != nil && *price.Variant != "" {
			existing.Variant = null.StringFrom(*price.Variant)
		}

		// Update timestamp if provided
		if price.UpdatedAt != nil {
			if ts := parseTimestamp(*price.UpdatedAt); ts != nil {
				existing.UpdatedAt = null.TimeFrom(*ts)
			}
		}

		if _, err := existing.Update(ctx, exec, boil.Infer()); err != nil {
			return fmt.Errorf("failed to update price for product %d: %w", price.ProductID, err)
		}
	}

	return nil
}

// GetPriceByProductID retrieves a price by product ID
func (s *PriceService) GetPriceByProductID(ctx context.Context, productID int) (*syncTypes.DBPrice, error) {
	price, err := models.ProductPrices(
		qm.Where("product_id = ?", productID),
	).One(ctx, s.db.DB)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get price: %w", err)
	}

	// Convert decimal to float64
	amountFloat, _ := price.Price.Float64()

	result := &syncTypes.DBPrice{
		ProductID: price.ProductID,
		Currency:  price.Currency,
		Amount:    amountFloat,
	}

	// Set variant if present
	if price.Variant.Valid {
		result.Variant = &price.Variant.String
	}

	// Convert updated_at timestamp if present
	if price.UpdatedAt.Valid {
		timestamp := price.UpdatedAt.Time.Format(time.RFC3339)
		result.UpdatedAt = &timestamp
	}

	// Convert created_at timestamp if present
	if price.CreatedAt.Valid {
		timestamp := price.CreatedAt.Time.Format(time.RFC3339)
		result.CreatedAt = &timestamp
	}

	return result, nil
}

// GetPriceTimestamps retrieves updated_at timestamps for multiple price records in a batch
func (s *PriceService) GetPriceTimestamps(ctx context.Context, priceKeys []syncTypes.PriceKey) (map[syncTypes.PriceKey]*int64, error) {
	if len(priceKeys) == 0 {
		return make(map[syncTypes.PriceKey]*int64), nil
	}

	// Build SQL query with OR conditions for all price keys
	var conditions []string
	var args []interface{}
	argIndex := 1

	for _, key := range priceKeys {
		// Handle variant: use COALESCE to treat NULL as empty string
		variantCondition := fmt.Sprintf("COALESCE(variant, '') = $%d", argIndex+2)
		condition := fmt.Sprintf("(product_id = $%d AND currency = $%d AND %s)", argIndex, argIndex+1, variantCondition)
		conditions = append(conditions, condition)

		args = append(args, key.ProductID, key.Currency, key.Variant)
		argIndex += 3
	}

	query := fmt.Sprintf(`
		SELECT product_id, currency, COALESCE(variant, ''), EXTRACT(epoch FROM updated_at)::bigint 
		FROM product_price 
		WHERE %s
	`, strings.Join(conditions, " OR "))

	rows, err := s.db.DB.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to get price timestamps: %w", err)
	}
	defer rows.Close()

	timestamps := make(map[syncTypes.PriceKey]*int64)

	for rows.Next() {
		var productID int
		var currency, variant string
		var epoch sql.NullInt64

		if err := rows.Scan(&productID, &currency, &variant, &epoch); err != nil {
			return nil, fmt.Errorf("failed to scan price timestamp row: %w", err)
		}

		key := syncTypes.PriceKey{
			ProductID: productID,
			Currency:  currency,
			Variant:   variant,
		}

		if epoch.Valid {
			epochValue := epoch.Int64
			timestamps[key] = &epochValue
		} else {
			timestamps[key] = nil
		}
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating price timestamp rows: %w", err)
	}

	return timestamps, nil
}
