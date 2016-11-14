package mandelbrot

import (
	"flag"
	"image"
	"image/color"
	"sync"
)

var (
	mode    = flag.String("mode", "seq", "mode: seq, px, row, workers")
	workers = flag.Int("workers", 1, "numbers of workers to use")
)

type img struct {
	h, w int
	m    [][]color.RGBA
}

func (m *img) At(x, y int) color.Color { return m.m[x][y] }
func (m *img) ColorModel() color.Model { return color.RGBAModel }
func (m *img) Bounds() image.Rectangle { return image.Rect(0, 0, m.h, m.w) }

func Create(h, w int) image.Image {
	c := make([][]color.RGBA, h)
	for i := range c {
		c[i] = make([]color.RGBA, w)
	}

	m := &img{h, w, c}

	switch *mode {
	case "seq":
		seqFillImg(m)
	case "px":
		oneToOneFillImg(m)
	case "row":
		onePerRowFillImg(m)
	case "workers":
		nWorkersFillImg(m)
	default:
		panic("unknown mode")
	}

	return m
}

//Sequential
func seqFillImg(m *img) {
	for i, row := range m.m {
		for j := range row {
			fillPixel(m, i, j)
		}
	}
}

//one goroutine per pixel
func oneToOneFillImg(m *img) {
	var wg sync.WaitGroup
	wg.Add(m.h * m.w)
	for i, row := range m.m {
		for j := range row {
			go func(i, j int) {
				fillPixel(m, i, j)
				wg.Done()
			}(i, j)
		}
	}
	wg.Wait()
}

//one per row of pixel
func onePerRowFillImg(m *img) {
	var wg sync.WaitGroup
	wg.Add(m.h)
	for i := range m.m {
		go func(i int) {
			for j := range m.m[i] {
				fillPixel(m, i, j)
			}
			wg.Done()
		}(i)
	}
	wg.Wait()
}

//4 workers per CPU
func nWorkersFillImg(m *img) {
	c := make(chan struct{ i, j int })

	for i := 0; i < *workers; i++ {
		go func() {
			for t := range c {
				fillPixel(m, t.i, t.j)
			}
		}()
	}

	for i, row := range m.m {
		for j := range row {
			c <- struct{ i, j int }{i, j}
		}
	}
	close(c)
}

func fillPixel(m *img, i, j int) {
	xi := 3.5*float64(i)/float64(m.w) - 2.5
	yi := 2*float64(j)/float64(m.h) - 1

	const maxI = 10000
	x, y := 0., 0.
	for i := 0; (x*x+y*y < 4) && i < maxI; i++ {
		x, y = x*x-y*y+xi, 2*x*y+yi
	}

	paint(&m.m[i][j], x, y)
}

func paint(c *color.RGBA, x, y float64) {
	n := byte(x * y)
	c.R, c.G, c.B, c.A = n, n, n, 255
}
