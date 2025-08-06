package service

import (
	"fusion-cloud/internal/repository"
	"io"
	"path/filepath"
)

type FileService interface {
	SaveFile(file io.Reader, originalName, id string) (string, error)
	GetFilePath(fileID string) (string, error)
}

type fileService struct {
	repo repository.FileRepository
}

func NewFileService(r repository.FileRepository) FileService {
	return &fileService{repo: r}
}

func (s *fileService) SaveFile(file io.Reader, originalName, id string) (string, error) {
	filename := id + filepath.Ext(originalName)
	return s.repo.SaveFile(file, filename)
}

func (s *fileService) GetFilePath(fileID string) (string, error) {
	return s.repo.GetFilePath(fileID)
}
