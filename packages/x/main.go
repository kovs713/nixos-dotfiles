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
			"x: %s: %v\n  no switch has run yet; start with:\n    sudo nixos-rebuild switch --flake %s#laptop-black\n",
			TARGET_FILE, err, flakeDir())
		os.Exit(1)
	}

	target := strings.TrimSpace(string(raw))
	if target == "" {
		fmt.Fprintf(os.Stderr, "x: %s is empty\n", TARGET_FILE)
		os.Exit(1)
	}

	return target
}

// never the cwd: nix resolves a relative flake against where it runs, so
// `x` from some other repo would build that repo instead of this one
func flakeDir() string {
	return DOTFILES_PATH
}

func flakeRef(target string) string {
	return flakeDir() + "#" + target
}

func run(argv ...string) {
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr

	if err := cmd.Run(); err != nil {
		os.Exit(1)
	}
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

		// no --profile-name: a named profile leaves /nix/var/nix/profiles/system
		// where it was, so the next boot runs that older system instead
		run("sudo", "-n", "nixos-rebuild", "switch", "--flake", flakeRef(to))

	case "rb":
		run("sudo", "-n", "nixos-rebuild", "switch", "--flake", flakeRef(target))

	case "b":
		run("sudo", "-n", "nixos-rebuild", "build", "--flake", flakeRef(target))

	case "gc":
		run("sudo", "-n", "nix", "store", "gc")

	case "upd":
		run(append([]string{"nix", "flake", "update", "--flake", flakeDir()}, args[1:]...)...)

	case "ch":
		run("nix", "develop", "--command", "bash", "-c", checkScript,
			"x check", flakeDir(), flakeDir(), target)

	case "test":
		fmt.Println(flakeDir())

	default:
		printUsage()
	}
}
