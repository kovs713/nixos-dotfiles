set -l new_flag 0
if test "$argv[1]" = "-n" -o "$argv[1]" = "--new"
    set new_flag 1
end

set -l selected_dir (zoxide query -l | fzf)
if test -z "$selected_dir"
    return 0
end

# Sanitize base name
set -l raw_base (basename "$selected_dir")
set -l base (string replace -r -a '[[:space:].]+' '_' -- $raw_base | \
             string replace -r -a '[^[:alnum:]_-]' '_' -- | \
             string replace -r '^_+|_+$' '' --)

if test -z "$base"
    set base "tmux"
end

# Generate hash
set -l hash (printf '%s' "$selected_dir" | cksum | awk '{printf "%04x", $1 % 65535}')

set -l session_name (printf "%s_%s" "$base" "$hash")

if test "$new_flag" -eq 1
    set -l orig_session "$session_name"
    set -l n 2
    while tmux has-session -t "=$session_name" 2>/dev/null
        set session_name (printf "%s-%d" "$orig_session" $n)
        set n (math $n + 1)
        if test "$n" -gt 99
            set -l rand_hex (printf '%04x' (random 0 65535))
            set session_name (printf "%s_%s" "$orig_session" "$rand_hex")
            break
        end
    end
end

if not tmux has-session -t "=$session_name" 2>/dev/null
    tmux new-session -d -s "$session_name" -c "$selected_dir"
end

if test -n "$TMUX"
    tmux switch-client -t "=$session_name"
else
    tmux attach-session -t "=$session_name"
end
