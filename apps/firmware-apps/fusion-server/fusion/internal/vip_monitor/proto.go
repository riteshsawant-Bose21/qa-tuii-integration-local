package vipmonitor

import (
	"net/http"

	"fusion/internal/api"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

var vipProtoJSONMarshalOptions = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
}

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	data, err := vipProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}

func writeProtoJSONWithStatus(w http.ResponseWriter, status int, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(status)
	data, err := vipProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
