package id

import (
	"encoding/base64"
)

type Service struct {
	// Add fields as necessary, e.g., a database connection or configuration settings.
}

// type IDService interface {
// 	// Define methods for the ID service, e.g., GenerateID, ValidateID, etc.
// 	EncryptID(id string) (string, error)
// 	DecryptID(encryptedID string) (string, error)
// 	GenerateID() (string, error)
// 	IsValidID(id string) bool
// }

// NewService creates a new instance of the ID service.
func NewService() *Service {
	return &Service{}
}

// Implement the methods defined in the IDService interface.

func (s *Service) EncryptID(id string) (string, error) {
	// Implement encryption logic here.
	base64.NewEncoder(base64.StdEncoding, nil)
	return id, nil
}

func (s *Service) DecryptID(encryptedID string) (string, error) {
	// Implement decryption logic here.
	return encryptedID, nil
}

// func GetProductsTableID(id string) (int, error) {
// 	tid, err := getSmallTableID(models.TableNames.Products, id)
// 	if err != nil {
// 		return 0, fmt.Errorf("invalid id %s: %w", id, err)
// 	}

// 	return tid, nil
// }

// func getSmallID(tableName string, tid int) string {
// 	return base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%d", tableName, tid)))
// }

// // getBigID returns the id of an object constructed from the given table name and the id of the object.
// func getBigID(tableName string, tid int64) string {
// 	return base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%d", tableName, tid)))
// }

// // getSmallTableID returns the table ID of an object from the given table name and the ID of the object.
// func getSmallTableID(tableName, id string) (int, error) {
// 	gotName, tid, err := GetSmallTableNameAndID(id)
// 	if err != nil {
// 		return 0, fmt.Errorf("can't parse id: %v", err)
// 	}

// 	if gotName != tableName {
// 		return 0, fmt.Errorf("invalid table name %s", gotName)
// 	}

// 	return tid, err
// }

// // getBigTableID returns the table ID of an object from the given table name and the ID of the object.
// func getBigTableID(tableName, id string) (int64, error) {
// 	gotName, tid, err := GetBigTableNameAndID(id)
// 	if err != nil {
// 		return 0, fmt.Errorf("can't parse id: %v", err)
// 	}

// 	if gotName != tableName {
// 		return 0, fmt.Errorf("invalid table name %s", gotName)
// 	}

// 	return tid, err
// }
