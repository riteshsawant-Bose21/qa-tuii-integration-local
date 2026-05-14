package bsf

import (
	"archive/zip"
	"bytes"
	"encoding/xml"
	"io"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

func newTestBSFRequest(isSubwoofer bool) *types.BSFGenerateRequest {
	return &types.BSFGenerateRequest{
		ProductName: "DM3SE",
		Family:      "DesignMax",
		Description: "Compact surface-mount speaker",
		SKU:         "841919-0110",
		IsSubwoofer: isSubwoofer,
		Category:    types.ComponentCategorySpeaker,
		SPMData:     []byte("binary spm measurement data"),
	}
}

// readZIPFiles opens a ZIP archive from raw bytes and returns a map of filename → content.
func readZIPFiles(t *testing.T, data []byte) map[string][]byte {
	t.Helper()
	r, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	require.NoError(t, err, "output should be a valid ZIP archive")

	files := make(map[string][]byte)
	for _, f := range r.File {
		rc, err := f.Open()
		require.NoError(t, err)
		content, err := io.ReadAll(rc)
		rc.Close()
		require.NoError(t, err)
		files[f.Name] = content
	}
	return files
}

// parseMainXML unmarshals the content of Main.xml into a bsfRoot struct.
func parseMainXML(t *testing.T, data []byte) bsfRoot {
	t.Helper()
	var root bsfRoot
	err := xml.Unmarshal(data, &root)
	require.NoError(t, err, "Main.xml should contain valid XML")
	return root
}

// ---------------------------------------------------------------------------
// NewBuilder
// ---------------------------------------------------------------------------

func TestNewBuilder_Speaker_ReturnsBuilder(t *testing.T) {
	builder, err := NewBuilder(types.ComponentCategorySpeaker)
	require.NoError(t, err)
	assert.NotNil(t, builder)
}

func TestNewBuilder_UnsupportedCategory_ReturnsError(t *testing.T) {
	builder, err := NewBuilder("unknown_category")
	assert.Error(t, err)
	assert.Nil(t, builder)
	assert.Contains(t, err.Error(), "unsupported component category")
}

func TestNewBuilder_EmptyCategory_ReturnsError(t *testing.T) {
	builder, err := NewBuilder("")
	assert.Error(t, err)
	assert.Nil(t, builder)
}

// ---------------------------------------------------------------------------
// ZIP structure
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_ProducesValidZIPArchive(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)
	require.NotEmpty(t, data)
	_, err = zip.NewReader(bytes.NewReader(data), int64(len(data)))
	assert.NoError(t, err)
}

func TestSpeakerBuilder_Build_ZIPContainsMainXML(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	_, ok := files["Main.xml"]
	assert.True(t, ok, "ZIP should contain Main.xml at the root")
}

func TestSpeakerBuilder_Build_ZIPContainsSPMFile(t *testing.T) {
	req := newTestBSFRequest(false)
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	spmKey := "Acoustical/" + req.ProductName + ".spm"
	spmContent, ok := files[spmKey]
	require.True(t, ok, "ZIP should contain %s", spmKey)
	assert.Equal(t, req.SPMData, spmContent, "SPM file content should match the input SPMData")
}

func TestSpeakerBuilder_Build_ZIPContainsMechanicalDirectory(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	_, ok := files["Mechanical/"]
	assert.True(t, ok, "ZIP should contain the empty Mechanical/ directory entry")
}

func TestSpeakerBuilder_Build_ZIPContainsResourcesDirectory(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	_, ok := files["Resources/"]
	assert.True(t, ok, "ZIP should contain the empty Resources/ directory entry")
}

func TestSpeakerBuilder_Build_MechanicalAndResourcesDirectoriesAreEmpty(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	assert.Empty(t, files["Mechanical/"], "Mechanical/ directory entry should have no content")
	assert.Empty(t, files["Resources/"], "Resources/ directory entry should have no content")
}

// ---------------------------------------------------------------------------
// Main.xml — schema and version attributes
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_MainXML_SchemaAndVersion(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, "1.0", root.Schema)
	assert.Equal(t, "1.0", root.Version)
}

// ---------------------------------------------------------------------------
// Main.xml — speaker type (midhigh vs sub)
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_MainXML_TypeIsMidhigh_WhenNotSubwoofer(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(false))
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, "midhigh", root.Info.Type)
}

func TestSpeakerBuilder_Build_MainXML_TypeIsSub_WhenSubwoofer(t *testing.T) {
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(newTestBSFRequest(true))
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, "sub", root.Info.Type)
}

// ---------------------------------------------------------------------------
// Main.xml — Info fields
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_MainXML_InfoFieldsMatchRequest(t *testing.T) {
	req := newTestBSFRequest(false)
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, req.ProductName, root.Info.Name)
	assert.Equal(t, req.Family, root.Info.Family)
	assert.Equal(t, req.Description, root.Info.Desc)
}

// ---------------------------------------------------------------------------
// Main.xml — BOM fields
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_MainXML_BOMFieldsMatchRequest(t *testing.T) {
	req := newTestBSFRequest(false)
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, req.ProductName, root.BOM.Item.Name)
	assert.Equal(t, req.SKU, root.BOM.Item.SKU)
	assert.Equal(t, req.Description, root.BOM.Item.Desc)
}

// ---------------------------------------------------------------------------
// Main.xml — Acoustical section
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_MainXML_AcousticalPathAndSPMFilename(t *testing.T) {
	req := newTestBSFRequest(false)
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	root := parseMainXML(t, readZIPFiles(t, data)["Main.xml"])
	assert.Equal(t, "Acoustical", root.Acoust.Path)
	assert.Equal(t, req.ProductName+".spm", root.Acoust.SPM)
}

// ---------------------------------------------------------------------------
// Edge cases
// ---------------------------------------------------------------------------

func TestSpeakerBuilder_Build_EmptySPMData_ProducesValidArchive(t *testing.T) {
	req := newTestBSFRequest(false)
	req.SPMData = []byte{}
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)

	data, err := builder.Build(req)
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	assert.Contains(t, files, "Main.xml", "ZIP should still contain Main.xml")
	spmKey := "Acoustical/" + req.ProductName + ".spm"
	spmContent, ok := files[spmKey]
	require.True(t, ok, "ZIP should still contain the SPM entry")
	assert.Empty(t, spmContent, "SPM entry should be empty when SPMData is empty")
}

func TestSpeakerBuilder_Build_ProductNameWithSpecialChars_UsedAsIs(t *testing.T) {
	req := newTestBSFRequest(false)
	req.ProductName = "DM-3SE_V2"
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	spmKey := "Acoustical/DM-3SE_V2.spm"
	_, ok := files[spmKey]
	assert.True(t, ok, "SPM path should use the product name verbatim")

	root := parseMainXML(t, files["Main.xml"])
	assert.Equal(t, "DM-3SE_V2", root.Info.Name)
	assert.Equal(t, "DM-3SE_V2.spm", root.Acoust.SPM)
}

func TestSpeakerBuilder_Build_LargeSPMData_ContentPreserved(t *testing.T) {
	req := newTestBSFRequest(false)
	req.SPMData = bytes.Repeat([]byte{0xAB, 0xCD, 0xEF}, 10000) // ~30KB binary data
	builder, _ := NewBuilder(types.ComponentCategorySpeaker)
	data, err := builder.Build(req)
	require.NoError(t, err)

	files := readZIPFiles(t, data)
	spmKey := "Acoustical/" + req.ProductName + ".spm"
	assert.Equal(t, req.SPMData, files[spmKey], "binary SPM data should be preserved exactly")
}
