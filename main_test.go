package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthCheckHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(HttpPingHandler)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v wanted %v", status, http.StatusOK)
	}

	expected := fmt.Sprintf(`{"alive": true, ip: %s}`, getMyIp())
	if rr.Body.String() != expected {
		t.Errorf("handler returned unexpected body: got %v want %v", rr.Body.String(), expected)
	}
}
