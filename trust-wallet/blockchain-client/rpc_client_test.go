package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetBlockNumber(t *testing.T) {
	req, err := http.NewRequest("GET", "/blockNumber", nil)
	if err != nil {
		t.Fatal(err)
	}
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(getBlockNumber)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	body, err := ioutil.ReadAll(rr.Body)
	if err != nil {
		t.Fatal(err)
	}

	if len(body) == 0 {
		t.Errorf("Expected non-empty response, got empty body")
	}
}

func TestGetBlockByNumber(t *testing.T) {
	req, err := http.NewRequest("GET", "/blockByNumber?block=0x134e82a", nil)
	if err != nil {
		t.Fatal(err)
	}
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(getBlockByNumber)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	body, err := ioutil.ReadAll(rr.Body)
	if err != nil {
		t.Fatal(err)
	}

	if len(body) == 0 {
		t.Errorf("Expected non-empty response, got empty body")
	}
}
