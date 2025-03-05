package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

const polygonRPC = "https://polygon-rpc.com/"

type RPCRequest struct {
	JSONRPC string        `json:"jsonrpc"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params,omitempty"`
	ID      int           `json:"id"`
}

type RPCResponse struct {
	JSONRPC string          `json:"jsonrpc"`
	Result  json.RawMessage `json:"result"`
	ID      int             `json:"id"`
}

func sendRPCRequest(method string, params []interface{}) (json.RawMessage, error) {
	request := RPCRequest{
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
		ID:      1,
	}
	data, _ := json.Marshal(request)
	fmt.Printf("Sending request to Polygon RPC: %s with params: %v\n", method, params)
	resp, err := http.Post(polygonRPC, "application/json", bytes.NewBuffer(data))
	if err != nil {
		log.Printf("Error sending RPC request: %v", err)
		return nil, err
	}
	defer resp.Body.Close()
	var rpcResp RPCResponse
	if err := json.NewDecoder(resp.Body).Decode(&rpcResp); err != nil {
		log.Printf("Error decoding RPC response: %v", err)
		return nil, err
	}
	fmt.Printf("Received response from Polygon RPC: %s\n", rpcResp.Result)
	return rpcResp.Result, nil
}
