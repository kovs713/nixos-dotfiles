package main

import "testing"

func TestFlip(t *testing.T) {
	cases := map[string]string{
		"laptop-black": "laptop-white",
		"laptop-white": "laptop-black",
	}

	for target, want := range cases {
		if got := flip(target); got != want {
			t.Errorf("flip(%q) = %q, want %q", target, got, want)
		}
	}
}

func TestFlipIsInvolutive(t *testing.T) {
	for _, target := range []string{"laptop-black", "laptop-white"} {
		if back := flip(flip(target)); back != target {
			t.Errorf("flip(flip(%q)) = %q, want %q", target, back, target)
		}
	}
}
