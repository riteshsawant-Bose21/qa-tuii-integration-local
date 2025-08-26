package fusion

// move this to contracts package later

var (
	ProductCategorySpeaker                string = "speaker"
	ProductCategoryAmplifier              string = "amplifier"
	ProductCategoryDigitalSignalProcessor string = "digitalSignalProcessor"
)

type Product struct {
	Speakers                []Speaker                `json:"speaker"`
	Amplifiers              []Amplifier              `json:"amplifier"`
	DigitalSignalProcessors []DigitalSignalProcessor `json:"digital_signal_processors"`
}

// Product represents a product in the Fusion system.
type Speaker struct {
	ID       int          `json:"id"`
	Category string       `json:"category"`
	MetaInfo Speaker_meta `json:"meta_info"`
}

type Amplifier struct {
	ID       int             `json:"id"`
	Category string          `json:"category"`
	MetaInfo Amplifiers_meta `json:"meta_info"`
}

type DigitalSignalProcessor struct {
	ID       int      `json:"id"`
	Category string   `json:"category"`
	MetaInfo DSP_meta `json:"meta_info"`
}

type Speaker_meta struct {
	Model         string `json:"model"`
	ID            int    `json:"id"`
	Skus          []int  `json:"skus"`
	Name          string `json:"name"`
	PowerHandling struct {
		Unit               string `json:"unit"`
		LongTermContinuous string `json:"long_term_continuous"`
		Peak               string `json:"peak"`
	} `json:"power_handling"`
	Sensitivity struct {
		Unit string `json:"unit"`
		At   []struct {
			Key   string `json:"key"`
			Value string `json:"value"`
		} `json:"at"`
	} `json:"sensitivity"`
	MaxSpl struct {
		Unit string `json:"unit"`
		At   []struct {
			Key   string `json:"key"`
			Value string `json:"value"`
		} `json:"at"`
	} `json:"max_spl"`
	FreqRange struct {
		Unit string `json:"unit"`
		Low  string `json:"low"`
		High string `json:"high"`
	} `json:"freq_range"`
	FrequencyResponse struct {
		At []struct {
			Key   string `json:"key"`
			Value string `json:"value"`
		} `json:"at"`
	} `json:"frequency_response"`
	FrequencyResponseCurve []struct {
		FrequencyHz int `json:"frequency_hz"`
		LevelDb     int `json:"level_db"`
	} `json:"frequency_response_curve"`
	NominalImpedance struct {
		Unit  string `json:"unit"`
		Value string `json:"value"`
	} `json:"nominal_impedance"`
	Coverage []struct {
		FrequencyRangeHz string `json:"frequency_range_hz"`
		Type             string `json:"type"`
		HorizontalDeg    int    `json:"horizontal_deg,omitempty"`
		VerticalDeg      int    `json:"vertical_deg,omitempty"`
		AngleDeg         int    `json:"angle_deg,omitempty"`
	} `json:"coverage"`
	AcousticTechnology string `json:"acoustic_technology"`
	Installation       struct {
		Technology  string `json:"technology"`
		Accessories string `json:"accessories"`
	} `json:"installation"`
	Certifications   string   `json:"certifications"`
	ProductCodes     []string `json:"product_codes"`
	ShortDescription string   `json:"short_description"`
	Description      string   `json:"description"`
	Environment      string   `json:"environment"`
	Dimensions       []struct {
		Unit   string  `json:"unit"`
		Height float32 `json:"height"`
		Width  float32 `json:"width"`
		Depth  float32 `json:"depth"`
	} `json:"dimensions"`
	MountType string `json:"mount_type"`
	Impedance struct {
		Unit string `json:"unit"`
		Low  string `json:"low"`
		High string `json:"high"`
	} `json:"impedance"`
	ImpedanceCurve []struct {
		FrequencyHz   int     `json:"frequency_hz"`
		ImpedanceOhms float64 `json:"impedance_ohms"`
	} `json:"impedance_curve"`
	AvailableTaps struct {
		Seven0V []float32 `json:"70v"`
		One00V  []float32 `json:"100v"`
	} `json:"available_taps"`
	NoOfPassbands           string   `json:"no_of_passbands"`
	Images                  []string `json:"images"`
	IsSubwoofer             bool     `json:"is_subwoofer"`
	IsWeatherRated          bool     `json:"is_weather_rated"`
	AvailableAccessories    []string `json:"available_accessories"`
	PolarData               string   `json:"polar_data"`
	BoseProfessionalVoicing string   `json:"bose_professional_voicing"`
	DriverComponents        struct {
		FullRange struct {
			Quantity int    `json:"quantity"`
			Size     string `json:"size"`
		} `json:"full_range"`
	} `json:"driver_components"`
	NetWeight []struct {
		Unit  string `json:"unit"`
		Value string `json:"value"`
	} `json:"net_weight"`
}

