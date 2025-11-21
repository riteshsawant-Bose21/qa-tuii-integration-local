package db

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

var (
	ProductTable string = model.TableNames.Products
)

var (
	ProductColumnID          string = model.ProductColumns.ID
	ProductColumnName        string = model.ProductColumns.Category
	ProductColumnDescription string = model.ProductColumns.Description
	ProductColumnPrice       string = model.ProductColumns.Price
	ProductColumnMetaInfo    string = model.ProductColumns.MetaInfo
	ProductColumnUpdatedAt   string = model.ProductColumns.UpdatedAt
	ProductColumnCreatedAt   string = model.ProductColumns.CreatedAt
)

var (
	productPrimaryKeyColumns = []string{ProductColumnID}
)

// newProduct returns a new Product node from the provided Product row
func (s *Service) newProduct(row *model.ProductSlice) (*types.ProductResponse, error) {
	if row == nil {
		return nil, nil
	}

	var node types.ProductResponse
	for _, r := range *row {
		if r == nil {
			continue
		}
		switch r.Category {
		case types.ProductCategorySpeaker:
			speaker := types.Speaker{}
			if r.ID == 0 {
				return nil, fmt.Errorf("product ID is required for speaker")
			}
			speaker.ID = r.ID
			if r.MetaInfo == nil {
				return nil, fmt.Errorf("mesta info is required for speaker")
			}
			var meta types.Speaker_meta_response
			if err := r.MetaInfo.Unmarshal(&meta); err != nil {
				return nil, fmt.Errorf("failed to unmarshal meta info for speaker: %w", err)
			}
			speaker.MetaInfo = meta
			node.Speakers = append(node.Speakers, speaker)
		case types.ProductCategoryAmplifier:
			amplifier := types.Amplifier{}
			if r.ID == 0 {
				return nil, fmt.Errorf("product ID is required for amplifier")
			}
			amplifier.ID = r.ID
			if r.MetaInfo == nil {
				return nil, fmt.Errorf("meta info is required for amplifier")
			}
			var meta types.Amplifier_meta_response
			if err := r.MetaInfo.Unmarshal(&meta); err != nil {
				return nil, fmt.Errorf("failed to unmarshal meta info for amplifier: %w", err)
			}
			amplifier.MetaInfo = meta
			node.Amplifiers = append(node.Amplifiers, amplifier)
		case types.ProductCategoryDigitalSignalProcessor:
			dsp := types.DigitalSignalProcessor{}
			if r.ID == 0 {
				return nil, fmt.Errorf("product ID is required for dsp")
			}
			dsp.ID = r.ID
			if r.MetaInfo == nil {
				return nil, fmt.Errorf("meta info is required for dsp")
			}
			var meta any
			if err := r.MetaInfo.Unmarshal(&meta); err != nil {
				return nil, fmt.Errorf("failed to unmarshal meta info for dsp: %w", err)
			}
			dsp.MetaInfo = types.DSP_meta{}
			node.DigitalSignalProcessors = append(node.DigitalSignalProcessors, dsp)
		default:
			return nil, fmt.Errorf("unknown product category: %s", r.Category)
		}
	}
	return &node, nil
}

// newProducts returns the list of Product nodes from the provided Product rows
// func (s *Service) newProducts(rows *model.ProductSlice) ([]*fusion.Product, error) {
// 	if len(rows) == 0 {
// 		return nil, nil
// 	}

// 	nodes := make([]*fusion.Product, len(rows))
// 	for i, row := range rows {
// 		if row != nil {
// 			node, err := s.newProduct(row)
// 			if err != nil {
// 				return nil, fmt.Errorf("can't parse row in pos %v", err)
// 			}
// 			nodes[i] = node
// 		}
// 	}

// 	return nodes, nil
// }
