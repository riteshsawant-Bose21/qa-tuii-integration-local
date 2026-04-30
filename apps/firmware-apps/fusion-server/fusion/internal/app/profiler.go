package app

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"runtime/pprof"
	"sync"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

type cpuProfiler struct {
	mu           sync.Mutex
	active       bool
	file         *os.File
	path         string
	lastHeapPath string
}

type profileStatusResponse struct {
	Active       bool   `json:"active"`
	Path         string `json:"path,omitempty"`
	LastHeapPath string `json:"last_heap_path,omitempty"`
}

func newCPUProfiler() *cpuProfiler {
	return &cpuProfiler{}
}

func (app *App) StartCPUProfile() (string, error) {
	return app.profiler.Start()
}

func (p *cpuProfiler) Start() (string, error) {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.active {
		return p.path, nil
	}

	timestamp := time.Now().Format("20060102_150405")
	path := filepath.Join("/tmp", fmt.Sprintf("fusion_server_cpu_%s.prof", timestamp))

	f, err := os.Create(path)
	if err != nil {
		return "", fmt.Errorf("create profile file: %w", err)
	}

	if err := pprof.StartCPUProfile(f); err != nil {
		f.Close()
		return "", fmt.Errorf("start cpu profile: %w", err)
	}

	p.file = f
	p.path = path
	p.active = true
	logging.GetLogger().Warn("[PROFILE] CPU profiling started: %s", path)
	return path, nil
}

func (p *cpuProfiler) Stop() (string, error) {
	p.mu.Lock()
	defer p.mu.Unlock()

	if !p.active {
		return "", nil
	}

	pprof.StopCPUProfile()

	path := p.path
	var err error
	if p.file != nil {
		err = p.file.Close()
	}

	p.file = nil
	p.path = ""
	p.active = false

	if err != nil {
		return path, fmt.Errorf("close profile file: %w", err)
	}

	logging.GetLogger().Warn("[PROFILE] CPU profiling stopped: %s", path)
	return path, nil
}

func (p *cpuProfiler) Status() profileStatusResponse {
	p.mu.Lock()
	defer p.mu.Unlock()
	return profileStatusResponse{
		Active:       p.active,
		Path:         p.path,
		LastHeapPath: p.lastHeapPath,
	}
}

func (p *cpuProfiler) CaptureHeap() (string, error) {
	p.mu.Lock()
	defer p.mu.Unlock()

	timestamp := time.Now().Format("20060102_150405")
	path := filepath.Join("/tmp", fmt.Sprintf("fusion_server_heap_%s.prof", timestamp))

	f, err := os.Create(path)
	if err != nil {
		return "", fmt.Errorf("create heap profile file: %w", err)
	}

	// Force a fresh GC cycle so the heap snapshot is current.
	runtime.GC()
	if err := pprof.Lookup("heap").WriteTo(f, 0); err != nil {
		_ = f.Close()
		return "", fmt.Errorf("write heap profile: %w", err)
	}
	if err := f.Close(); err != nil {
		return path, fmt.Errorf("close heap profile file: %w", err)
	}

	p.lastHeapPath = path
	logging.GetLogger().Warn("[PROFILE] Heap profile captured: %s", path)
	return path, nil
}

func (app *App) HandleProfileStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(app.profiler.Status())
}

func (app *App) HandleProfileStart(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	path, err := app.profiler.Start()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profileStatusResponse{Active: true, Path: path})
}

func (app *App) HandleProfileStop(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	path, err := app.profiler.Stop()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profileStatusResponse{Active: false, Path: path, LastHeapPath: app.profiler.Status().LastHeapPath})
}

func (app *App) HandleHeapProfileCapture(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	path, err := app.profiler.CaptureHeap()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	status := app.profiler.Status()
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profileStatusResponse{
		Active:       status.Active,
		Path:         status.Path,
		LastHeapPath: path,
	})
}
