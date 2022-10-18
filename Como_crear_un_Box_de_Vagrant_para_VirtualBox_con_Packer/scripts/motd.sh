#!/bin/sh -eux

if [ -d /etc/update-motd.d ]; then
    MOTD_CONFIG='/etc/update-motd.d/99-jpaybar'

    cat > "$MOTD_CONFIG" <<JPAYBAR
#!/bin/sh

echo "\n\033[1;34mWelcome to this Vagrant-built VM. Customized by Juan M. Payan Barea.\nhttps://github.com/jpaybar (st4rt.fr0m.scr4tch@gmail.com)\nhttps://www.linkedin.com/in/juanmanuelpayan/\033[0m\n"
JPAYBAR

    chmod 0755 "$MOTD_CONFIG"
else
    echo -e "\n\033[1;34mWelcome to this Vagrant-built VM. Customized by Juan M. Payan Barea.\nhttps://github.com/jpaybar (st4rt.fr0m.scr4tch@gmail.com)\nhttps://www.linkedin.com/in/juanmanuelpayan/\033[0m\n" > /etc/motd
fi
