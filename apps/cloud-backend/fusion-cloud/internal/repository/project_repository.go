package repository

import (
	"database/sql"
	"fusion-cloud/internal/model"
)

type ProjectRepository struct {
	db *sql.DB
}

func NewProjectRepository(db *sql.DB) *ProjectRepository {
	return &ProjectRepository{db: db}
}

func (r *ProjectRepository) Create(project *model.ProjectRequest, ownerId int64) (int64, error) {
	query := `INSERT INTO projects (name, description, owner_id, metadata) VALUES (?, ?, ?, ?)`
	result, err := r.db.Exec(query, project.Name, project.Description, ownerId, project.MetaData)
	if err != nil {
		return 0, err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return id, nil
}

func (r *ProjectRepository) FindByNameAndOwner(name string, ownerID int64) (*model.Project, error) {
	query := `SELECT id, name, description, owner_id, metadata, created_at, updated_at FROM projects WHERE name = ? AND owner_id = ?`
	var project model.Project
	err := r.db.QueryRow(query, name, ownerID).Scan(
		&project.ID,
		&project.Name,
		&project.Description,
		&project.OwnerID,
		&project.MetaData,
		&project.CreatedAt,
		&project.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil // No project found
		}
		return nil, err // Some other error occurred
	}
	return &project, nil
}

func (r *ProjectRepository) FindByOwner(ownerID int64) ([]model.Project, error) {
	query := `SELECT id, name, description, owner_id, metadata, created_at, updated_at FROM projects WHERE owner_id = ?`
	rows, err := r.db.Query(query, ownerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var projects []model.Project
	for rows.Next() {
		var project model.Project
		if err := rows.Scan(
			&project.ID,
			&project.Name,
			&project.Description,
			&project.OwnerID,
			&project.MetaData,
			&project.CreatedAt,
			&project.UpdatedAt,
		); err != nil {
			return nil, err
		}
		projects = append(projects, project)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return projects, nil
}

func (r *ProjectRepository) FindByID(ownerId int64, projectId string) (*model.Project, error) {
	query := `SELECT id, name, description, owner_id, metadata, created_at, updated_at FROM projects WHERE id = ? AND owner_id = ?`
	var project model.Project
	err := r.db.QueryRow(query, projectId, ownerId).Scan(
		&project.ID,
		&project.Name,
		&project.Description,
		&project.OwnerID,
		&project.MetaData,
		&project.CreatedAt,
		&project.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil // No project found
		}
		return nil, err // Some other error occurred
	}
	return &project, nil
}

func (r *ProjectRepository) Update(ownerId int64, projectId string, project *model.ProjectRequest) error {
	query := `UPDATE projects SET name = ?, description = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP  WHERE id = ? AND owner_id = ?`
	_, err := r.db.Exec(query, project.Name, project.Description, project.MetaData, projectId, ownerId)
	if err != nil {
		return err
	}
	return err
}

func (r *ProjectRepository) Delete(ownerId int64, projectId string) error {
	query := `DELETE FROM projects WHERE id = ? AND owner_id = ?`
	_, err := r.db.Exec(query, projectId, ownerId)
	if err != nil {
		return err
	}
	return nil
}
