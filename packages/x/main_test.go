package main

import "testing"

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
