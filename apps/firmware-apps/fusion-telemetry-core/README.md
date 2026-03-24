# Fusion Telemetry Core
This repository contains the source code and associated files for the fusion telemetry core firmware application.

## Requirements
The applications uses the following components and expects them to be installed on the build machine and the target.
1. Boost
2. SPDLOG

The make file supports x86 and ARM (i.MX8) architectures. In order to build for the i.MX8 target the SDK has to be installed. The script for installing the SDK can be downloaded from https://boseprofessional.sharepoint.com/:f:/s/FusionMVPTeam/En2Kvq3tm-BPiR0roMCaDPoB-HJMfQ5-pLCbVbECYoAEXw?e=95yzJm

Follow the steps bellow to install and use the SDK.
1. Create a directory to install the Fusion Yocto SDK in.
    >*SDK_DIR=/bose/fusion/yocto-sdk/*

    >*mkdir $SDK_DIR*

2. Install the SDK (do this only once).
    >*./imx8mm-var-dart-fusion-toolchain-4.2.2.sh -y -d $SDK_DIR*

3. Use the SDK (Do this every time you have a new terminal and need to build using the SDK)
    >*source $SDK_DIR/environment-setup-cortexa53-crypto-poky-linux*

## Building the application
The application uses *make*. To build the application run *make* from the application root folder. *make clean* will remove all the generated files.

With waf:

>*./waf configure && ./waf*

## Running unit tests

GoogleTest-based unit tests are built when `gtest` is available via `pkg-config`.

Build and run:

>*./waf configure && ./waf*

>*./build/telemetry_core_tests*

## Running the application
The application accepts the following arguments
1. The system IP and port number (-i IP:Port)

    This is a **Mandatory** argument. The format is *IP:Port*.

2. Configuration file. (-c full/path/of/config/file)

    Full path to the configuration file (JSON). This is an optional argument and the default file and path are *./config/telemetry-configuration.json*.

3. Unix Socket file path (-p /Unix/socket/file/path)

    Full path of the Unix socket file. This overrides the value in the configuration file.

4. Meter Data Update Request period (-u Hi_period Med_period Lo_period)

    The HI, MED & LO meters update request periods. This overrides the values in the configuration file.
    The units are in frames (1 frame = 2/3ms)

5. Meter Data Report period (-r Hi_period Med_period Lo_period)

    The HI, MED & LO meters report periods. This overrides the values in the configuration file.
    The units are in frames (1 frame = 2/3ms). The report periods must be mutiples of the respective update periods.

## Usage example:

>*./telemetry_core -c ./config/telemetry_configuration.json -i 172.23.100.178:1234*

## Telemetry Compatibility Policy

Fusion telemetry components must be able to participate in rolling upgrades without
requiring a device reboot or forcing every telemetry-related service to move in
lockstep. The telemetry compatibility contract therefore has to be explicit.

### Version Layers

The telemetry path has four distinct versioned surfaces:

1. Control protocol version
   The request/response protocol carried by messages such as
   `pub_register_req`, `pub_register_rsp`, `update_meters_req`, and
   `update_meters_rsp`.

2. Shared-memory region format version
   The header written at the start of the shared-memory region.

3. Structured payload format version
   The header written before each structured payload written with
   `NamedSharedMemory::write()`.

4. Raw blob envelope version
   The header written before raw telemetry JSON written with
   `NamedSharedMemory::lightWeightWrite()`.

These version layers must evolve intentionally and must not rely on implicit
behavior or matching source trees.

### Current Enforcement

The current implementation now enforces a one-version compatibility window for
the control path and explicit version headers for shared-memory transport:

- Control protocol/schema accepts `N` and `N-1`
- Publishers and telemetry-core both enforce the same control-message policy
- Shared-memory region headers are self-describing and validated
- Structured payloads written with `NamedSharedMemory::write()` carry
  self-describing per-payload headers
- Raw telemetry blobs written with `NamedSharedMemory::lightWeightWrite()`
  carry a versioned blob envelope
- Readers still tolerate legacy unframed raw blobs as a compatibility fallback

At the moment the concrete accepted versions are:

- Current protocol version: `1`
- Current schema version: `1`
- Accepted compatibility window: `1` and `0`

The shared compatibility helpers live in the shared interface layer so both the
publisher and telemetry-core use the same policy.

### Rolling Upgrade Policy

The release policy for telemetry components is:

- Only adjacent compatibility is required: `N` must interoperate with `N` and `N-1`
- Skipping versions is not supported: `N` does not need to interoperate with `N-2`
- Mixed-version operation is allowed only for the duration of a rolling upgrade or rollback
- After rollout completes, the cluster should converge to a single telemetry protocol generation

In practical terms:

- A new `fusion-telemetry-core` release at version `N` must accept publishers using
  control protocol/schema `N` and `N-1`
- A new publisher release such as `fusion-dsp` or `fusion-system-monitor` at version `N`
  must understand telemetry-core requests at protocol/schema `N` and `N-1`
- Shared-memory readers must be able to validate and consume payload formats for
  their own version and the immediately previous version
- Any change that cannot satisfy the `N` / `N-1` rule defines a new restart domain
  and must be rolled out as a coordinated update of the affected services

### Release Window Rules

Telemetry compatibility support should remain in place for one release window:

- Release `N` introduces support for `N` and preserves support for `N-1`
- Release `N+1` may remove support for `N-1` if the fleet has already converged
- Rollback from `N` to `N-1` must remain supported during the rollout of `N`

This means the system should tolerate one-version skew, but not indefinite skew.

### Compatibility Matrix

The intended acceptance matrix is:

| Telemetry Core | Publisher | Supported |
| --- | --- | --- |
| `N` | `N` | yes |
| `N` | `N-1` | yes |
| `N-1` | `N` | yes |
| `N` | `N-2` | no |
| `N+1` | `N-1` | no |

The same rule applies to structured payloads and raw blob envelopes.

### Change Classification

Changes must be classified before release:

- Backward-Compatible Additions: Add fields, add optional capabilities, and preserve
  existing semantics. These may keep the same major protocol generation and remain
  compatible with `N-1`.

- Compatibility-Breaking Changes: Remove fields, repurpose fields, change payload
  meaning, change shared-memory layout, or require a new control-flow assumption.
  These require a new protocol/schema generation and must preserve `N-1`
  compatibility for one rollout window unless the affected services are explicitly
  treated as a restart domain.

### Operational Rule

If a telemetry change cannot satisfy the one-version compatibility window, it must
not be justified by rebooting the device. Instead, the affected services must be
called out explicitly as a coordinated restart domain and updated together under
service-level orchestration.

### Follow-On Implementation Work

The policy above is now partially implemented. The highest-value remaining work is:

- Extend the same `N` / `N-1` discipline to any remaining non-telemetry
  cross-service contracts
- Add stronger integration coverage around real publisher/core interaction paths
  if socket-level end-to-end tests become practical
- Document the current telemetry restart domain when a change is intentionally
  not compatible
- Define release-process rules for when `N-1` support may be removed
