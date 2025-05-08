# Enabling Bridged Networking in Multipass on macOS

Multipass on macOS does not support bridged networking out of the box. This guide demonstrates how to patch Multipass’s internal QEMU invocation by replacing the `qemu-system-aarch64` binary with a custom wrapper script that enables bridged networking using macOS's `vmnet.framework`.

> ⚠️ This method is **experimental and unsupported by Canonical**. It may break after updates to Multipass or QEMU. Proceed at your own risk.

## ✅ Prerequisites

- macOS Ventura or newer
- Multipass installed
- `vmnet.framework` is available (default in macOS)
- Multipass VMs using Apple Silicon (aarch64) architecture

## 📍 Step-by-Step Instructions

### 1. Locate the QEMU directory used by Multipass

```bash
cd "/Library/Application Support/com.canonical.multipass/bin"
```

> This is where the `qemu-system-aarch64` binary lives.

### 2. Back up the original QEMU binary

```bash
sudo mv qemu-system-aarch64 qemu-system-aarch64.real
```

### 3. Copy the wrapper script
```bash
sudo cp qemu-system-aarch64 "/Library/Application Support/com.canonical.multipass/bin/qemu-system-aarch64"
```

### 4. Make the script executable

```bash
sudo chmod +x "/Library/Application Support/com.canonical.multipass/bin/qemu-system-aarch64"
```

### 5. Restart Multipass daemon

```bash
sudo launchctl kickstart -k system/com.canonical.multipassd
```

### 6. Launch a new instance

```bash
multipass launch --name test-bridged
multipass list
```

You should see the instance now has both a `192.168.64.x` address **and** a `10.x.x.x` address (bridged via LAN).

## ✅ Verification

You can confirm bridged operation with:

```bash
multipass exec test-bridged -- ip a
```

And look for an IP in the `10.0.0.x` range assigned to a bridged interface (e.g., `enp0s5`).

You should also be able to:

- `ping` this IP from your host
- `ssh` or `curl` from other devices on your LAN

## 🧼 To Revert

Restore the original binary:

```bash
sudo rm qemu-system-aarch64
sudo mv qemu-system-aarch64.real qemu-system-aarch64
```

Then restart the daemon:

```bash
sudo launchctl kickstart -k system/com.canonical.multipassd
```

## 🧠 Notes

- This patch affects **all Multipass instances**, including those not needing bridged networking.
- macOS may require special permissions for QEMU to use `vmnet.framework`.
- Using UTM or direct QEMU is a more stable long-term alternative.
