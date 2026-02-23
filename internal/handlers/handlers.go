package handlers

import (
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"
)

var (
	// Application state
	isReady   int32 = 1 // 1 = ready, 0 = not ready
	startTime       = time.Now()
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Uptime    string    `json:"uptime"`
	Version   string    `json:"version"`
}

// ReadyResponse represents the readiness check response
type ReadyResponse struct {
	Ready     bool      `json:"ready"`
	Timestamp time.Time `json:"timestamp"`
}

// HealthHandler handles the /health endpoint
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(startTime)

	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Uptime:    uptime.String(),
		Version:   "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// ReadyHandler handles the /ready endpoint
func ReadyHandler(w http.ResponseWriter, r *http.Request) {
	ready := atomic.LoadInt32(&isReady) == 1

	response := ReadyResponse{
		Ready:     ready,
		Timestamp: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")

	if ready {
		w.WriteHeader(http.StatusOK)
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	json.NewEncoder(w).Encode(response)
}

// SetReady sets the application ready state
func SetReady(ready bool) {
	if ready {
		atomic.StoreInt32(&isReady, 1)
	} else {
		atomic.StoreInt32(&isReady, 0)
	}
}
