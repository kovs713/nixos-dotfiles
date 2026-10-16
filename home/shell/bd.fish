set -l target $argv[1]
if test -z "$target"
    set target .
end
find $target -type f -exec sh -c 'for f do printf "\n--- %s ---\n" "$f"; bat "$f"; done' sh {} + | wl-copy
