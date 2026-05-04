package routes

import (
	"net/http"

	"fusion/internal/api"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

var routesProtoJSONMarshalOptions = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
}

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	data, err := routesProtoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}
	_, err = w.Write(data)
	return err
}
