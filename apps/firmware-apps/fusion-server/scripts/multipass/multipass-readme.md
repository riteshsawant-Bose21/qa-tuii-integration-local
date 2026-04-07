# Multipass Recovery (macOS)

Use this guide when Multipass hangs or `multipass list` does not respond.

## What this does

This process fully resets Multipass by:

1. Stopping the Multipass daemon
2. Deleting all local Multipass instance data
3. Starting the daemon again

## Warning

This is a destructive reset. It permanently removes all local Multipass VMs and their data.

## Reset Steps

### 1. Stop Multipass

```bash
sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
```

### 2. Delete Multipass data

```bash
sudo rm -rf "/var/root/Library/Application Support/multipassd"
```

### 3. Start Multipass

```bash
sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist
```

### 4. Verify reset

```bash
multipass list
```

Expected result: no previous instances should appear.

## Optional health check

```bash
multipass launch --name test-vm
multipass list
```

If the test VM starts and appears in the list, Multipass is working again.