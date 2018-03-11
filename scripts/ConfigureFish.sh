#!/bin/bash
#
# Configures the script shell upon installation
# Prerequisites: fish, git, wget
#
# Isaac Pateau

FONTS_DIR=$HOME/.local/share/fonts
FISH_CONFIG_FILE=$HOME/.config/fish/config.fish

# Go to fish folder
cd fish

# Install oh-my-fish
curl -L https://get.oh-my.fish > install
chmod 0755 install
fish -c "./install --noninteractive"

# Install bobthefish theme
fish -c "omf install bobthefish"

# Configure bobthefish
# Install/Configure noto-mono for Powerline (Ensure that noto-mono is the font used for the terminal)
wget https://github.com/powerline/fonts/blob/master/NotoMono/Noto%20Mono%20for%20Powerline.ttf -O NotoMonoForPowerline.ttf
mkdir -p $HOME/.local/share/fonts
cp NotoMonoForPowerline.ttf $HOME/.local/share/fonts
fc-cache -f $HOME/.local/share/fonts

# Set the theme's config
cp config.fish $HOME/.config/fish/
cp fish_greeting.fish $HOME/.config/fish/functions

# Download/configure fish-symnav
git clone https://github.com/externl/fish-symnav
cp fish-symnav/functions/* $HOME/.config/fish/functions
cp fish-symnav/conf.d/* $HOME/.config/fish/conf.d

if [ -f $HOME/.config/fish/functions/fish_user_key_bindings.fish ] ; then
    # Tell the user to add these lines to his/her keybindings
    echo "Please add these lines to your user key bindings"
    echo ""
    echo "set -l symnav_bind_mode default"
    echo "bind -M $symnav_bind_mode \t __symnav_complete"
    echo "bind -M $symnav_bind_mode \r __symnav_execute"
    echo "bind -M $symnav_bind_mode \n __symnav_execute"
else
    cp fish_user_key_bindings.fish $HOME/.config/fish/functions
fi

# Silence the output of symnav_initalize since the components are installed
sed -i '/echo "symnav: execution bindings may not be installed" 1>&2/ s/echo/#echo/g' $HOME/.config/fish/conf.d/symnav_initialize.fish
sed -i '/echo "symnav: completion bindings may not be installed" 1>&2/ s/echo/#echo/g' $HOME/.config/fish/conf.d/symnav_initialize.fish

# Cleanup
rm -rf fish-symnav

# Finished!
echo "Installation complete!"