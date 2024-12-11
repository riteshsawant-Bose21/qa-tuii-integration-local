package timers

import (
	"fmt"
	"time"
)

// Task1 is an example task that could be executed at a scheduled time
func Task1() {
	fmt.Println("Task1 executed at", time.Now())
}

// Task2 is another example task
func Task2() {
	fmt.Println("Task2 executed at", time.Now())
}

// func main() {
// 	// Create a new cron scheduler
// 	c := cron.New()

// 	// Schedule Task1 to run every Sunday at noon
// 	_, err := c.AddFunc("0 12 * * 0", Task1)
// 	if err != nil {
// 		fmt.Println("Error scheduling Task1:", err)
// 		return
// 	}

// 	// Schedule Task2 to run every minute (for testing/demo purposes)
// 	_, err = c.AddFunc("* * * * *", Task2)
// 	if err != nil {
// 		fmt.Println("Error scheduling Task2:", err)
// 		return
// 	}

// 	// Start the scheduler
// 	c.Start()
// 	fmt.Println("Cron scheduler started. Waiting for tasks to execute...")

// 	// Keep the application running
// 	select {}
// }
