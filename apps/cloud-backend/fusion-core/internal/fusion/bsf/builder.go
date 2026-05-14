// Package bsf provides BSF (Bose Specification File) archive generation.
// A BSF file is a ZIP archive containing XML metadata and acoustical measurement data
// used by the audio simulation engine.
package bsf

import (
	"archive/zip"
	"bytes"
	"encoding/xml"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Builder constructs BSF archives for a given component category.
type Builder interface {
	Build(req *types.BSFGenerateRequest) ([]byte, error)
}

// NewBuilder returns a Builder for the given component category.
// Returns an error if the category is not supported.
func NewBuilder(category types.ComponentCategory) (Builder, error) {
	switch category {
	case types.ComponentCategorySpeaker:
		return &speakerBuilder{}, nil
	default:
		return nil, fmt.Errorf("unsupported component category: %s", category)
	}
}

// --- XML structs for Main.xml ---

type bsfRoot struct {
	XMLName xml.Name      `xml:"Root"`
	Schema  string        `xml:"schema,attr"`
	Version string        `xml:"version,attr"`
	Info    bsfInfo       `xml:"Info"`
	BOM     bsfBOM        `xml:"BOM"`
	Acoust  bsfAcoustical `xml:"Acoustical"`
}

type bsfInfo struct {
	Type   string `xml:"Type"`
	Name   string `xml:"Name"`
	Family string `xml:"Family"`
	Desc   string `xml:"Desc"`
}

type bsfBOM struct {
	Item bsfBOMItem `xml:"Item"`
}

type bsfBOMItem struct {
	Name string `xml:"Name"`
	SKU  string `xml:"SKU"`
	Desc string `xml:"Desc"`
}

type bsfAcoustical struct {
	Path string `xml:"path,attr"`
	SPM  string `xml:"SPM"`
}

// --- Speaker builder ---

type speakerBuilder struct{}

func (b *speakerBuilder) Build(req *types.BSFGenerateRequest) ([]byte, error) {
	xmlBytes, err := b.buildMainXML(req)
	if err != nil {
		return nil, fmt.Errorf("failed to build Main.xml: %w", err)
	}

	return b.packZIP(req, xmlBytes)
}

func (b *speakerBuilder) buildMainXML(req *types.BSFGenerateRequest) ([]byte, error) {
	speakerType := "midhigh"
	if req.IsSubwoofer {
		speakerType = "sub"
	}

	root := bsfRoot{
		Schema:  "1.0",
		Version: "1.0",
		Info: bsfInfo{
			Type:   speakerType,
			Name:   req.ProductName,
			Family: req.Family,
			Desc:   req.Description,
		},
		BOM: bsfBOM{
			Item: bsfBOMItem{
				Name: req.ProductName,
				SKU:  req.SKU,
				Desc: req.Description,
			},
		},
		Acoust: bsfAcoustical{
			Path: "Acoustical",
			SPM:  req.ProductName + ".spm",
		},
	}

	output, err := xml.MarshalIndent(root, "", "  ")
	if err != nil {
		return nil, err
	}

	// Prepend XML declaration
	declaration := []byte(xml.Header)
	return append(declaration, output...), nil
}

func (b *speakerBuilder) packZIP(req *types.BSFGenerateRequest, mainXML []byte) ([]byte, error) {
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)

	// Main.xml at root
	w, err := zw.Create("Main.xml")
	if err != nil {
		return nil, fmt.Errorf("failed to create Main.xml entry: %w", err)
	}
	if _, err := w.Write(mainXML); err != nil {
		return nil, fmt.Errorf("failed to write Main.xml: %w", err)
	}

	// Acoustical/{product_name}.spm
	spmPath := fmt.Sprintf("Acoustical/%s.spm", req.ProductName)
	w, err = zw.Create(spmPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create SPM entry: %w", err)
	}
	if _, err := w.Write(req.SPMData); err != nil {
		return nil, fmt.Errorf("failed to write SPM data: %w", err)
	}

	// Empty directory entries
	for _, dir := range []string{"Mechanical/", "Resources/"} {
		if _, err := zw.Create(dir); err != nil {
			return nil, fmt.Errorf("failed to create directory entry %s: %w", dir, err)
		}
	}

	if err := zw.Close(); err != nil {
		return nil, fmt.Errorf("failed to finalize ZIP: %w", err)
	}

	return buf.Bytes(), nil
}
