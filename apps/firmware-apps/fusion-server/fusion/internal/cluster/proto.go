package cluster

import (
	"net/http"

	"fusion/internal/api"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

var clusterProtoJSONMarshalOptions = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
}

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	data, err := clusterProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}

func writeProtoJSONWithStatus(w http.ResponseWriter, status int, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(status)
	data, err := clusterProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
