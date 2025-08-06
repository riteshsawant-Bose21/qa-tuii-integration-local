package handler

import (
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type FileHandler struct {
	service service.FileService
}

func NewFileHandler(s service.FileService) *FileHandler {
	return &FileHandler{service: s}
}

func (h *FileHandler) RegisterRoutes(r chi.Router) {
	r.Post("/upload", h.UploadFile)
	r.Get("/{fileId}", h.GetFile)
}

// UploadFile godoc
// @Summary      Upload a file
// @Description  Uploads a file and returns the file ID
// @Tags         file
// @Accept       multipart/form-data
// @Produce      json
// @Param        file formData file true "File to upload"
// @Success      200 {object} utils.APIResponse
// @Failure      400 {object} utils.APIResponse
// @Failure      500 {object} utils.APIResponse
// @Router       /files/upload [post]
func (h *FileHandler) UploadFile(w http.ResponseWriter, r *http.Request) {
	file, header, err := r.FormFile("file")
	if err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgFileInvalidFileUpload, nil)
		return
	}
	defer file.Close()

	id := uuid.New().String()
	fileID, err := h.service.SaveFile(file, header.Filename, id)
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgFailedToSaveFile, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgFileUploaded, map[string]string{"fileId": fileID})
}

// GetFile godoc
// @Summary      Get a file
// @Description  Downloads a file using file ID
// @Tags         file
// @Produce      octet-stream
// @Param        fileId path string true "File ID"
// @Success      200 {file} file
// @Failure      404 {object} utils.APIResponse
// @Router       /files/{fileId} [get]
func (h *FileHandler) GetFile(w http.ResponseWriter, r *http.Request) {
	fileID := r.PathValue("fileId")
	path, err := h.service.GetFilePath(fileID)
	if err != nil {
		utils.Respond(w, http.StatusNotFound, constants.StatusError, constants.MsgFileNotFound, nil)
		return
	}

	http.ServeFile(w, r, path)
}
