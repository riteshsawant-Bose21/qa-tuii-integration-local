package handler

import (
	"fmt"
	"io"
	"path/filepath"
	"strings"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// BSFHandler handles BSF generation HTTP requests.
type BSFHandler struct {
	bsf fusion.BSF
}

// NewBSFHandler creates a new BSF handler.
func NewBSFHandler(bsf fusion.BSF) *BSFHandler {
	return &BSFHandler{bsf: bsf}
}

// Generate handles POST requests to generate a BSF file.
// @Summary Generate BSF File
// @Description Generates a BSF (Bose Specification File) from the provided product metadata and SPM file, uploads it to S3, and returns the download URL.
// @Tags BSF
// @Accept multipart/form-data
// @Produce json
// @Param product_name formData string true "Product name (e.g. DM3SE)"
// @Param family formData string true "Product family (e.g. DesignMax)"
// @Param description formData string true "Product description"
// @Param sku formData string false "Product SKU (default: -)"
// @Param is_subwoofer formData bool false "Whether the product is a subwoofer (default: false)"
// @Param category formData string false "Component category (default: speaker)"
// @Param spm_file formData file true "SPM measurement file"
// @Success 201 {object} types.BSFGenerateResponse "BSF file generated and uploaded"
// @Failure 400 {object} types.ErrorResponse "Missing or invalid input"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /bsf/generate [post]
func (h *BSFHandler) Generate(c *gin.Context) {
	logger := log.GetLogger(c)
	logger = logger.With(zap.String("handler", "BSFGenerate"))

	// Parse required fields
	productName := strings.TrimSpace(c.PostForm("product_name"))
	family := strings.TrimSpace(c.PostForm("family"))
	description := strings.TrimSpace(c.PostForm("description"))

	if productName == "" {
		response.BadRequest(c, "product_name is required")
		return
	}
	if family == "" {
		response.BadRequest(c, "family is required")
		return
	}
	if description == "" {
		response.BadRequest(c, "description is required")
		return
	}

	// Optional fields
	sku := strings.TrimSpace(c.PostForm("sku"))
	if sku == "" {
		sku = "-"
	}

	isSubwoofer := c.PostForm("is_subwoofer") == "true"

	categoryStr := strings.TrimSpace(c.PostForm("category"))
	if categoryStr == "" {
		categoryStr = string(types.ComponentCategorySpeaker)
	}
	category := types.ComponentCategory(categoryStr)
	if _, ok := types.ValidCategories[category]; !ok {
		response.BadRequest(c, fmt.Sprintf("unsupported category %q, valid values: speaker", categoryStr))
		return
	}

	// Parse SPM file upload
	fileHeader, err := c.FormFile("spm_file")
	if err != nil {
		logger.Error("Failed to read spm_file from form", zap.Error(err))
		response.BadRequest(c, "spm_file is required")
		return
	}

	if ext := strings.ToLower(filepath.Ext(fileHeader.Filename)); ext != ".spm" {
		response.BadRequest(c, fmt.Sprintf("invalid file type %q, only .spm files are allowed", ext))
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		logger.Error("Failed to open uploaded spm_file", zap.Error(err))
		response.InternalError(c)
		return
	}
	defer file.Close()

	spmData, err := io.ReadAll(file)
	if err != nil {
		logger.Error("Failed to read spm_file content", zap.Error(err))
		response.InternalError(c)
		return
	}

	req := &types.BSFGenerateRequest{
		ProductName: productName,
		Family:      family,
		Description: description,
		SKU:         sku,
		IsSubwoofer: isSubwoofer,
		Category:    category,
		SPMData:     spmData,
	}

	result, err := h.bsf.Generate(c, req, logger)
	if err != nil {
		logger.Error("Failed to generate BSF", zap.Error(err))
		response.InternalError(c)
		return
	}

	response.Created(c, result)
}
