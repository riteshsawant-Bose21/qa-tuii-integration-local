package repository

import (
	"encoding/json"
	"os"
	"path/filepath"

	"fusion-cloud/internal/model"
	"fusion-cloud/internal/utils"
)

type ProductRepository interface {
	GetAllProducts() ([]model.Product, error)
}

type productRepository struct {
	jsonPath string
}

func NewProductRepository(jsonPath string) ProductRepository {
	return &productRepository{jsonPath: jsonPath}
}

func (r *productRepository) GetAllProducts() ([]model.Product, error) {
	file, err := os.ReadFile(filepath.Clean(r.jsonPath))
	if err != nil {
		return nil, err
	}

	var rawProducts []map[string]interface{}
	if err := json.Unmarshal(file, &rawProducts); err != nil {
		return nil, err
	}

	var products []model.Product
	for _, raw := range rawProducts {
		formatted := utils.FormatProductFields(raw)
		p := utils.MapToStruct(formatted)
		products = append(products, p)
	}

	return products, nil
}