type Amplifiers_meta struct {
	ID          int    `json:"id"`
	Model       string `json:"model"`
	Skus        []int  `json:"skus"`
	Name        string `json:"name"`
	PowerOutput struct {
		Symmetrical struct {
			RatedPerChannel struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"rated_per_channel"`
			PeakPerChannel struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"peak_per_channel"`
			RatedPerChannelHighVoltage struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"rated_per_channel_high_voltage"`
			PeakPerChannelHighVoltage struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"peak_per_channel_high_voltage"`
		} `json:"symmetrical"`
		Asymmetrical struct {
			RatedPerChannel struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"rated_per_channel"`
			PeakPerChannel struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"peak_per_channel"`
			RatedPerChannelHighVoltage struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"rated_per_channel_high_voltage"`
			PeakPerChannelHighVoltage struct {
				Unit string `json:"unit"`
				At   []struct {
					Key   string `json:"key"`
					Value int    `json:"value"`
				} `json:"at"`
			} `json:"peak_per_channel_high_voltage"`
		} `json:"asymmetrical"`
	} `json:"power_output"`
	NumberOfInputsAndOutputs struct {
		Analog struct {
			Inputs  int `json:"inputs"`
			Outputs int `json:"outputs"`
		} `json:"analog"`
		FusionConnect struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"fusion_connect"`
		Aes67 struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"aes67"`
		Dante struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"dante"`
	} `json:"number_of_inputs_and_outputs"`
	FrontPanelImage string `json:"front_panel_image"`
	RearPanelImage  string `json:"rear_panel_image"`
	ThermalOutput   struct {
		Unit  string `json:"unit"`
		Value int    `json:"value"`
	} `json:"thermal_output"`
	CurrentDraw struct {
		At []struct {
			Key   string  `json:"key"`
			Value float64 `json:"value"`
			Unit  string  `json:"unit"`
		} `json:"at"`
	} `json:"current_draw"`
	RackHeight struct {
		Unit  string `json:"unit"`
		Value int    `json:"value"`
	} `json:"rack_height"`
	SafeOperatingTemperature struct {
		Unit string `json:"unit"`
		Min  int    `json:"min"`
		Max  int    `json:"max"`
	} `json:"safe_operating_temperature"`
	Firmware struct {
		CurrentPublishedVersion string `json:"current_published_version"`
		CurrentRunningVersion   string `json:"current_running_version"`
	} `json:"firmware"`
	Images []string `json:"images"`
	Colors []string `json:"colors"`
	Power  struct {
		Unit string `json:"unit"`
		At   []struct {
			Key   string `json:"key"`
			Value int    `json:"value"`
		} `json:"at"`
	} `json:"power"`
	Amplink []struct {
		Channels  int    `json:"channels"`
		Connector string `json:"connector"`
	} `json:"amplink"`
	Dante []struct {
		Channels  int    `json:"channels"`
		Connector string `json:"connector"`
	} `json:"dante"`
	Dimensions []struct {
		Unit   string  `json:"unit"`
		Height float32 `json:"height"`
		Width  float32 `json:"width"`
		Depth  float32 `json:"depth"`
	} `json:"dimensions"`
	NetWeight []struct {
		Unit  string `json:"unit"`
		Value string `json:"value"`
	} `json:"net_weight"`
	Certifications string   `json:"certifications"`
	ProductCodes   []string `json:"product_codes"`
}

type DSP_meta struct {
	ID                       int    `json:"id"`
	Model                    string `json:"model"`
	Name                     string `json:"name"`
	Skus                     []int  `json:"skus"`
	NumberOfInputsAndOutputs struct {
		FusionConnect struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"fusion_connect"`
		Aes67 struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"aes67"`
		Dante struct {
			MaxInputs  int `json:"max_inputs"`
			MaxOutputs int `json:"max_outputs"`
		} `json:"dante"`
	} `json:"number_of_inputs_and_outputs"`
	MaxNumberOfDigitalControl int `json:"max_number_of_digital_control"`
	MaxNumberOfAnalogControl  int `json:"max_number_of_analog_control"`
	SafeOperatingTemperature  struct {
		Unit string `json:"unit"`
		Min  int    `json:"min"`
		Max  int    `json:"max"`
	} `json:"safe_operating_temperature"`
	Firmware struct {
		CurrentPublishedVersion string `json:"current_published_version"`
		CurrentRunningVersion   string `json:"current_running_version"`
	} `json:"firmware"`
	Images         []string `json:"images"`
	GpioLogicPorts struct {
		Inputs  int `json:"inputs"`
		Outputs int `json:"outputs"`
	} `json:"gpio_logic_ports"`
	DspArchitecture          string `json:"dsp_architecture"`
	AcousticEchoCancellation struct {
		Channels int `json:"channels"`
	} `json:"acoustic_echo_cancellation"`
	ConfigurationSoftware                   string   `json:"configuration_software"`
	SupportedBoseProfessionalDanteEndpoints []string `json:"supported_bose_professional_dante_endpoints"`
	Dimensions                              struct {
		RackSpace string `json:"rack_space"`
		Size      []struct {
			Unit   string  `json:"unit"`
			Height float32 `json:"height"`
			Width  float32 `json:"width"`
			Depth  float32 `json:"depth"`
		} `json:"size"`
	} `json:"dimensions"`
	NetWeight []struct {
		Unit  string `json:"unit"`
		Value string `json:"value"`
	} `json:"net_weight"`
	ProductCodes []string `json:"product_codes"`
}
