package main

import (
	stdjson "encoding/json"
	"os"
	"path/filepath"
	"testing"

	fusionpb "fusion/internal/gen/proto/fusion"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestProtoUnmarshalDroConditionedOutputEnvelope(t *testing.T) {
	tests := []struct {
		name       string
		file       string
		assertions func(t *testing.T, envelope *fusionpb.DroConditionedOutputEnvelope)
	}{
		{
			name: "board1_1",
			file: "board1_1.json",
			assertions: func(t *testing.T, envelope *fusionpb.DroConditionedOutputEnvelope) {
				require.NotNil(t, envelope.GetResult())
				require.NotEmpty(t, envelope.GetResult().GetDevices())
				assert.Equal(t, "fusion_c1", envelope.GetResult().GetDevices()[0].GetDeviceType())
				assert.NotNil(t, envelope.GetResult().GetDevices()[0].GetDspStaticConfig())
				assert.NotEmpty(t, envelope.GetResult().GetDevices()[0].GetDspStaticConfig().GetAudioTasks())
			},
		},
		{
			name: "demo3_3board_aes67",
			file: "demo3_3board_aes67.json",
			assertions: func(t *testing.T, envelope *fusionpb.DroConditionedOutputEnvelope) {
				require.NotNil(t, envelope.GetResult())
				require.NotEmpty(t, envelope.GetResult().GetAes67Streams())
				require.NotEmpty(t, envelope.GetResult().GetDevices())
				assert.NotEmpty(t, envelope.GetResult().GetDevices()[0].GetCores())
				assert.NotEmpty(t, envelope.GetResult().GetDevices()[0].GetDspStaticConfig().GetTaskConnections())
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			data, err := os.ReadFile(protoSampleOutputPath(tt.file))
			require.NoError(t, err)

			var envelope fusionpb.DroConditionedOutputEnvelope
			err = stdjson.Unmarshal(data, &envelope)
			require.NoError(t, err)

			assert.NotEmpty(t, envelope.GetRequestId())
			assert.NotNil(t, envelope.GetResult())
			tt.assertions(t, &envelope)
		})
	}
}

func protoSampleOutputPath(name string) string {
	return filepath.Join("..", "..", "..", "..", "..", "..", "fusion-dsp-configurator-prototype", "outputs", name)
}
