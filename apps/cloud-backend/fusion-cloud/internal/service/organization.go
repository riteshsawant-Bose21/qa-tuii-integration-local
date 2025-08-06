package service

import (
	"fmt"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/repository"
	"fusion-cloud/internal/utils"
	"fusion-cloud/internal/utils/jwtutil"
)

type Organization struct {
	repo       *repository.Organization
	jwtManager *jwtutil.JWTManager
}

func NewOrganization(orgRepo *repository.Organization, jwt *jwtutil.JWTManager) *Organization {
	return &Organization{
		repo:       orgRepo,
		jwtManager: jwt,
	}
}

func (o *Organization) GETOrganization() (*model.Organization, error) {
	org, err := o.repo.GetOrganization()
	if err != nil {
		return nil, fmt.Errorf("error while getting org in service: %w", err)
	}
	if org == nil {
		return nil, utils.ErrOrganizationNotFound
	}
	return org, nil
}
