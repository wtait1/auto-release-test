package main

import "fmt"

var (
	// Version is injected at build time via the '-X' linker flag
	Version string
)

func main() {
	fmt.Println("Hi! This is ART version " + Version)
}
