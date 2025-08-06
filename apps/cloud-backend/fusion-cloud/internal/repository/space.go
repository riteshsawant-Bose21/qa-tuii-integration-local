package repository

import (
	"database/sql"
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/xyte"
)

type SpaceRepository struct {
	db      *sql.DB
	xyteSVC *xyte.Client
}

func NewSpace(db *sql.DB, xyteService *xyte.Client) *SpaceRepository {
	return &SpaceRepository{
		db:      db,
		xyteSVC: xyteService,
	}
}

func (o *SpaceRepository) GetAllSpaces() (*model.Space, error) {
	devices, err := o.xyteSVC.GetAllSpaces()
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%w", err)
	}

	if devices == nil {
		return nil, fmt.Errorf("no devices found")
	}

	return devices, nil
}

func (o *SpaceRepository) CreateSpace(space *model.SpaceRequest) (*model.Space, error) {
	spc, err := o.xyteSVC.CreateSpace(space)
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%w", err)
	}
	return spc, nil
}

func (o *SpaceRepository) UpdateSpace(space *model.SpaceRequest) (bool, error) {
	isUpdated, err := o.xyteSVC.UpdateSpace(space)
	if err != nil {
		return false, fmt.Errorf("xyte client error :%w", err)
	}
	return isUpdated, nil
}
func (o *SpaceRepository) DeleteSpace(id string) error {
	if err := o.xyteSVC.DeleteSpace(id); err != nil {
		return fmt.Errorf("xyte client error :%w", err)
	}
	return nil
}
