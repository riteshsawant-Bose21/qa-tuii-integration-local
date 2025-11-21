# Fusion Device Setup

The user will connect to the Fusion Device using a mobile application over Bluetooth.

## Configuration Tasks

The first task will be to configure the device. These properties must be set:

### Virtual IP Address

- This is the public address that can be accessed over WiFi or the physical network.
- This address sits in front of a network of Fusion Devices.
- Setting this value requires technical knowledge of the network the Fusion device is on.
- While each device may have a DHCP address, a **static IP address** must be used for the VIP.

### Device Name

- This is a user-specified name for the device.
- It must be unique, although a conflicting name will have no effect on the operation of the device network.

### Location

- This is a user-specified device location.
- It does **not** need to be unique.

### Unique Identifier

- This is a unique identifier provided by the DRO.
- It must be unique across all devices in the Fusion network.
- The user will **not** set this identifier manually—it is assigned by the DRO and set via an API call.

## Setting the VIP

To set the VIP, the setup application will make a `POST` call to:

    /devices/vip/:vip

This call will be made over the Dart-to-Bluetooth HTTP bridge.  
The `:vip` parameter will be the desired new VIP, e.g., `192.168.2.100`.

- The VIP will be validated and propagated across all Fusion devices.
- If called over HTTP, the URL would be:

      http://dhcp_address:8080/devices/vip/:vip


## Getting the VIP

To get the VIP, make a `GET` call to:
    
    /devices/vip

The returned JSON data will contain the VIP and the local address of the Fusion
device that is currently maintaining the VIP.

    {
    "local": "192.168.64.3",
    "vip": "192.168.2.100"
    }

## Setting Device ID, Location, and Name

To set device ID, location, and name, the setup application will call:

    /device

- If called over HTTP, the route URL would be:

      http://dhcp_address:9090/device

- This call is made over a direct Bluetooth connection using the Dart-to-Bluetooth HTTP bridge.
- The `/device` endpoint is intended **only** for the setup application and internal Fusion server use.

## Configuring Devices After VIP Setup

Once the Fusion network is configured with a VIP, a device can be configured using a `PATCH` call:

    http://vip:8080/devices/:id

- `:id` is the unique identifier provided by the DRO.
- As a `PATCH` call, only a subset of the device info parameters can be provided.

Example:

    {
      "location": "foyer"
    }

## Retrieving All Device Information

Device information can be retrieved using a `GET` call to:

    /devices

The response will be a JSON array, where each element contains the device's address, ID, location, name, xyte_cloud_id, is_claimed from xyte_cloud,serial_number of Board :

    [
      {
        "address": "192.168.64.4",
        "id": "fusion2_instance",
        "location": "",
        "name": "fusion2",
        "xyte_cloud_id": "",
        "is_claimed": false,
        "serial_number": "Serial Number of Device"
      },
      {
        "address": "192.168.64.5",
        "id": "fusion3_instance",
        "location": "",
        "name": "fusion3",
        "xyte_cloud_id": "",
        "is_claimed": false,
        "serial_number": "Serial Number of Device"
      },
      {
        "address": "192.168.64.6",
        "id": "test-device",
        "location": "RoomB",
        "name": "RenamedDevice",
        "xyte_cloud_id": "",
        "is_claimed": false,
        "serial_number": "Serial Number of Device"
      }
    ]