package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// ---------------------------------------------------------------------------
// Mock BSF service
// ---------------------------------------------------------------------------

type MockBSFService struct {
	mock.Mock
}

func (m *MockBSFService) Generate(ctx context.Context, req *types.BSFGenerateRequest, logger *zap.Logger) (*types.BSFGenerateResponse, error) {
	args := m.Called(ctx, req, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.BSFGenerateResponse), args.Error(1)
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

// buildBSFRequest creates a multipart HTTP request for the BSF generate endpoint.
// Pass fileName="" to omit the spm_file part entirely.
func buildBSFRequest(t *testing.T, fields map[string]string, fileName string, fileContent []byte) *http.Request {
	t.Helper()
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	for key, value := range fields {
		require.NoError(t, writer.WriteField(key, value))
	}
	if fileName != "" {
		part, err := writer.CreateFormFile("spm_file", fileName)
		require.NoError(t, err)
		_, err = part.Write(fileContent)
		require.NoError(t, err)
	}
	require.NoError(t, writer.Close())

	req, err := http.NewRequest(http.MethodPost, "/bsf/generate", body)
	require.NoError(t, err)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	return req
}

// newBSFTestContext creates a gin.Context wired with a multipart request and a logger.
func newBSFTestContext(t *testing.T, fields map[string]string, fileName string, fileContent []byte) (*httptest.ResponseRecorder, *gin.Context) {
	t.Helper()
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = buildBSFRequest(t, fields, fileName, fileContent)
	logger, _ := zap.NewDevelopment()
	c.Set("logger", logger)
	return w, c
}

// defaultFields returns the minimum required form fields for a valid request.
func defaultFields() map[string]string {
	return map[string]string{
		"product_name": "DM3SE",
		"family":       "DesignMax",
		"description":  "Compact surface-mount speaker",
	}
}

const (
	bsfTestSPMFileName = "DM3SE.spm"
	bsfTestBSFURL      = "https://example.com/product/BSF/DesignMax/DM3SE_123.bsf"
)

var bsfTestSPMData = []byte("binary spm data")

// successMock returns a MockBSFService pre-configured to return a success response.
func successMock() *MockBSFService {
	m := &MockBSFService{}
	m.On("Generate", mock.Anything, mock.Anything, mock.Anything).
		Return(&types.BSFGenerateResponse{BSFURL: bsfTestBSFURL}, nil)
	return m
}

// capturingMock returns a MockBSFService that captures the BSFGenerateRequest passed to Generate.
func capturingMock(captured **types.BSFGenerateRequest) *MockBSFService {
	m := &MockBSFService{}
	m.On("Generate", mock.Anything, mock.Anything, mock.Anything).
		Run(func(args mock.Arguments) {
			*captured = args.Get(1).(*types.BSFGenerateRequest)
		}).
		Return(&types.BSFGenerateResponse{BSFURL: bsfTestBSFURL}, nil)
	return m
}

// ---------------------------------------------------------------------------
// Validation: required text fields
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_MissingProductName_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	fields := defaultFields()
	delete(fields, "product_name")
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, "product_name")
}

func TestBSFHandler_Generate_BlankProductName_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	fields := defaultFields()
	fields["product_name"] = "   "
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestBSFHandler_Generate_MissingFamily_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	fields := defaultFields()
	delete(fields, "family")
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, "family")
}

func TestBSFHandler_Generate_MissingDescription_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	fields := defaultFields()
	delete(fields, "description")
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, "description")
}

// ---------------------------------------------------------------------------
// Validation: SPM file
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_MissingSPMFile_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	// No file attached
	w, c := newBSFTestContext(t, defaultFields(), "", nil)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, "spm_file")
}

func TestBSFHandler_Generate_WrongFileExtension_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	w, c := newBSFTestContext(t, defaultFields(), "measurement.txt", bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, ".spm")
}

