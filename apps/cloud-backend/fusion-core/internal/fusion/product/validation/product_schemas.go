package validation

import (
	"reflect"
	"strings"
)

// BaseProduct defines common fields for all products
type BaseProduct struct {
	ProductID   int    `json:"id" validate:"required,type:number,positive" description:"Unique product identifier"`
	ModelName   string `json:"model_name" validate:"required,type:string,not_empty,max_length:255" description:"Product model name"`
	ModelFamily string `json:"model_family" validate:"required,type:string,not_empty,max_length:255" description:"Product family/series"`
	Description string `json:"description" validate:"required,type:string,not_empty" description:"Product description"`
	ShortDesc   string `json:"short_description" validate:"optional,type:string" description:"Short product description"`
	Images      []any  `json:"images" validate:"optional,type:array" description:"Product images"`
	SKUs        []any  `json:"skus" validate:"optional,type:array" description:"Associated SKU numbers"`
	UpdatedAt   string `json:"updated_at" validate:"optional,type:string" description:"Last update timestamp"`
}

// Speaker defines speaker-specific fields
type Speaker struct {
	BaseProduct

	// Required fields for speakers
	PowerHandling        any    `json:"power_handling" validate:"required,type:object" description:"Power handling specifications"`
	Sensitivity          any    `json:"sensitivity" validate:"required,type:object" description:"Speaker sensitivity specifications"`
	FrequencyRange       any    `json:"frequency_range" validate:"required,type:object" description:"Operating frequency range"`
	NominalImpedance     any    `json:"nominal_impedance" validate:"required,type:object" description:"Nominal impedance specification"`
	MaxSPL               any    `json:"max_spl" validate:"required,type:object" description:"Maximum sound pressure level"`
	Coverage             []any  `json:"coverage" validate:"required,type:array" description:"Coverage pattern specifications"`
	Environment          string `json:"environment" validate:"required,type:string" description:"Installation environment"`
	MountType            string `json:"mount_type" validate:"required,type:string" description:"Mounting type"`
	IsSubwoofer          bool   `json:"is_subwoofer" validate:"required,type:boolean" description:"Subwoofer indicator"`
	IsWeatherRated       bool   `json:"is_weather_rated" validate:"required,type:boolean" description:"Weather resistance indicator"`
	IsHighImpedanceRated bool   `json:"is_high_impedance_rated" validate:"required,type:boolean" description:"High impedance capability"`

	// Optional fields for speakers
	BSFFileURL        string `json:"bsf_file_url" validate:"required,type:string,not_empty" description:"BSF configuration file URL"`
	ImpedanceRange    any    `json:"impedance" validate:"optional,type:object" description:"Impedance range specification"`
	AvailableTaps     any    `json:"available_taps" validate:"optional,type:object" description:"Available transformer taps"`
	HighImpedanceTaps []any  `json:"high_impedance_taps" validate:"optional,type:array" description:"High impedance tap values"`
}

// Amplifier defines amplifier-specific fields
type Amplifier struct {
	BaseProduct

	// Required fields for amplifiers
	PowerOutput              any `json:"power_output" validate:"required,type:object" description:"Power output specifications"`
	NumberOfInputsAndOutputs any `json:"number_of_inputs_and_outputs" validate:"required,type:object" description:"Number of inputs and outputs"`
	PowerConsumption         any `json:"power" validate:"required,type:object" description:"Power consumption specifications"`
	SpeakerInputs            int `json:"number_of_loudspeaker_inputs" validate:"required,type:number" description:"Number of loudspeaker inputs"`
}

// DigitalSignalProcessor defines DSP-specific fields
type DigitalSignalProcessor struct {
	BaseProduct

	// Required fields for DSPs
	NumberOfInputsAndOutputs any `json:"number_of_inputs_and_outputs" validate:"required,type:object" description:"Number of inputs and outputs"`
	MaxDigitalControl        int `json:"max_number_of_digital_control" validate:"required,type:number" description:"Maximum digital control inputs"`
	MaxAnalogControl         int `json:"max_number_of_analog_control" validate:"required,type:number" description:"Maximum analog control inputs"`
	GPIOLogicPorts           any `json:"gpio_logic_ports" validate:"required,type:object" description:"GPIO logic port specifications"`
}

// Controller defines controller-specific fields
type Controller struct {
	BaseProduct

	// Required fields for controllers
	ZoneControlCount  string `json:"zone_control_count" validate:"required,type:string" description:"Number of zones controllable"`
	ControlType       string `json:"control_type" validate:"required,type:string" description:"Type of control interface"`
	AdditionalSensors []any  `json:"additional_sensors" validate:"required,type:array" description:"Additional sensor capabilities"`
	PhysicalSize      string `json:"physical_size" validate:"required,type:string" description:"Physical dimensions/form factor"`
	ApplicableRegions []any  `json:"applicable_regions" validate:"required,type:array" description:"Supported geographic regions"`
}

// IOEndpoint defines I/O endpoint-specific fields
type IOEndpoint struct {
	BaseProduct

	// Required fields for I/O endpoints
	Inputs  any  `json:"inputs" validate:"required,type:object" description:"Input specifications"`
	Outputs any  `json:"outputs" validate:"required,type:object" description:"Output specifications"`
	Network bool `json:"network" validate:"required,type:boolean" description:"Network capability indicator"`
}

