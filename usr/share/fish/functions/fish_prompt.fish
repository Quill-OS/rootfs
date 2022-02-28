function fish_prompt
    if ! test (id -u) -eq 0
        set_color brgreen
        echo -n "$USER"
        set_color normal
        echo -n "@"
        set_color F67400
	set current_path (set current_path_raw (pwd) && if [ "$current_path_raw" = "$HOME" ]; echo -n "~"; else; echo -n "$current_path_raw"; end)
        echo (hostname) (set_color green; echo -n "$current_path")(set_color normal)'>' (set_color normal)
    else
        set_color brgreen
        echo -n "$USER"
        set_color normal
        echo -n "@"
	set current_path (set current_path_raw (pwd) && if [ "$current_path_raw" = "$HOME" ]; echo -n "~"; else; echo -n "$current_path_raw"; end)
        echo (hostname) (set_color red; echo -n "$current_path")(set_color normal)'#' (set_color normal)
    end
end
