package app

import (
	"net/http"

	"fusion/internal/api"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

var appProtoJSONMarshalOptions = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
}

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	data, err := appProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
