package repository

import (
	"fusion-cloud/internal/utils"
	"io"
	"os"
	"path/filepath"
)

type FileRepository interface {
	SaveFile(file io.Reader, filename string) (string, error)
	GetFilePath(fileID string) (string, error)
}

type fileRepository struct {
	baseDir string
}

func NewFileRepository(baseDir string) FileRepository {
	os.MkdirAll(baseDir, os.ModePerm)
	return &fileRepository{baseDir: baseDir}
}

func (r *fileRepository) SaveFile(file io.Reader, filename string) (string, error) {
	path := filepath.Join(r.baseDir, filename)
	dst, err := os.Create(path)
	if err != nil {
		return "", err
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if err != nil {
		return "", err
	}

	return filename, nil
}

func (r *fileRepository) GetFilePath(fileID string) (string, error) {
	path := filepath.Join(r.baseDir, fileID)

	if _, err := os.Stat(path); os.IsNotExist(err) {
		return "", utils.ErrFileNotFound
	} else if err != nil {
		return "", err
	}

	return path, nil
}
