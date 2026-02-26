# fusion-services-core

Shared Go packages for Fusion services. This module is intended to hold cross-service utilities (network/VIP handling, etc.) that are not specific to a single service.

## Packages

- `network`: VRRP listener used to observe VIP ownership changes from keepalived VRRP advertisements.
- `vip`: VIP helpers (validation, canonicalization, keepalived.conf read/write, local config, and local VIP notification).

## Usage (from another service)

In your service `go.mod`:

```
require fusion-services-core v0.0.0

replace fusion-services-core => ../../fusion-services-core
```

Or, use a workspace file at the repo root:

```
go 1.23.1

use (
	./fusion-server/fusion
	./fusion-services-core
)
```

Then import packages, for example:

```go
import "fusion-services-core/vip"

if err := vip.Validate("192.168.2.100/24"); err != nil {
	// handle
}
```

## Notes

- The `network` package expects a minimal logger interface (Debug/Error) to avoid pulling in service-specific logging.
- The `vip` package includes `SendLocalStatus` for a local UDP notification schema.

## Development

- This module targets Go 1.23.1.
- Run `gofmt` on changes before committing.
