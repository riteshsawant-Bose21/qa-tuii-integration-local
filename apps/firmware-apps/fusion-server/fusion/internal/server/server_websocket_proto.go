package server

import (
	"fmt"
	"time"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var websocketProtoJSONMarshalOptions = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
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

func websocketResponse(id *string, msgType string, code int, status, message string, data any) *model.WebSocketResponse {
	response := &model.WebSocketResponse{
		Version:   1,
		Type:      msgType,
		Code:      int32(code),
		Status:    status,
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

func marshalWebSocketProto(msg proto.Message) ([]byte, error) {
	return websocketProtoJSONMarshalOptions.Marshal(msg)
}

func marshalWebSocketProtoOrPanic(msg proto.Message) []byte {
	data, err := marshalWebSocketProto(msg)
	if err != nil {
		panic(fmt.Sprintf("marshal websocket proto: %v", err))
	}
	return data
}
