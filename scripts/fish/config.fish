# Remove Fish Greeting
set fish_greeting ""

# Setup git in English
alias git "env LANG=en_US git"

# Setup Alias for apbs
alias apbs "/home/isaac/.PersonnalStuff/scripts/apbs"

# Setup Android stuff
set PATH $PATH /data/Android/Sdk/tools/
set PATH $PATH /data/Android/Sdk/platform-tools/
#set PATH $PATH /home/isaac/bin/

# Setup bobthefish theme stuff
set -g theme_color_scheme solarized-dark
set -g theme_display_date no
set -g theme_display_ruby no
set -g theme_display_cmd_duration no
set -g theme_display_greeting no

# Set fish-symnav configuration
set -g symnav_execute_substitution 1
set -g symnav_prompt_pwd 1
set -g symnav_fish_prompt 1