package main

import (
	"fmt"
	"os/exec"
	"strings"
	"testing"
)

const (
	instance1Name = "fusion1"
	instance2Name = "fusion2"
	instancePort  = "7947"
)

// runMultipassCommand executes a bash command on the default instance using multipass exec.
func runMultipassCommand(t *testing.T, command string) (string, error) {
	t.Helper()
	return runMultipassCommandOnInstance(t, instance1Name, command)
}

// runMultipassCommandOnInstance executes a bash command on a given instance using multipass exec.
func runMultipassCommandOnInstance(t *testing.T, instance, command string) (string, error) {
	t.Helper()
	args := []string{"exec", instance, "--", "bash", "-c", command}
	cmd := exec.Command("multipass", args...)
	output, err := cmd.CombinedOutput()
	return string(output), err
}

// TestMultipassGet runs the "get" command inside the default instance.
func TestMultipassGet(t *testing.T) {
	command := fmt.Sprintf(`echo '{"action":"get"}' | nc -u -w 1 -v localhost %s`, instancePort)
	out, err := runMultipassCommand(t, command)
	if err != nil {
		t.Fatalf("Multipass get command failed: %v, output: %s", err, out)
	}
}

// TestMultipassSet runs the "set" command inside the default instance.
func TestMultipassSet(t *testing.T) {
	command := fmt.Sprintf(`echo '{"action":"set","test":"hello"}' | nc -u -w 1 localhost %s`, instancePort)
	out, err := runMultipassCommand(t, command)
	if err != nil {
		t.Fatalf("Multipass set command failed: %v, output: %s", err, out)
	}
}

// TestMultipassSetAndGet sets a value and then verifies it with a get command on the default instance.
func TestMultipassSetAndGet(t *testing.T) {
	// Set the value on instance1.
	setCommand := fmt.Sprintf(`echo '{"action":"set","test":"hello"}' | nc -u -w 1 localhost %s`, instancePort)
	setOut, err := runMultipassCommand(t, setCommand)
	if err != nil {
		t.Fatalf("Multipass set command failed: %v, output: %s", err, setOut)
	}

	// Retrieve the value from instance1.
	getCommand := fmt.Sprintf(`echo '{"action":"get"}' | nc -u -w 1 -v localhost %s`, instancePort)
	getOut, err := runMultipassCommand(t, getCommand)
	if err != nil {
		t.Fatalf("Multipass get command failed: %v, output: %s", err, getOut)
	}

	// Verify that the returned output contains the expected test value.
	if !strings.Contains(getOut, "hello") {
		t.Fatalf("Expected get output to contain 'hello', got: %s", getOut)
	}
}

// TestMultipassPropagation sets a value on instance1 and verifies that it propagates to instance2.
func TestMultipassPropagation(t *testing.T) {
	// Set the value on instance1.
	setCommand := fmt.Sprintf(`echo '{"action":"set","test":"hello"}' | nc -u -w 1 localhost %s`, instancePort)
	setOut, err := runMultipassCommandOnInstance(t, instance1Name, setCommand)
	if err != nil {
		t.Fatalf("Multipass set command on %s failed: %v, output: %s", instance1Name, err, setOut)
	}

	// Retrieve the value from instance2.
	getCommand := fmt.Sprintf(`echo '{"action":"get"}' | nc -u -w 1 -v localhost %s`, instancePort)
	getOut, err := runMultipassCommandOnInstance(t, instance2Name, getCommand)
	if err != nil {
		t.Fatalf("Multipass get command on %s failed: %v, output: %s", instance2Name, err, getOut)
	}

	// Verify that the returned output from instance2 contains the expected test value.
	if !strings.Contains(getOut, "hello") {
		t.Fatalf("Expected get output from %s to contain 'hello', got: %s", instance2Name, getOut)
	}
}
