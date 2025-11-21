package network

import (
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server/handler"
	"net"
	"time"
)

type SAPServer struct {
	*Listener
	handler *handler.Handler
}

// NewSAPServer creates a server that handles Session Announcement Protocol data
func NewSAPServer(groups []string, port string, handler *handler.Handler) (*SAPServer, error) {

	conn, err := ResolveListenUDP(":" + port)
	if err != nil {
		return nil, err
	}

	if err := JoinMulticastGroups(conn, groups, port); err != nil {
		conn.Close()
		return nil, err
	}

	logger := logging.GetLogger()
	logger.Info("SAP listening on :%s (groups: %v)", port, groups)

	handler.StartSAPSessionPruner()

	var sap *SAPServer
	sap = &SAPServer{
		Listener: NewListener(
			conn,
			defaultBufferSize,
			time.Second,
			func(data []byte, _ *net.UDPAddr) {
				if err := sap.handler.HandleSAPMessage(data); err != nil {
					logger.Error("Error handling sap message: %v", err)
				}
			},
		),
		handler: handler,
	}

	return sap, nil
}

func (s *SAPServer) BroadcastMessage(msg *api.NotifyMessage) error {
	return nil
}
