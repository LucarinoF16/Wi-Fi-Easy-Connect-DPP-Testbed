#!/bin/bash

# === Variables ===
INTERFACE="wlan1"
DRIVER="nl80211"
CONF_PATH="/etc/dpp/dpp.conf"
KEY_FILE="/etc/dpp/privatekey.hex"
MAC="00c0cab79536"
CHANNEL="81/6"

# === Read ASN.1 DER Key ===
if [[ ! -f "$KEY_FILE" ]]; then
  echo "Error: Key not found. Create it first with CrPrKey.sh"
  exit 1
fi

KEY_HEX=$(< "$KEY_FILE")

# === Starting wpa_supplicant-dpp with debug in log ===
sleep 20
echo -e "Starting wpa_supplicant...\n"
sudo ip link set $INTERFACE down
sudo rfkill unblock wifi
sudo pkill -f wpa_supplicant 2>/dev/null
sudo pkill -f wpa_supplicant-dpp 2>/dev/null
sudo rm -f /var/run/wpa_supplicant/$INTERFACE
sudo /home/irtlab/Desktop/refresh.sh
sleep 1
sudo ip link set $INTERFACE up
sleep 2

sudo wpa_supplicant -i "$INTERFACE" -D "$DRIVER" -c "$CONF_PATH" -dd > /tmp/wpa_dpp.log 2>&1 &

sleep 2  # wait for uptime

# === Creating Bootstrap with key ===
echo -e "Generating Bootstrap Uri\n"
sudo wpa_cli -i "$INTERFACE" dpp_bootstrap_gen \
  type=qrcode \
  key="$KEY_HEX" \
  mac="$MAC" \
  chan="$CHANNEL"

# === Start Listening ===
echo -e "\nSetting Device on DPP_Listen (2437 MHz)..."
sudo wpa_cli -i "$INTERFACE" dpp_listen 2437

# Show URI
echo -e "\nHere is your Bootstrap Public Key: \n"
sudo wpa_cli -i "$INTERFACE" dpp_bootstrap_get_uri 1
echo -e "\nOr scan this QR Code if possible: \n"
sudo wpa_cli -i "$INTERFACE" dpp_bootstrap_get_uri 1 | qrencode -t ansiutf8
sudo /home/irtlab/Desktop/check.sh
sudo /home/irtlab/Desktop/Blink.sh #Remove this if not needed
sudo dhclient $INTERFACE
#sudo wpa_cli -i "$INTERFACE" (this is for debugging)

