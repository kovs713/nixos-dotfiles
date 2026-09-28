package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const targetFile = "/etc/x/target"

func usage() {
	fmt.Fprintln(os.Stderr, `usage: x [command]

  x              rebuild the live target
  x theme        switch to the other theme variant and rebuild
  x gc           nix store gc
  x update [in…] nix flake update
  x check        parse, format and evaluate, as the README says`)
	os.Exit(2)
}

func flip(target string) string {
	if host, ok := strings.CutSuffix(target, "-black"); ok {
		return host + "-white"
	}
	return strings.TrimSuffix(target, "-white") + "-black"
}

func liveTarget() string {
	raw, err := os.ReadFile(targetFile)
	if err != nil {
		fmt.Fprintf(os.Stderr,
			"x: %s: %v\n  no switch has run yet; start with:\n    sudo nixos-rebuild switch --flake %s#laptop-black\n",
			targetFile, err, flakeDir())
		os.Exit(1)
	}

	target := strings.TrimSpace(string(raw))
	if target == "" {
		fmt.Fprintf(os.Stderr, "x: %s is empty\n", targetFile)
		os.Exit(1)
	}

	return target
}

func flakeDir() string {
	if dir := os.Getenv("FLAKE"); dir != "" {
		return dir
	}

	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "x: %v\n", err)
		os.Exit(1)
	}

	return filepath.Join(home, "dotfiles")
}

func flakeRef(target string) string {
	dir, err := filepath.Abs(flakeDir())
	if err != nil {
		fmt.Fprintf(os.Stderr, "x: %v\n", err)
		os.Exit(1)
	}

	return dir + "#" + target
}

func run(argv ...string) {
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr

	if err := cmd.Run(); err != nil {
		os.Exit(1)
	}
}

func switchTo(target string) {
	run("sudo", "-n", "nixos-rebuild", "switch",
		"--flake", flakeRef(target), "--profile-name", target)
}

const checkScript = `
set -e
cd "$1"
files=$(find modules home packages -name '*.nix')
for file in $files; do nix-instantiate --parse "$file" >/dev/null; done
nixfmt --check $files
nix eval --no-update-lock-file "$2#nixosConfigurations.$3.config.system.build.toplevel.drvPath"
for test in model-sync fuzzy calendar launcher-search; do
  node home/laptop/quickshell/$test.test.mjs
done
`

func check() {
	run("nix", "develop", "--command", "bash", "-c", checkScript,
		"x check", flakeDir(), flakeDir(), liveTarget())
}

func main() {
	args := os.Args[1:]

	if len(args) == 0 {
		switchTo(liveTarget())
		return
	}

	switch args[0] {
	case "rebuild":
		switchTo(liveTarget())
	case "theme":
		from, to := liveTarget(), flip(liveTarget())
		fmt.Println("theme:", from, "->", to)
		switchTo(to)
	case "gc":
		run("sudo", "-n", "nix", "store", "gc")
	case "update":
		run(append([]string{"nix", "flake", "update"}, args[1:]...)...)
	case "check":
		check()
	default:
		usage()
	}
}
