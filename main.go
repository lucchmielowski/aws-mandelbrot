package main

import (
	"bytes"
	"errors"
	"fmt"
	"github.com/lucchmielowski/aws-mandelbrot/mandelbrot"
	"image/gif"
	"image/jpeg"
	"image/png"
	"log"
	"net/http"
	"runtime"
	"strconv"
)

func errorHandler(w http.ResponseWriter, r *http.Request, status int) {
	w.WriteHeader(status)
	if status == http.StatusNotFound {
		fmt.Fprint(w, "custom 404")
	}
}

func renderMandlebrot(w http.ResponseWriter, r *http.Request) {
	runtime.GOMAXPROCS(runtime.NumCPU())

	ext := r.URL.Query().Get("ext")

	height, err := strconv.Atoi(r.URL.Query().Get("height"))

	width, err := strconv.Atoi(r.URL.Query().Get("width"))

	if ext == "" || err != nil {
		errorHandler(w, r, http.StatusBadRequest)
	}

	buffer := new(bytes.Buffer)
	img := mandelbrot.Create(width, height)

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
		errorHandler(w, r, http.StatusInternalServerError)
	}

	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Content-Length", strconv.Itoa(len(buffer.Bytes())))
	if _, err := w.Write(buffer.Bytes()); err != nil {
		log.Println("unable to write image.")
	}
}

func httpPing(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Server", "A Go Web Server")
	w.WriteHeader(200)
}

func main() {
	mux := http.NewServeMux()
	rM := http.HandlerFunc(renderMandlebrot)
	hW := http.HandlerFunc(httpPing)
	mux.Handle("/", hW)
	mux.Handle("/mandelbrot", rM)
	http.ListenAndServe(":3000", mux)
}
