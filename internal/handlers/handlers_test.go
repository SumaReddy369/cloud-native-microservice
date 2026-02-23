package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	HealthHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, rec.Code)
	}

	contentType := rec.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", contentType)
	}

	var response HealthResponse
	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if response.Status != "healthy" {
		t.Errorf("expected status 'healthy', got %s", response.Status)
	}
	if response.Version != "1.0.0" {
		t.Errorf("expected version '1.0.0', got %s", response.Version)
	}
	if response.Uptime == "" {
		t.Error("expected non-empty uptime")
	}
}

func TestReadyHandler_WhenReady(t *testing.T) {
	SetReady(true)

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	rec := httptest.NewRecorder()

	ReadyHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, rec.Code)
	}

	var response ReadyResponse
	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if !response.Ready {
		t.Error("expected ready to be true")
	}
}

func TestReadyHandler_WhenNotReady(t *testing.T) {
	SetReady(false)
	defer SetReady(true) // Restore for other tests

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	rec := httptest.NewRecorder()

	ReadyHandler(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("expected status %d, got %d", http.StatusServiceUnavailable, rec.Code)
	}

	var response ReadyResponse
	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if response.Ready {
		t.Error("expected ready to be false")
	}
}

func TestSetReady(t *testing.T) {
	// Test setting to false
	SetReady(false)
	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	rec := httptest.NewRecorder()
	ReadyHandler(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("after SetReady(false), expected 503, got %d", rec.Code)
	}

	// Test setting to true
	SetReady(true)
	req = httptest.NewRequest(http.MethodGet, "/ready", nil)
	rec = httptest.NewRecorder()
	ReadyHandler(rec, req)
	if rec.Code != http.StatusOK {
		t.Errorf("after SetReady(true), expected 200, got %d", rec.Code)
	}
}
