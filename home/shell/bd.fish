set -l target $argv[1]
if test -z "$target"
    set target .
end
find $target -type f -exec bat \{\} + | wl-copy
