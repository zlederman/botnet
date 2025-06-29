package internal

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	amqp "github.com/rabbitmq/amqp091-go"
)

func saveScriptToTempDir(rawScript string) (string, error) {
	tempDir, err := os.MkdirTemp("","*")
	if err != nil {
		return "", err
	}
	fmt.Println("Created Temp Directory ", tempDir)


	hasher := sha256.New()
	hasher.Write([]byte(rawScript))
	hashBytes := hasher.Sum(nil)

	hashString := hex.EncodeToString(hashBytes)[0:10]

	filepath := filepath.Join(tempDir, "script_" + hashString + ".py")
	err = os.WriteFile(filepath, []byte(rawScript), 0644)
	if err != nil {
		return "", err
	}
	fmt.Println("Successfully wrote to ", filepath)
	return filepath, nil
}

func executeScript(scriptPath string) {
	cmd := exec.Command("uv", "run", scriptPath)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	err := cmd.Run()
	if err != nil {
		fmt.Printf("Command failed with error %v\n Output:\n %s\n", err, out.String())
		return
	}
	result := out.String()
	fmt.Println("Command Output:\n", result)	

}

func Receive() {
	conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	q, err := ch.QueueDeclare(
		"hello", // name
		false,   // durable
		false,   // delete when unused
		false,   // exclusive
		false,   // no-wait
		nil,     // arguments
	)
	failOnError(err, "Failed to declare a queue")

	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		true,   // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	failOnError(err, "Failed to register a consumer")

	var forever chan struct{}

	go func() {
		for d := range msgs {
			log.Printf("Received a message: %s", d.Body)
			filePath, err := saveScriptToTempDir(string(d.Body))
			if err != nil {
				log.Printf("Error Trying to Save Script %v\n", err)
				return
			}
			executeScript(filePath)

		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}