// Accessory defines accessory-specific fields
type Accessory struct {
	BaseProduct

	// Required fields for accessories
	Type     string `json:"type" validate:"required,type:string" description:"Accessory type"`
	Quantity int    `json:"quantity" validate:"required,type:number" description:"Quantity included"`
	// Override the optional SKUs from BaseProduct to make it required for accessories
	SKUsRequired []any `json:"skus" validate:"required,type:array" description:"Associated SKU numbers (required for accessories)"`
}

// PriceData defines price data fields
// PriceContainer represents the top-level price data structure with variants
type PriceContainer struct {
	SKU      int         `json:"sku" validate:"required,type:number,positive" description:"Product SKU identifier"`
	Variants []PriceData `json:"variants" validate:"required,type:array" description:"Price variants array"`
}

// PriceData represents an individual price record
type PriceData struct {
	ProductID int     `json:"product_id" validate:"required,type:number,positive" description:"Product ID identifier"`
	SKU       int     `json:"sku" validate:"required,type:number,positive" description:"Product SKU identifier"`
	Currency  string  `json:"currency" validate:"required,type:string,not_empty,min_length:3,max_length:3" description:"Currency code"`
	Price     float64 `json:"price" validate:"required,type:number,positive" description:"Price value"`
	Variant   *string `json:"variant" validate:"optional,type:string" description:"Product variant (color, size, etc.)"`
	CreatedAt *string `json:"created_at" validate:"optional,type:string" description:"Creation timestamp"`
	UpdatedAt *string `json:"updated_at" validate:"optional,type:string" description:"Last update timestamp"`
}

// ProductTypes maps product type names to their struct types
var ProductTypes = map[string]reflect.Type{
	"speaker":                  reflect.TypeOf(Speaker{}),
	"amplifier":                reflect.TypeOf(Amplifier{}),
	"digital_signal_processor": reflect.TypeOf(DigitalSignalProcessor{}),
	"controller":               reflect.TypeOf(Controller{}),
	"i_o_endpoint":             reflect.TypeOf(IOEndpoint{}),
	"additional_accessories":   reflect.TypeOf(Accessory{}),
	"generic":                  reflect.TypeOf(BaseProduct{}),
}

// GenerateFieldDefinitionsFromStruct extracts field definitions from struct tags
func GenerateFieldDefinitionsFromStruct(structType reflect.Type) []FieldDefinition {
	var fields []FieldDefinition

	// Process all fields including embedded ones
	for i := 0; i < structType.NumField(); i++ {
		field := structType.Field(i)

		// Handle embedded structs (like BaseProduct)
		if field.Anonymous && field.Type.Kind() == reflect.Struct {
			embeddedFields := GenerateFieldDefinitionsFromStruct(field.Type)
			fields = append(fields, embeddedFields...)
			continue
		}

		// Parse validation tags
		validateTag := field.Tag.Get("validate")
		if validateTag == "" {
			continue
		}

		jsonTag := field.Tag.Get("json")
		descriptionTag := field.Tag.Get("description")

		fieldDef := parseFieldDefinition(field.Name, jsonTag, validateTag, descriptionTag)
		if fieldDef != nil {
			fields = append(fields, *fieldDef)
		}
	}

	return fields
}

// parseFieldDefinition converts struct tag information to FieldDefinition
func parseFieldDefinition(fieldName, jsonTag, validateTag, description string) *FieldDefinition {
	if validateTag == "" {
		return nil
	}

	// Parse JSON path
	jsonPath := fieldName
	if jsonTag != "" {
		parts := strings.Split(jsonTag, ",")
		if parts[0] != "" && parts[0] != "-" {
			jsonPath = parts[0]
		}
	}

	// Parse validation rules
	rules := strings.Split(validateTag, ",")

	var requirement FieldRequirement = Required // default to required
	var fieldType string
	constraints := make(map[string]string)

	for _, rule := range rules {
		rule = strings.TrimSpace(rule)

		if strings.Contains(rule, ":") {
			// Handle key:value rules like "type:number", "max_length:255"
			parts := strings.SplitN(rule, ":", 2)
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			if key == "type" {
				fieldType = value
			} else {
				constraints[key] = value
			}
		} else {
			// Handle requirement levels and simple constraints
			switch rule {
			case "required":
				requirement = Required
			case "optional":
				requirement = Optional
			default:
				// Handle constraint rules without values
				constraints[rule] = "true"
			}
		}
	}

	return &FieldDefinition{
		Name:         fieldName,
		JSONPath:     jsonPath,
		Requirement:  requirement,
		Description:  description,
		ExpectedType: fieldType,
		Constraints:  constraints,
	}
}

// GetProductFieldDefinitionsFromStructs generates field definitions using struct tags
func GetProductFieldDefinitionsFromStructs() map[string][]FieldDefinition {
	definitions := make(map[string][]FieldDefinition)

	for productType, structType := range ProductTypes {
		definitions[productType] = GenerateFieldDefinitionsFromStruct(structType)
	}

	return definitions
}

// GetPriceFieldDefinitionsFromStruct generates price field definitions from struct
func GetPriceFieldDefinitionsFromStruct() []FieldDefinition {
	return GenerateFieldDefinitionsFromStruct(reflect.TypeOf(PriceData{}))
}
