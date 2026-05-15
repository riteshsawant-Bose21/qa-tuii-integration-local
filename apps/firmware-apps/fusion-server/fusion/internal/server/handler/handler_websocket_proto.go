package handler

import (
	"fmt"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"time"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func websocketRequestDataToProto(value *structpb.Value, msg proto.Message) error {
	if value == nil {
		return fmt.Errorf("missing data")
	}
	if _, ok := value.GetKind().(*structpb.Value_NullValue); ok {
		return fmt.Errorf("missing data")
	}
	data, err := protojson.Marshal(value)
	if err != nil {
		return err
	}
	return protojson.Unmarshal(data, msg)
}

func websocketRequestDataToAny(value *structpb.Value, target any) error {
	if value == nil {
		return fmt.Errorf("missing data")
	}
	if _, ok := value.GetKind().(*structpb.Value_NullValue); ok {
		return fmt.Errorf("missing data")
	}
	data, err := protojson.Marshal(value)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, target)
}

func websocketValueFromAny(data any) (*structpb.Value, error) {
	if data == nil {
		return structpb.NewNullValue(), nil
	}

	payloadBytes, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	var generic any
	if err := json.Unmarshal(payloadBytes, &generic); err != nil {
		return nil, err
	}

	return structpb.NewValue(generic)
}

func websocketStructFromMap(data map[string]any) (*structpb.Struct, error) {
	if data == nil {
		return nil, nil
	}
	return structpb.NewStruct(data)
}

func createSuccessResponse(id *string, msgType string, code int, message string, data any) *model.WebSocketResponse {
	response := &model.WebSocketResponse{
		Version:   int32(api.WSCurrentVersion),
		Type:      msgType,
		Code:      int32(code),
		Status:    api.WSStatusSuccess,
		Message:   message,
		Timestamp: timestamppb.New(time.Now()),
	}
	if id != nil {
		response.Id = id
	}
	if value, err := websocketValueFromAny(data); err == nil {
		response.Data = value
	}
	return response
}

func createErrorResponse(id *string, code int, message string) *model.WebSocketResponse {
	response := &model.WebSocketResponse{
		Version:   int32(api.WSCurrentVersion),
		Type:      api.WSMsgTypeError,
		Code:      int32(code),
		Status:    api.WSStatusError,
		Message:   message,
		Timestamp: timestamppb.New(time.Now()),
	}
	if id != nil {
		response.Id = id
	}
	response.Data = structpb.NewNullValue()
	return response
}
