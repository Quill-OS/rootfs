function fish_prompt
    if ! test (id -u) -eq 0
        set_color brgreen
        echo -n "$USER"
        set_color normal
        echo -n "@"
        set_color F67400
        echo (hostname) (set_color green; pwd)(set_color normal)'>' (set_color normal)
    else
        set_color brgreen
        echo -n "$USER"
        set_color normal
        echo -n "@"
        echo (hostname) (set_color red; pwd)(set_color normal)'#' (set_color normal)
    end
end
