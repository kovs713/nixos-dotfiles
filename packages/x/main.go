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
	SYSTEM        = "x86_64-linux"
)

func printUsage() {
	fmt.Fprintln(os.Stderr, `usage: x [command]
  x               this help
  x theme         switch to the other theme variant and rebuild
  x rb            nixos-rebuild switch current target
  x b             nixos-rebuild build current target
  x gc            nix store gc
  x upd [input]   nix flake update [input]
  x ch            parse, format and evaluate, as the README says
  x sh [stack...] dev shell for one or more stacks; no name lists them`)
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

		run(
			"sudo",
			"-n",
			"nixos-rebuild",
			"switch",
			"--flake",
			DOTFILES_PATH+"#"+to,
		)

	case "rb":
		run(
			"sudo",
			"-n",
			"nixos-rebuild",
			"switch",
			"--flake",
			DOTFILES_PATH+"#"+target,
		)

	case "b":
		run(
			"sudo",
			"-n",
			"nixos-rebuild",
			"build",
			"--flake",
			DOTFILES_PATH+"#"+target,
		)

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
			"nix",
			"develop",
			DOTFILES_PATH+"#checks",
			"--command",
			"bash",
			DOTFILES_PATH+"/packages/x/check.sh", target,
		)

	case "sh":
		if len(args) == 1 {
			run(
				"nix",
				"eval",
				DOTFILES_PATH+"#devShells."+SYSTEM,
				"--apply", "builtins.attrNames",
			)
			return
		}

		stacks := make([]string, 0, len(args)-1)
		for _, name := range args[1:] {
			stacks = append(
				stacks,
				DOTFILES_PATH+"#devShells."+SYSTEM+"."+name,
			)
		}

		if len(stacks) == 1 {
			run(
				"nix",
				"develop",
				stacks[0],
			)
		}

		run(
			append(append([]string{
				"nix", "shell",
			}, stacks...),
				"--command",
				"bash")...,
		)

	default:
		printUsage()
	}
}
