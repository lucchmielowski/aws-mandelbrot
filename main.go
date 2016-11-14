package main

import (
	"bytes"
	"errors"
	"fmt"
	"goji.io"
	"goji.io/pat"
	"image/gif"
	"image/jpeg"
	"image/png"
	"local/mandelbrot-aws/mandelbrot"
	"log"
	"net/http"
	"runtime"
	"strconv"
)

func renderMandlebrot(w http.ResponseWriter, r *http.Request) {
	runtime.GOMAXPROCS(runtime.NumCPU())

	var err error
	ext := r.URL.Query().Get("ext")

	height := r.URL.Query().Get("height")

	width := r.URL.Query().Get("width")

	if ext == "" || height == "" || width == "" {
		http.Error(w, http.StatusText(400), 400)
		fmt.Fprintf(w, "should have parameters 'ext', 'width', 'height'")
		return
	}

	intH, err := strconv.Atoi(height)

	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	intW, err := strconv.Atoi(width)

	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	buffer := new(bytes.Buffer)
	img := mandelbrot.Create(intW, intH)

	switch ext {
	case "png":
		err = png.Encode(buffer, img)
	case "jpg", "jpeg":
		err = jpeg.Encode(buffer, img, nil)
	case "gif":
		err = gif.Encode(buffer, img, nil)
	default:
		err = errors.New("unknonw format" + ext)
	}

	// unless you can't
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	w.Header().Set("Content-Type", "image/"+ext)
	w.Header().Set("Content-Length", strconv.Itoa(len(buffer.Bytes())))
	if _, err := w.Write(buffer.Bytes()); err != nil {
		log.Println("unable to write message")
	}
}

func main() {
	mux := goji.NewMux()
	mux.HandleFunc(pat.Get("/render/mandelbrot"), renderMandlebrot)

	http.ListenAndServe("localhost:3000", mux)
}
