#!/bin/bash

# Backup existing Exim configuration
cp -f /etc/exim.conf /etc/exim.conf.bak

# Reset Exim to default configuration (if available)
if [ -f /etc/exim4/exim4.conf.template ]; then
    cp -f /etc/exim4/exim4.conf.template /etc/exim.conf
elif [ -f /etc/exim/exim.conf.default ]; then
    cp -f /etc/exim/exim.conf.default /etc/exim.conf
fi

# Manual configuration
read -p "Masukkan nama pengguna SMTP: " smtp_username
read -s -p "Masukkan kata sandi SMTP: " smtp_password
echo
read -p "Masukkan route_data (contoh, mail.example.com): " route_data

# Set host_address variable
host_address='$host_address'

# Content of the exim.conf.local file
exim_conf_content=$(cat <<EOL
%RETRYBLOCK%
+secondarymx                    *                               F,4h,5m; G,16h,1h,1.5; F,4d,8h
*                               *                               F,2h,15m; G,16h,1h,1.5; F,4d,8h
@AUTH@
smtp_login:
    driver = plaintext
    public_name = LOGIN
    hide client_send = : $smtp_username : $smtp_password
@BEGINACL@

@CONFIG@


@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@

@POSTMAILCOUNT@

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@
smtp_pacekopat:
    driver = manualroute
    transport = smtp_pacekopat
    domains = ! +local_domains
    route_data = $route_data
@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@
smtp_pacekopat:
    driver = smtp
    port = 587
    hosts_require_auth = $host_address
    hosts_require_tls = $host_address
EOL
)

# Save advanced configuration to temporary file
echo "$exim_conf_content" | sudo tee "/etc/exim.conf.local" > /dev/null

# Restart Exim
echo "Restarting Exim..."
sudo service exim restart

# Display success message
echo "Exim configuration saved and Exim restarted."
