package server

import (
	"net/http"

	"fusion/internal/api"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

var (
	serverProtoJSONMarshalOptions = protojson.MarshalOptions{
		UseProtoNames:   true,
		EmitUnpopulated: false,
	}
	serverProtoJSONUnmarshalOptions = protojson.UnmarshalOptions{
		DiscardUnknown: false,
	}
)

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	data, err := serverProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}

func writeProtoJSONWithStatus(w http.ResponseWriter, status int, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(status)
	data, err := serverProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
