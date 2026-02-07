# GRE Tunnel Auto Setup

A simple, interactive **bash script** that automatically creates and persists a **GRE tunnel** (Generic Routing Encapsulation) between two Linux servers using **systemd**.

Great for quick point-to-point tunnels, testing, lab environments, bypassing some NAT/firewall restrictions, or routing private traffic over the public internet.

## Features

- Auto-detects local public IPv4 (via ipify.org)
- Interactive setup — asks only the necessary questions
- Creates **persistent** tunnel using a systemd service
- Automatically chooses next available tunnel name (`gre1`, `gre2`, …) if not specified
- Enables & starts the tunnel immediately
- Cleans up previous iptables rules (filter + nat) — **careful!**
- Shows clear summary at the end

## Prerequisites

- Root / sudo access
- Linux server with `ip` command (iproute2 package — almost always pre-installed)
- Kernel module `ip_gre` available (most modern kernels have it)
- Both servers must be able to reach each other on port **UDP/47** (GRE protocol)

## Installation

