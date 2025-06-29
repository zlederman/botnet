package main

import (
	"flag"
	"fmt"
	internal "github.com/zlederman/botnet/internal"
)

func main() {
	mode := flag.String("mode", "server", "start app in 'client' or 'server' mode")
	flag.Parse()

	switch *mode {
	case "server":
		internal.Send()
	case "client":
		internal.Receive()
	default:
		fmt.Println("Invalid Mode")
	}
}

