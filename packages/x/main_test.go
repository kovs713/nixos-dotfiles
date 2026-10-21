package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Every output name, because `x theme` is only correct for a target that is
// also an output: it feeds the flipped name straight back to `--flake .#<name>`.
var targets = []string{
	"laptop-black",
	"laptop-white",
	"desktop-black",
	"desktop-white",
}

func TestFlip(t *testing.T) {
	cases := map[string]string{
		"laptop-black":  "laptop-white",
		"laptop-white":  "laptop-black",
		"desktop-black": "desktop-white",
		"desktop-white": "desktop-black",
	}

	for target, want := range cases {
		if got := flip(target); got != want {
			t.Errorf("flip(%q) = %q, want %q", target, got, want)
		}
	}
}

func TestFlipIsInvolutive(t *testing.T) {
	for _, target := range targets {
		if back := flip(flip(target)); back != target {
			t.Errorf("flip(flip(%q)) = %q, want %q", target, back, target)
		}
	}
}

func TestRebuildLimits(t *testing.T) {
	dir := t.TempDir()
	output := filepath.Join(dir, "args")
	stub := "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$X_TEST_ARGS\"\n"
	if err := os.WriteFile(filepath.Join(dir, "systemd-run"), []byte(stub), 0755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir)
	t.Setenv("X_TEST_ARGS", output)
	for _, action := range []string{"build", "switch"} {
		for _, target := range targets {
			rebuild(action, target)
			got, err := os.ReadFile(output)
			if err != nil {
				t.Fatal(err)
			}
			want := []string{
				"--user", "--unit=x-rebuild", "--collect", "--wait", "--pipe",
				"--property=MemoryHigh=4G", "--property=MemoryMax=6G",
				"sudo", "-n", "nixos-rebuild", action,
				"--max-jobs", "1", "--cores", "2", "--flake", DOTFILES_PATH + "#" + target,
			}
			if string(got) != strings.Join(want, "\n")+"\n" {
				t.Fatalf("%s %s: unexpected command: %s", action, target, got)
			}
		}
	}
}
