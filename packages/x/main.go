package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

const (
	TARGET_FILE   = "/etc/x/target"
	DOTFILES_PATH = "/home/kovs/dotfiles"
)

func printUsage() {
	fmt.Fprintln(os.Stderr, `usage: x [command]
  x               this help
  x theme         switch to the other theme variant and rebuild
  x rb            nixos-rebuild switch current target
  x b             nixos-rebuild build current target
  x gc            nix store gc
  x upd [input]   nix flake update [input]
  x ch            parse, format and evaluate, as the README says`)
	os.Exit(2)
}

func flip(target string) string {
	if host, ok := strings.CutSuffix(target, "-black"); ok {
		return host + "-white"
	}
	return strings.TrimSuffix(target, "-white") + "-black"
}

func liveTarget() string {
	raw, err := os.ReadFile(TARGET_FILE)
	if err != nil {
		fmt.Fprintf(os.Stderr,
			`x: %s: %v no switch has run yet; start with:
				sudo nixos-rebuild switch --flake %s#laptop-black`,
			TARGET_FILE, err, DOTFILES_PATH)
		os.Exit(1)
	}

	target := strings.TrimSpace(string(raw))
	if target == "" {
		fmt.Fprintf(os.Stderr, "x: %s is empty\n", TARGET_FILE)
		os.Exit(1)
	}

	return target
}

func run(argv ...string) {
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr

	if err := cmd.Run(); err != nil {
		os.Exit(1)
	}
}

func rebuild(action, target string) {
	run(
		"systemd-run", "--user", "--unit=x-rebuild", "--collect", "--wait", "--pipe",
		"--property=MemoryHigh=4G", "--property=MemoryMax=6G",
		"sudo", "-n", "nixos-rebuild", action,
		"--max-jobs", "1", "--cores", "2", "--flake", DOTFILES_PATH+"#"+target,
	)
}

func main() {
	args := os.Args[1:]

	if len(args) == 0 {
		printUsage()
		return
	}

	target := liveTarget()

	switch args[0] {
	case "theme":
		from, to := target, flip(target)

		fmt.Println("theme:", from, "->", to)

		rebuild("switch", to)

	case "rb":
		rebuild("switch", target)

	case "b":
		rebuild("build", target)

	case "gc":
		run(
			"sudo",
			"-n",
			"nix",
			"store",
			"gc",
		)

	case "upd":
		run(
			append([]string{
				"nix",
				"flake",
				"update",
				"--flake",
				DOTFILES_PATH,
			}, args[1:]...)...,
		)

	case "ch":
		run(
			"bash",
			DOTFILES_PATH+"/packages/x/check.sh",
			target,
		)

	default:
		printUsage()
	}
}
