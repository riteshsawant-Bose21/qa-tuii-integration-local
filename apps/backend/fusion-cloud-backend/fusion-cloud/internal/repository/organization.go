package repository

import (
	"database/sql"
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/xyte"
)

type Organization struct {
	db      *sql.DB
	xyteSVC *xyte.Client
}

func NewOrganization(db *sql.DB, xyteService *xyte.Client) *Organization {
	return &Organization{
		db:      db,
		xyteSVC: xyteService,
	}
}

func (o *Organization) GetOrganization() (*model.Organization, error) {
	org, err := o.xyteSVC.GetOrganizationDetails()
	if err != nil {
		return nil, fmt.Errorf("xyte client error :%v", err)
	}

	return org, nil
}
