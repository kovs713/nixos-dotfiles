set -l target_dir $argv[1]
if test -z "$target_dir"
    set target_dir $PWD
end
set -l session_name (basename "$target_dir")
if test -n "$TMUX"
    if tmux has-session -t "$session_name" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        tmux new-session -d -s "$session_name" -c "$target_dir"
        tmux switch-client -t "$session_name"
    end
else
    if tmux has-session -t "$session_name" 2>/dev/null
        tmux attach-session -t "$session_name"
    else
        tmux new-session -s "$session_name" -c "$target_dir"
    end
end
