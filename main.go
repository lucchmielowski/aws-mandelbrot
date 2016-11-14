package main

import (
	"errors"
	"flag"
	"image/gif"
	"image/jpeg"
	"image/png"
	"log"
	"os"
	"path/filepath"
	"runtime"

	"local/mandelbrot-aws/mandelbrot"
)

var (
	output = flag.String("out", "mandelbrot.png", "name of the output image file")
	height = flag.Int("h", 1024, "height of the output in pixels")
	width  = flag.Int("w", 1024, "width of the output in pixels")
)

func main() {
	flag.Parse()
	runtime.GOMAXPROCS(runtime.NumCPU())

	f, err := os.Create(*output)
	if err != nil {
		log.Fatal(err)
	}

	img := mandelbrot.Create(*height, *width)

	fmt := filepath.Ext(*output)
	switch fmt {
	case ".png":
		err = png.Encode(f, img)
	case ".jpg", ".jpeg":
		err = jpeg.Encode(f, img, nil)
	case ".gif":
		err = gif.Encode(f, img, nil)
	default:
		err = errors.New("unknonw format" + fmt)
	}

	// unless you can't
	if err != nil {
		log.Fatal(err)
	}
}
