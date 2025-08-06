package handler

import (
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
	"net/http"

	"github.com/go-chi/chi/v5"
)

type FilePreviewHandler struct {
	service service.FilePreviewService
}

func NewFilePreviewHandler(s service.FilePreviewService) *FilePreviewHandler {
	return &FilePreviewHandler{service: s}
}

func (h *FilePreviewHandler) RegisterRoutes(r chi.Router) {
	r.Get("/{fileId}", h.GetFile)
}

// GetFile godoc
// @Summary      Get a file
// @Description  Downloads a file using file ID
// @Tags         file
// @Produce      octet-stream
// @Param        fileId path string true "File ID"
// @Success      200 {file} file
// @Failure      404 {object} utils.APIResponse
// @Router       /file-preview/{fileId} [get]
func (h *FilePreviewHandler) GetFile(w http.ResponseWriter, r *http.Request) {
	fileID := r.PathValue("fileId")
	path, err := h.service.GetFilePath(fileID)
	if err != nil {
		utils.Respond(w, http.StatusNotFound, constants.StatusError, constants.MsgFileNotFound, nil)
		return
	}

	http.ServeFile(w, r, path)
}
