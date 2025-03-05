package main

import (
	"net/http"
)

func getBlockNumber(w http.ResponseWriter, r *http.Request) {
	result, err := sendRPCRequest("eth_blockNumber", nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(result)
}

func getBlockByNumber(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("block")
	if query == "" {
		http.Error(w, "Missing block number", http.StatusBadRequest)
		return
	}
	params := []interface{}{query, true}
	result, err := sendRPCRequest("eth_getBlockByNumber", params)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(result)
}
