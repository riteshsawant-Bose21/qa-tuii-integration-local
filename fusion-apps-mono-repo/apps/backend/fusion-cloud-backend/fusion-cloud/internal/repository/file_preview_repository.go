package repository

import (
	"fusion-cloud/internal/utils"
	"os"
	"path/filepath"
)

type FilePreviewRepository interface {
	GetFilePath(fileID string) (string, error)
}

type filePreviewRepository struct {
	baseDir string
}

func NewFilePreviewRepository(baseDir string) FilePreviewRepository {
	os.MkdirAll(baseDir, os.ModePerm)
	return &filePreviewRepository{baseDir: baseDir}
}

func (r *filePreviewRepository) GetFilePath(fileID string) (string, error) {
	path := filepath.Join(r.baseDir, fileID)

	if _, err := os.Stat(path); os.IsNotExist(err) {
		return "", utils.ErrFileNotFound
	} else if err != nil {
		return "", err
	}

	return path, nil
}
