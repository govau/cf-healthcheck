package main

//go:generate go-bindata -o static.go data/

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	data, err := Asset("data/status.json")
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-cache")
		_, err := w.Write(data)
		if err != nil {
			panic(err)
		}
	})

	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), nil))
}
