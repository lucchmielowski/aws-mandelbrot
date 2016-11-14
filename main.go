package main

import (
	"bytes"
	"errors"
	"github.com/kataras/iris"
	"github.com/lucchmielowski/aws-mandelbrot/mandelbrot"
	"image/gif"
	"image/jpeg"
	"image/png"
	"runtime"
)

func renderMandlebrot(c *iris.Context) {
	runtime.GOMAXPROCS(runtime.NumCPU())

	ext := c.URLParam("ext")

	height, err := c.URLParamInt("height")

	width, err := c.URLParamInt("width")

	if ext == "" || err != nil {
		c.EmitError(iris.StatusBadRequest)
		return
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
		c.EmitError(iris.StatusInternalServerError)
	}

	c.SetContentType("image/" + ext)
	c.SetBody(buffer.Bytes())
}

func main() {
	iris.Get("/render/mandelbrot", renderMandlebrot)
	iris.Listen(":3000")
}
