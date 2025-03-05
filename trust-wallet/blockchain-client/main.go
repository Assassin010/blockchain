/* main.go */

package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func testRPCConnectivity() {
	fmt.Println("Testing connectivity to Polygon RPC at:", polygonRPC)
	resp, err := http.Get(polygonRPC)
	if err != nil {
		log.Fatalf("Cannot reach Polygon RPC: %v", err)
	}
	defer resp.Body.Close()
	fmt.Println("Polygon RPC is reachable!")
}

func main() {
	fmt.Println("Starting Blockchain Client...")
	fmt.Println("Environment Variables:")
	for _, e := range os.Environ() {
		fmt.Println(e)
	}
	testRPCConnectivity()

	http.HandleFunc("/blockNumber", getBlockNumber)
	http.HandleFunc("/blockByNumber", getBlockByNumber)

	fmt.Println("Server running on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
