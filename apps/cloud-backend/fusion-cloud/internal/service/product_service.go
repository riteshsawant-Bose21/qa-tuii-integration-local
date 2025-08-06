package service

import (
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
)

type ProductService interface {
	GetProducts() ([]model.Product, error)
	GetFilteredByKeywords() ([]model.Product, error)
}

type productService struct {
	repo repository.ProductRepository
}

func NewProductService(repo repository.ProductRepository) ProductService {
	return &productService{repo: repo}
}

func (s *productService) GetProducts() ([]model.Product, error) {
	return s.repo.GetAllProducts()
}

func (s *productService) GetFilteredByKeywords() ([]model.Product, error) {
	all, err := s.repo.GetAllProducts()
	if err != nil {
		return nil, err
	}

	return utils.FilterProductsByKeywords(all), nil
}
