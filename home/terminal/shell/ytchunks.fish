if test (count $argv) -eq 0
    echo 'usage: ytchunks "youtube-url"'
    return 1
end

set -l url $argv[1]
set -l tmp "$HOME/Music/.ytchunks_tmp"
set -l title (yt-dlp --print "%(title)s" --skip-download "$url")
if test $status -ne 0
    return 1
end

yt-dlp \
    -x --audio-format mp3 \
    --embed-thumbnail \
    --split-chapters \
    -o "chapter:$HOME/Music/%(title)s/%(section_title)s.%(ext)s" \
    -o "$tmp/%(title)s.%(ext)s" \
    "$url"
or return 1

rm -f "$tmp/$title.mp3" "$tmp/$title.webp" "$tmp/$title.png"

set -l dir "$HOME/Music/$title"
for f in "$dir"/*.mp3
    test -f "$f"; or continue
    set -l t (basename "$f" .mp3)
    ffmpeg -y -i "$f" -map 0 -map_metadata -1 -c copy \
        -metadata title="$t" "$f.tmp.mp3"
    and mv "$f.tmp.mp3" "$f"
end

echo "done: $dir"
