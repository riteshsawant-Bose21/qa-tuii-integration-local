package utils

import (
	"encoding/json"
	"fusion-cloud/internal/model"
	"strings"
)

var productKeywords = []string{
	"DM3C",
	"DM5C",
	"DM6C",
	"DM8C",
	"1204",
	"2404D",
	"4804D",
	// Add more keywords as needed
}

func StructToMap(p model.Product) map[string]interface{} {
	var m map[string]interface{}
	data, _ := json.Marshal(p)
	_ = json.Unmarshal(data, &m)
	return m
}

func MapToStruct(m map[string]interface{}) model.Product {
	var p model.Product
	data, _ := json.Marshal(m)
	_ = json.Unmarshal(data, &p)
	return p
}

func FilterProductsByKeywords(products []model.Product) []model.Product {
	var filtered []model.Product

	for _, product := range products {
		name := strings.ToLower(product.Name)

		for _, keyword := range productKeywords {
			if strings.Contains(name, strings.ToLower(keyword)) {
				// Convert struct → map
				productMap := StructToMap(product)

				// Inject keyword
				productMap["custom_name"] = keyword

				// Format fields BEFORE unmarshalling
				formattedMap := FormatProductFields(productMap)

				// Convert map → struct
				finalProduct := MapToStruct(formattedMap)

				filtered = append(filtered, finalProduct)
				break
			}
		}
	}

	return filtered
}
