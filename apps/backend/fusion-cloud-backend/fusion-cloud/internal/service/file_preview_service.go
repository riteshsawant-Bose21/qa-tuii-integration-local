package service

import (
	"fusion-cloud/internal/repository"
)

type FilePreviewService interface {
	GetFilePath(fileID string) (string, error)
}

type filePreviewService struct {
	repo repository.FilePreviewRepository
}

func NewFilePreviewService(r repository.FilePreviewRepository) FilePreviewService {
	return &filePreviewService{repo: r}
}

func (s *filePreviewService) GetFilePath(fileID string) (string, error) {
	return s.repo.GetFilePath(fileID)
}
