package main

import (
	"flag"
	"fmt"

	internal "github.com/zlederman/botnet/internal"
)

func main() {
	mode := flag.String("mode", "server", "start app in 'client' or 'server' mode")
	filePath := flag.String("file", "", "path to the file to send (server mode only)")

	flag.Parse()

	switch *mode {
	case "server":
		if *filePath == ""{
			fmt.Println("Please add a file a path to send to the queue")
			return
		}
		internal.Send(*filePath)
	case "client":
		internal.Receive()
	default:
		fmt.Println("Invalid Mode")
	}
}