func TestBSFHandler_Generate_NoFileExtension_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	w, c := newBSFTestContext(t, defaultFields(), "DM3SE", bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestBSFHandler_Generate_UppercaseSPMExtension_IsAccepted(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(successMock())

	// .SPM uppercase — handler should lower-case before comparing
	w, c := newBSFTestContext(t, defaultFields(), "DM3SE.SPM", bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusCreated, w.Code)
}

// ---------------------------------------------------------------------------
// Validation: category
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_InvalidCategory_Returns400(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewBSFHandler(&MockBSFService{})

	fields := defaultFields()
	fields["category"] = "slider"
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp types.ErrorResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp.ErrorMessage, "unsupported category")
}

// ---------------------------------------------------------------------------
// Service error → 500
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_ServiceReturnsError_Returns500(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockSvc := &MockBSFService{}
	mockSvc.On("Generate", mock.Anything, mock.Anything, mock.Anything).
		Return(nil, errors.New("S3 unavailable"))
	h := NewBSFHandler(mockSvc)

	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
	mockSvc.AssertExpectations(t)
}

// ---------------------------------------------------------------------------
// Success
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_Success_Returns201WithBSFURL(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockSvc := successMock()
	h := NewBSFHandler(mockSvc)

	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	assert.Equal(t, http.StatusCreated, w.Code)
	var resp types.BSFGenerateResponse
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, bsfTestBSFURL, resp.BSFURL)
	mockSvc.AssertExpectations(t)
}

// ---------------------------------------------------------------------------
// Default values applied by handler
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_EmptySKU_DefaultsToHyphen(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	// no sku field
	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, "-", captured.SKU, "empty SKU should default to '-'")
}

func TestBSFHandler_Generate_ExplicitSKU_IsPassedThrough(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	fields := defaultFields()
	fields["sku"] = "841919-0110"
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, "841919-0110", captured.SKU)
}

func TestBSFHandler_Generate_NoCategory_DefaultsToSpeaker(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	// no category field
	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, types.ComponentCategorySpeaker, captured.Category)
}

// ---------------------------------------------------------------------------
// IsSubwoofer flag
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_IsSubwooferTrue_PassedToService(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	fields := defaultFields()
	fields["is_subwoofer"] = "true"
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.True(t, captured.IsSubwoofer)
}

func TestBSFHandler_Generate_IsSubwooferOmitted_DefaultsFalse(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.False(t, captured.IsSubwoofer)
}

func TestBSFHandler_Generate_IsSubwooferFalseExplicit_PassedAsExpected(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	fields := defaultFields()
	fields["is_subwoofer"] = "false"
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.False(t, captured.IsSubwoofer)
}

// ---------------------------------------------------------------------------
// Whitespace trimming
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_WhitespaceTrimmedFromTextFields(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	fields := map[string]string{
		"product_name": "  DM3SE  ",
		"family":       "  DesignMax  ",
		"description":  "  A speaker  ",
		"sku":          "  SKU-001  ",
	}
	w, c := newBSFTestContext(t, fields, bsfTestSPMFileName, bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, "DM3SE", captured.ProductName)
	assert.Equal(t, "DesignMax", captured.Family)
	assert.Equal(t, "A speaker", captured.Description)
	assert.Equal(t, "SKU-001", captured.SKU)
}

// ---------------------------------------------------------------------------
// SPM data passthrough
// ---------------------------------------------------------------------------

func TestBSFHandler_Generate_SPMDataIsPassedToService(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	specificSPMData := []byte("specific binary spm measurement bytes 0xAB 0xCD")
	w, c := newBSFTestContext(t, defaultFields(), bsfTestSPMFileName, specificSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, specificSPMData, captured.SPMData)
}

func TestBSFHandler_Generate_ProductNameAndFamilyPassedCorrectly(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var captured *types.BSFGenerateRequest
	h := NewBSFHandler(capturingMock(&captured))

	fields := defaultFields()
	fields["product_name"] = "AM10"
	fields["family"] = "ArenaMatch"
	w, c := newBSFTestContext(t, fields, "AM10.spm", bsfTestSPMData)

	h.Generate(c)

	require.Equal(t, http.StatusCreated, w.Code)
	require.NotNil(t, captured)
	assert.Equal(t, "AM10", captured.ProductName)
	assert.Equal(t, "ArenaMatch", captured.Family)
}
