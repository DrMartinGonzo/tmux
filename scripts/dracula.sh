#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value=$(tmux show-option -gqv "$option")
  if [ -z $option_value ]; then
    echo $default_value
  else
    echo $option_value
  fi
}

main()
{
  # set current directory variable
  current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  # set configuration option variables
  show_battery=$(get_tmux_option "@dracula-show-battery" true)
  show_network=$(get_tmux_option "@dracula-show-network" true)
  show_weather=$(get_tmux_option "@dracula-show-weather" true)
  show_fahrenheit=$(get_tmux_option "@dracula-show-fahrenheit" true)
  show_location=$(get_tmux_option "@dracula-show-location" true)
  show_powerline=$(get_tmux_option "@dracula-show-powerline" false)
  show_flags=$(get_tmux_option "@dracula-show-flags" false)
  show_left_icon=$(get_tmux_option "@dracula-show-left-icon" smiley)
  show_left_icon_padding=$(get_tmux_option "@dracula-left-icon-padding" 1)
  show_military=$(get_tmux_option "@dracula-military-time" false)
  show_timezone=$(get_tmux_option "@dracula-show-timezone" true)
  show_left_sep=$(get_tmux_option "@dracula-show-left-sep" )
  show_right_sep=$(get_tmux_option "@dracula-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@dracula-border-contrast" false)
  show_cpu_usage=$(get_tmux_option "@dracula-cpu-usage" false)
  show_ram_usage=$(get_tmux_option "@dracula-ram-usage" false)
  show_gpu_usage=$(get_tmux_option "@dracula-gpu-usage" false)
  show_day_month=$(get_tmux_option "@dracula-day-month" false)
  show_time=$(get_tmux_option "@dracula-show-time" true)
  show_refresh=$(get_tmux_option "@dracula-refresh-rate" 5)
  force_city=$(get_tmux_option "@dracula-force-city")

  # Dracula Color Pallette
  white='#f8f8f2'
  gray='#44475a'
  dark_gray='#282a36'
  light_purple='#bd93f9'
  dark_purple='#6272a4'
  cyan='#8be9fd'
  green='#50fa7b'
  orange='#ffb86c'
  red='#ff5555'
  pink='#ff79c6'
  yellow='#f1fa8c'

  # Icons
  # nf-mdi-arrow_expand
  icon_zoom='ﬕ'
  icon_prefix=''

  # switch
  icon='﨡 '
  icon_mod='蘒 '

  # map marker
  # icon=' '
  # icon_mod='ﭐ '

  # octagon
  # icon=' '
  # icon_mod=' '

  # icon='😺 '
  # icon_mod='😼 '

  # status-left parts
  status_left_begin="#[bg=${dark_gray}]#{?client_prefix,#[fg=${yellow}],#[fg=${green}]}${icon_prefix}"
  status_left_switch="#{?client_prefix,#[bg=${yellow}] ${icon_mod},#[bg=${green}] ${icon}}"
  status_left_zoom="#{?window_zoomed_flag,${icon_zoom} ,}"

  # Handle left icon configuration
  case $show_left_icon in
      smiley)
          left_icon="☺";;
      session)
          left_icon="#S";;
      window)
          left_icon="#W";;
      *)
          left_icon=$show_left_icon;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
	  padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
      right_sep="$show_right_sep"
      left_sep="$show_left_sep"
  fi

  # start weather script in background
  if $show_weather; then
    $current_dir/sleep_weather.sh $show_fahrenheit $show_location $force_city &
  fi

  # Set timezone unless hidden by configuration
  case $show_timezone in
      false)
          timezone="";;
      true)
          timezone="#(date +%Z)";;
  esac

  case $show_flags in
    false)
      flags=""
      current_flags="";;
    true)
      flags="#{?window_flags,#[fg=${dark_purple}]#{window_flags},}"
      current_flags="#{?window_flags,#[fg=${light_purple}]#{window_flags},}"
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
	tmux set-option -g clock-mode-style 24
  else
	tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${gray},fg=${white}"

  # wait unit data/weather.txt exists just to avoid errors
  # this should almost never need to wait unless something unexpected occurs
  while $show_weather && [ ! -f $current_dir/../data/weather.txt ]; do
      sleep 0.01
  done

  # Powerline Configuration
  if $show_powerline; then

      tmux set-option -g status-left "${status_left_begin}#[fg=${dark_gray}]${status_left_switch}#S ${status_left_zoom}${left_sep}"
      tmux set-option -g  status-right ""
      powerbg=${gray}

      if $show_battery; then # battery
        tmux set-option -g  status-right "#[fg=${pink},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${pink}] #($current_dir/battery.sh)"
        powerbg=${pink}
      fi

      if $show_ram_usage; then
	 tmux set-option -ga status-right "#[fg=${cyan},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${cyan}] #($current_dir/ram_info.sh)"
	 powerbg=${cyan}
      fi

      if $show_cpu_usage; then
	 tmux set-option -ga status-right "#[fg=${orange},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${orange}] #($current_dir/cpu_info.sh)"
	 powerbg=${orange}
      fi

      if $show_gpu_usage; then
	 tmux set-option -ga status-right "#[fg=${pink},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${pink}] #($current_dir/gpu_usage.sh)"
	 powerbg=${pink}
      fi

      if $show_network; then # network
        tmux set-option -ga status-right "#[fg=${cyan},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${cyan}] #($current_dir/network.sh)"
        powerbg=${cyan}
      fi

      if $show_weather; then # weather
        tmux set-option -ga status-right "#[fg=${orange},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${orange}] #(cat $current_dir/../data/weather.txt)"
        powerbg=${orange}
      fi

      if $show_time; then
        if $show_day_month && $show_military ; then # military time and dd/mm
          tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %d/%m %I:%M %p ${timezone} "
        else
          tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %m/%d %I:%M %p ${timezone} "
        fi
      fi

      tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${dark_purple}]${left_sep}#[fg=${white},bg=${dark_purple}] #I #W${current_flags} #[fg=${dark_purple},bg=${gray}]${left_sep}"

  # Non Powerline Configuration
  else
    tmux set-option -g status-left "${status_left_begin}#[fg=${dark_gray}]${status_left_switch}#S ${status_left_zoom}"

    tmux set-option -g  status-right ""

      if $show_battery; then # battery
        tmux set-option -g  status-right "#[fg=${dark_gray},bg=${pink}] #($current_dir/battery.sh) "
      fi
      if $show_ram_usage; then
	tmux set-option -ga status-right "#[fg=${dark_gray},bg=${cyan}] #($current_dir/ram_info.sh) "
      fi

      if $show_cpu_usage; then
	tmux set-option -ga status-right "#[fg=${dark_gray},bg=${orange}] #($current_dir/cpu_info.sh) "
      fi

      if $show_gpu_usage; then
	tmux set-option -ga status-right "#[fg=${dark_gray},bg=${pink}] #($current_dir/gpu_usage.sh) "
      fi

      if $show_network; then # network
        tmux set-option -ga status-right "#[fg=${dark_gray},bg=${cyan}] #($current_dir/network.sh) "
      fi

      if $show_weather; then # weather
          tmux set-option -ga status-right "#[fg=${dark_gray},bg=${orange}] #(cat $current_dir/../data/weather.txt) "
      fi

      if $show_time; then
        if $show_day_month && $show_military ; then # military time and dd/mm
          tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %d/%m %I:%M %p ${timezone} "
        else
          tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %m/%d %I:%M %p ${timezone} "
        fi
      fi

      tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${dark_purple}] #I #W${current_flags} "

  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
}

# run main function
main
