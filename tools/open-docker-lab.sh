# open the web lab via a browser

TOP_DIR=$(dirname `readlink -f $0`)

browser=chromium-browser
local_port=6080
[ -f $TOP_DIR/.lab_local_port ] && local_port=$(< $TOP_DIR/.lab_local_port)
url=http://localhost:$local_port/vnc.html
pwd=ubuntu
[ -f $TOP_DIR/.lab_login_pwd ] && pwd=$(< $TOP_DIR/.lab_login_pwd)

which $browser 2>&1>/dev/null \
    && ($browser $url 2>&1>/dev/null &) \
    && echo "Please login $url with password: $pwd"


# Create local shotcut on  Desktop
if [ -d ~/Desktop ]; then
    echo '#!/usr/bin/env xdg-open' >  ~/Desktop/linux-lab.desktop
    cat $TOP_DIR/linux-lab.desktop | sed "s%Exec=.*%Exec=$browser $url%g" | sed "s%lxterminal.xpm%chromium-browser.png%g">> ~/Desktop/linux-lab.desktop
    chmod a+x ~/Desktop/linux-lab.desktop
fi
