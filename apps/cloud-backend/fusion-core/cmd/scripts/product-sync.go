package main

import (
	"context"
	"encoding/json"
	"fmt"
	inbuiltlog "log"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"go.uber.org/zap"
)

func main() {
	logger, err := log.NewProduction()
	if err != nil {
		inbuiltlog.Fatalf("Error while initializing the logger: %v\n", err)
	}

	logger.Info("Initializing the API server...")

	logger.Info(fmt.Sprintf("Starting Product Sync Script in %s mode", "production"))

	pgs, err := sql.New(
		sql.PostgresOpener,
		"127.0.0.1",    // host
		"5432",         // port
		"fusion_cloud", // user
		"bose123",      // password
		"fusion_cloud", // instance (example: database name)
	)
	if err != nil {
		logger.Fatal("Failed to connect to the database", zap.Error(err))
	}

	logger.Info("Database connection established successfully")

	s3, err := cloudfs.NewS3Client(context.Background())
	if err != nil {
		logger.Fatal("Failed to initialize S3 client", zap.Error(err))
	}
	logger.Info("Initialized S3 Client.")

	// Initialize ID Service
	idSVC := id.NewService()
	if idSVC == nil {
		logger.Fatal("Failed to initialize ID service")
	}
	logger.Info("Initialized ID Service.")

	// Initaialize Product Service
	//DB first
	productDBSvc := productdb.NewService(pgs)
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}
	logger.Info("Initialized Product DB Service.")

	// Service
	productSVC := product.NewService(productDBSvc, idSVC)
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	// Bucket Handle
	bucket := s3.Bucket("fusion-products")
	if bucket == nil {
		logger.Fatal("Failed to get bucket handle")
	}
	logger.Info("Got Bucket Handle.")

	// Get list of products from S3
	obj := bucket.Object("products.json")

	ctx := context.Background()
	reader, err := obj.NewReader(ctx)
	if err != nil {
		logger.Fatal("Failed to get products from S3", zap.Error(err))
	}
	defer reader.Close()

	var products *types.ProductFetch
	decoder := json.NewDecoder(reader)

	if err := decoder.Decode(&products); err != nil {
		logger.Fatal("Failed to get products from S3", zap.Error(err))
	}

	if products == nil {
		logger.Fatal("No products found in S3")
	}
	// Sync products to database

	if products.Speakers != nil || len(products.Speakers) > 0 {
		logger.Info(fmt.Sprintf("Found %d speakers in S3", len(products.Speakers)))

		for _, product := range products.Speakers {
			// Check if product already exists in database
			// existingProduct, err := productSVC.GetProductByID(context.Background(), product.ID)
			// if err != nil {
			// 	logger.Fatal("Failed to check if product exists in database", zap.Error(err))
			// }
			// if existingProduct != nil {
			// 	logger.Info(fmt.Sprintf("Product %s already exists in database, skipping", product.ID))
			// 	continue
			// }

			// If not, create a new product entry
			newProduct := &types.ProductFetch{}
			err = productSVC.UpdateProducts(context.Background(), newProduct)
			if err != nil {
				logger.Fatal("Failed to create product in database", zap.Error(err))
			}
			logger.Info(fmt.Sprintf("Created product %d in database", product.ID))
		}
	}

	logger.Info("Product sync completed successfully")
}
