#!/bin/bash
set -e

echo "=== GRE Tunnel Auto Setup ==="

# --- Detect current server public IPv4 ---
echo ">>> Detecting this server public IPv4..."
DETECTED_IP=$(curl -4 -s https://api.ipify.org || true)

if [[ -z "$DETECTED_IP" ]]; then
    echo "❌ Failed to detect public IPv4 automatically."
    read -p "Enter THIS server public IPv4 manually: " LOCAL_IP
else
    echo "Detected IPv4: $DETECTED_IP"
    read -p "Is this the public IP of THIS server? (y/n): " CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]' | xargs)

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "yes" ]]; then
        LOCAL_IP="$DETECTED_IP"
    else
        read -p "Enter THIS server public IPv4 manually: " LOCAL_IP
    fi
fi

# --- Destination server IP ---
read -p "Enter DESTINATION server public IPv4: " REMOTE_IP

# --- Tunnel IP ---
read -p "Enter LOCAL tunnel IP (example: 10.10.10.1/30): " LOCAL_TUN_IP

# --- Tunnel name ---
read -p "Enter tunnel name (press Enter for auto: gre1, gre2...): " CUSTOM_NAME
CUSTOM_NAME=$(echo "$CUSTOM_NAME" | xargs)

if [[ -z "$CUSTOM_NAME" ]]; then
    i=1
    while [[ -e /etc/systemd/system/gre$i.service ]]; do
        ((i++))
    done
    TUN_NAME="gre$i"
else
    TUN_NAME="$CUSTOM_NAME"
fi

SERVICE_FILE="/etc/systemd/system/${TUN_NAME}.service"

echo ">>> Flushing iptables (filter + nat)"
iptables -F
iptables -t nat -F
iptables -X

echo ">>> Creating systemd service: $SERVICE_FILE"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=GRE Tunnel $TUN_NAME
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=/sbin/modprobe ip_gre
ExecStart=/sbin/ip tunnel add $TUN_NAME mode gre local $LOCAL_IP remote $REMOTE_IP ttl 255
ExecStart=/sbin/ip addr add $LOCAL_TUN_IP dev $TUN_NAME
ExecStart=/sbin/ip link set $TUN_NAME up

ExecStop=/sbin/ip link set $TUN_NAME down
ExecStop=/sbin/ip tunnel del $TUN_NAME

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Enabling and starting GRE tunnel"
systemctl daemon-reload
systemctl enable "$TUN_NAME"
systemctl start "$TUN_NAME"

echo
echo "✅ GRE Tunnel CREATED SUCCESSFULLY"
echo "--------------------------------"
echo "Tunnel Name : $TUN_NAME"
echo "Local IP    : $LOCAL_IP"
echo "Remote IP   : $REMOTE_IP"
echo "Tunnel IP   : $LOCAL_TUN_IP"
echo "Persistent  : YES (systemd)"
