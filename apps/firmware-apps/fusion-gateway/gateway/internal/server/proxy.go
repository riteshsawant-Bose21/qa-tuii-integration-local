package server

import (
	"net/http"
	"net/http/httputil"
	"net/url"

	"fusion-services-core/logging"
)

// NewReverseProxy creates a reverse proxy that forwards all requests to target.
func NewReverseProxy(target string) (*httputil.ReverseProxy, error) {
	upstream, err := url.Parse(target)
	if err != nil {
		return nil, err
	}

	proxy := httputil.NewSingleHostReverseProxy(upstream)
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		// Ensure upstream host is used for outbound requests.
		req.Host = upstream.Host
	}
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		logging.GetLogger().Error("proxy error for %s %s: %v", r.Method, r.URL.Path, err)
		http.Error(w, "bad gateway", http.StatusBadGateway)
	}

	return proxy, nil
}
