package vip

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestWriteToKeepalivedConfigNormalizesInlineMalformedBlock(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "keepalived.conf")

	input := `# Fusion customized keepalived configuration
global_defs {
  enable_script_security
}
vrrp_instance VI_1 {
  state BACKUP
  interface enp0s1
  virtual_router_id 51
  priority 99
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass fusion 
  }
  virtual_ipaddress { 192.168.2.100 }
    VIP_NOT_SET/24
  }
}
`

	if err := os.WriteFile(path, []byte(input), 0o644); err != nil {
		t.Fatalf("write config: %v", err)
	}

	if err := WriteToKeepalivedConfig(path, "192.168.2.101"); err != nil {
		t.Fatalf("WriteToKeepalivedConfig returned error: %v", err)
	}

	gotBytes, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read config: %v", err)
	}
	got := string(gotBytes)

	if strings.Contains(got, "VIP_NOT_SET/24") {
		t.Fatalf("expected malformed placeholder line to be removed, got:\n%s", got)
	}
	if strings.Contains(got, "virtual_ipaddress { 192.168.2.100 }") {
		t.Fatalf("expected inline virtual_ipaddress block to be normalized, got:\n%s", got)
	}

	expectedBlock := "  virtual_ipaddress {\n    192.168.2.101\n  }"
	if !strings.Contains(got, expectedBlock) {
		t.Fatalf("expected normalized VIP block %q in config, got:\n%s", expectedBlock, got)
	}
}

func TestWriteToKeepalivedConfigRejectsInvalidVIP(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "keepalived.conf")

	input := `vrrp_instance VI_1 {
  virtual_ipaddress {
    192.168.2.100
  }
}
`

	if err := os.WriteFile(path, []byte(input), 0o644); err != nil {
		t.Fatalf("write config: %v", err)
	}

	if err := WriteToKeepalivedConfig(path, "not-an-ip"); err == nil {
		t.Fatal("expected invalid VIP write to fail")
	}
}
