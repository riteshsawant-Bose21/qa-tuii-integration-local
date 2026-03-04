# Firmware Update API - Comprehensive Review

**Reviewer:** Senior Software Engineer  
**Date:** March 4, 2026  
**Status:** Review Complete - Recommendations Enclosed

---

## Executive Summary

The current implementation uses **"firmware"** as the umbrella term for device update functionality, but you've correctly identified a semantic mismatch:

| What You Call It | What It Actually Does |
|------------------|----------------------|
| `firmware` | Delivers **bundles** containing firmware + software |
| `FirmwareUpdateHandler` | Handles bundle operations (upload, approve, download) |
| `/firmware/*` endpoints | Serve device update bundles |

**Core Issue:** The term "firmware" is too narrow for what the system delivers.

---

## Part 1: Naming Taxonomy Analysis

### Current Terminology vs Reality

```
┌─────────────────────────────────────────────────────────────────┐
│                DEVICE UPDATE BUNDLE                             │
│         (Contains Firmware + Device Software)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────────────────────────┐  │
│  │      FIRMWARE       │  │     DEVICE SOFTWARE             │  │
│  │  (low-level device  │  │  (backend services running      │  │
│  │   firmware)         │  │   on the device)                │  │
│  └─────────────────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              APPLICATION UPDATE (Future - Separate Module)      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Desktop/Mobile Application                 │    │
│  │         (Completely separate update system)             │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

**Note:** Application updates are a **completely separate module** and will NOT share the same bundle or API infrastructure as device updates.

### Recommended Terminology

| Current Name | Recommended Name | Reasoning |
|-------------|------------------|-----------|
| `firmware` | `deviceupdate` or `update` | More accurate for bundles containing firmware + software |
| `FirmwareUpdateHandler` | `DeviceUpdateHandler` or `UpdateHandler` | Reflects handling of complete update bundles |
| `Firmware` interface | `DeviceUpdate` or `UpdateService` | Service handles updates, not just firmware |
| `/firmware/*` | `/device-updates/*` or `/updates/*` | RESTful, describes actual function |
| `firmware.bundle.read` | `update.bundle.read` | Permission for update bundles |

---

## Part 2: Current Code Structure Review

### 2.1 File Structure

```
internal/
├── fusion/
│   ├── firmware.go              ← Interface definition (confusing name)
│   └── firmware/
│       ├── service.go           ← Service struct & interfaces
│       ├── firmware.go          ← Business logic
│       └── db/
│           └── service.go       ← Database operations
├── handler/
│   └── firmware.go              ← HTTP handlers
├── api/
│   └── types/
│       └── firmware.go          ← Request/Response types
├── constants/
│   └── endpoints.go             ← Route constants
└── middleware/
    └── permissions.go           ← Permission definitions
```

**Issues:**
1. `internal/fusion/firmware.go` defines `Firmware` interface but the package at `internal/fusion/firmware/` also exists → confusing
2. Interface name `Firmware` doesn't match what it does (bundle management)
3. The folder `firmware/` suggests it only handles firmware, not software+firmware bundles

### 2.2 Current Interface Definition

```go
// internal/fusion/firmware.go
type Firmware interface {
    NotifyBundleUpload(...)     // ✅ Uses "Bundle" - good
    ListBundles(...)            // ✅ Uses "Bundles" - good
    ApproveBundle(...)          // ✅ Uses "Bundle" - good
    CheckForUpdate(...)         // ✅ Generic "Update" - good
    GetBundleDownloadURL(...)   // ✅ Uses "Bundle" - good
    LogBundleUpdateStatus(...)  // ✅ Uses "Bundle" - good
}
```

**Observation:** Method names are good! They use "Bundle" and "Update" which are accurate. The interface name `Firmware` is the problem.

### 2.3 Handler Naming

```go
// internal/handler/firmware.go
type FirmwareUpdateHandler struct {
    firmware fusion.Firmware
}

func NewFirmwareUpdateHandler(firmware fusion.Firmware) *FirmwareUpdateHandler
```

**Issues:**
1. Field `firmware` suggests it's handling firmware operations, but it handles bundles
2. Handler name `FirmwareUpdateHandler` is misleading
3. The comment says "NewUserHandler creates..." - copy-paste error

### 2.4 Type Naming Analysis

| Current Type | Status | Recommendation |
|-------------|--------|----------------|
| `NotifyBundleUploadPayload` | ✅ Good | Keep - uses "Bundle" |
| `BundleResponse` | ✅ Good | Keep |
| `BundleDetails` | ✅ Good | Keep |
| `BundleListResponse` | ✅ Good | Keep |
| `CheckForUpdateRequest` | ✅ Good | Keep - generic "Update" |
| `CheckForUpdateResponse` | ✅ Good | Keep |
| `LogBundleUpdateStatusPayload` | ✅ Good | Keep - uses "Bundle" |
| `FirmwareReleaseDetails` | ⚠️ Deprecated | Remove if unused |
| `FirmwareReleaseListResponse` | ⚠️ Deprecated | Remove if unused |
| `DeviceUpdateCheckPayload` | ⚠️ Unused? | Remove or repurpose |
| `CheckUpdateRequest` | ⚠️ Unused? | Conflicts with CheckForUpdateRequest |
| `FirmwareRelease` | ⚠️ Deprecated | Comment says "use Bundle instead" |

### 2.5 Endpoint Constants Analysis

```go
// Current constants (internal/constants/endpoints.go)
EndpointFirmware              = "/firmware"
EndpointFirmwareBundles       = "/bundles"
EndpointFirmwareList          = "/bundles"
EndpointApproveBundle         = "/bundles/:bundleID/approve"
EndpointFirmwareUpdateCheck   = "/updates/check"
EndpointBundleDownload        = "/bundles/:bundleId/download"
EndpointLogBundleUpdateStatus = "/bundles/updates/status"
```

**Issues:**
1. `EndpointFirmwareBundles` and `EndpointFirmwareList` are identical (`"/bundles"`) - redundant
2. Inconsistent casing: `bundleID` vs `bundleId`
3. `/firmware` as base path is semantically incorrect for bundles containing software

### 2.6 Permission Naming

```go
// Current permissions
FirmwareBundleRead    = "firmware.bundle.read"
FirmwareBundleCreate  = "firmware.bundle.create"
FirmwareBundleApprove = "firmware.bundle.approve"
FirmwareUpdateCheck   = "firmware.update.check"
FirmwareDownload      = "firmware.download"
FirmwareUpdateLog     = "firmware.update.log"
```

**Issue:** These will need updating if the domain is renamed from "firmware" to "device-update" or "update".

---

## Part 3: Database Schema Review

### 3.1 Current Tables

```sql
-- Table: bundle
CREATE TABLE bundle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
    release_notes TEXT,
    min_prev_version TEXT NOT NULL,
    min_desktop_app_version TEXT NOT NULL,
    manifest_data JSONB NOT NULL,
    is_approved bool NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Table: bundle_update_status
CREATE TABLE bundle_update_status (
    id UUID PRIMARY KEY,
    update_id UUID NOT NULL,
    project_id UUID NOT NULL references project(id),
    bundle_version TEXT NOT NULL,
    previous_version TEXT,
    status bundle_update_status_enum NOT NULL,
    launcher_version TEXT,
    installed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Analysis:**
| Table Name | Status | Notes |
|------------|--------|-------|
| `bundle` | ✅ Good | Neutral, describes the package accurately |
| `bundle_update_status` | ✅ Good | Describes what it tracks |

**Recommendations:**
- Table names are good - they use "bundle" which is domain-agnostic
- Keep this table dedicated to device updates only
- Application updates (future) should use a completely separate table (`app_release`)

### 3.2 Schema Note

**Do NOT add a `bundle_type` column.** Application updates are a completely separate module and should have their own dedicated tables:

```sql
-- Current: Device updates (this module)
bundle                    -- Device update bundles
bundle_update_status      -- Device update status logs

-- Future: Application updates (separate module)
app_release               -- Desktop/mobile app releases
app_update_status         -- App update status logs
```

This separation ensures:
- Independent versioning and release cycles
- Different validation rules per update type
- Cleaner queries without type filtering
- Easier to maintain and scale independently

---

## Part 4: Recommended Refactoring Plan

### Option A: Minimal Impact (Recommended for Short-Term)

Change only the **public-facing** names while keeping internal structure:

| Change | From | To |
|--------|------|-----|
| CI/CD API Base Path | `/firmware/bundles` | `/cicd/bundles` |
| Client API Base Path | `/firmware` | `/device-updates` |
| Swagger Tags | "Firmware Update - CI/CD API" | "CI/CD API" |
| Swagger Tags | "Firmware Update - Client API" | "Device Updates" |
| Permission Prefix | `firmware.*` | `device-update.*` |

**Pros:** Minimal code changes, clear separation between CI/CD and client APIs  
**Cons:** Internal naming still uses "firmware"

### Option B: Full Refactoring (Recommended for Long-Term)

Complete rename across all layers:

#### 4.1 Folder Structure

```
internal/
├── fusion/
│   ├── device_update.go                    ← Renamed interface
│   └── deviceupdate/                       ← Renamed package
│       ├── service.go
│       ├── device_update.go                ← Renamed from firmware.go
│       └── db/
│           └── service.go
├── handler/
│   └── device_update.go                    ← Renamed
├── api/
│   └── types/
│       └── device_update.go                ← Renamed (or keep bundle.go)
```

#### 4.2 Interface Rename

```go
// internal/fusion/device_update.go
package fusion

type DeviceUpdate interface {
    NotifyBundleUpload(...)
    ListBundles(...)
    ApproveBundle(...)
    CheckForUpdate(...)
    GetBundleDownloadURL(...)
    LogBundleUpdateStatus(...)
}
```

#### 4.3 Handler Rename

```go
// internal/handler/device_update.go
package handler

type DeviceUpdateHandler struct {
    updateService fusion.DeviceUpdate
}

func NewDeviceUpdateHandler(updateService fusion.DeviceUpdate) *DeviceUpdateHandler {
    return &DeviceUpdateHandler{
        updateService: updateService,
    }
}
```

#### 4.4 Endpoint Constants

```go
// internal/constants/endpoints.go

// ============================================
// CI/CD API Endpoints (Internal/Pipeline Use)
// ============================================
// These endpoints are called by CI/CD pipelines, not client applications.
// Using a separate base path for clear separation and different auth patterns.

EndpointCICD                    = "/cicd"              // Base path for CI/CD APIs
EndpointCICDBundles             = "/bundles"           // POST: Notify bundle upload
EndpointCICDBundleApprove       = "/bundles/:bundleId/approve"  // POST: Approve bundle

// ============================================
// Client API Endpoints (Desktop App Use)
// ============================================
// These endpoints are called by client applications (desktop app).

EndpointDeviceUpdates           = "/device-updates"    // Base path for client APIs
EndpointBundles                 = "/bundles"           // GET: List bundles
EndpointBundleDownload          = "/bundles/:bundleId/download"  // GET: Download
EndpointUpdateCheck             = "/check"             // GET: Check for updates
EndpointUpdateStatus            = "/status"            // POST: Log update status
```

**Resulting API paths:**

**CI/CD Pipeline APIs** (called by build/release pipelines):
```
POST   /api/v1/cicd/bundles                       → Notify bundle upload (CI/CD)
POST   /api/v1/cicd/bundles/:bundleId/approve     → Approve bundle (Release Manager)
```

**Client APIs** (called by desktop application):
```
GET    /api/v1/device-updates/bundles             → List bundles (Admin UI)
GET    /api/v1/device-updates/check               → Check for updates
GET    /api/v1/device-updates/bundles/:bundleId/download → Download bundle
POST   /api/v1/device-updates/status              → Log update status
```

**Benefits of Separation:**
- CI/CD APIs can use service account / API key authentication
- Client APIs use user authentication (Auth0)
- Different rate limiting policies per API category
- Clearer audit trails for pipeline vs user actions
- Easier to apply different security policies

#### 4.5 Permission Constants

```go
// internal/middleware/permissions.go
const (
    // CI/CD permissions (for pipelines and release managers)
    CICDBundleCreate    = "cicd.bundle.create"     // Upload bundle notification
    CICDBundleApprove   = "cicd.bundle.approve"    // Approve bundle for release

    // Device Update permissions (for client applications)
    DeviceUpdateBundleRead  = "device-update.bundle.read"   // List bundles
    DeviceUpdateCheck       = "device-update.check"         // Check for updates
    DeviceUpdateDownload    = "device-update.download"      // Download bundle
    DeviceUpdateStatusLog   = "device-update.status.log"    // Log update status
)
```

**Separation Benefits:**
- CI/CD permissions can be assigned to service accounts
- Device update permissions assigned to application roles
- Clear audit trail for who did what

#### 4.6 S3 Bucket & Config

```go
// internal/config/s3.go
type S3Config struct {
    // ... other buckets
    DeviceUpdateBucket string  // Renamed from FirmwareUpdateBucket
}

// environment/constants.go
DeviceUpdateBucket: "S3_DEVICE_UPDATE_BUCKET"  // Renamed
```

---

## Part 5: Alternative Naming Options

### Option 1: "Device Updates" (Recommended)

```
/api/v1/device-updates/bundles
/api/v1/device-updates/updates/check
```

**Pros:** 
- Clear that it's for device (not desktop app) updates
- Accommodates firmware + software in one term
- Future-proof: distinguishes from application updates

**Cons:**
- Longer path

### Option 2: "OTA Updates" (Over-The-Air)

```
/api/v1/ota/bundles
/api/v1/ota/updates/check
```

**Pros:**
- Industry-standard term
- Short and memorable

**Cons:**
- Not all updates may be OTA (some could be USB-based)

### Option 3: "Updates" (Generic)

```
/api/v1/updates/bundles
/api/v1/updates/check
```

**Pros:**
- Very generic, accommodates all update types
- Short path

**Cons:**
- May conflict with future desktop application updates
- Less descriptive

### Option 4: Keep "Firmware" But Redefine Semantically

Document that "firmware" in this context means "device system software bundle" including:
- Low-level firmware
- Device services/software
- Configuration updates

**Pros:**
- No code changes needed
- Just documentation update

**Cons:**
- Semantic confusion persists
- Not accurate to industry terminology

---

## Part 6: Issues Found in Code

### 6.1 Copy-Paste Error

```go
// internal/handler/firmware.go:21
// NewUserHandler creates a new user handler with the provided user service.
func NewFirmwareUpdateHandler(firmware fusion.Firmware) *FirmwareUpdateHandler {
```

**Fix:** Update comment to match function name.

### 6.2 Duplicate/Unused Constants

```go
// internal/constants/endpoints.go
EndpointFirmwareBundles = "/bundles"
EndpointFirmwareList    = "/bundles"  // Duplicate!
```

**Fix:** Remove one of these constants.

### 6.3 Inconsistent Parameter Naming

```go
EndpointApproveBundle  = "/bundles/:bundleID/approve"   // bundleID (uppercase)
EndpointBundleDownload = "/bundles/:bundleId/download"  // bundleId (lowercase)
```

**Fix:** Standardize to either `bundleId` or `bundleID` (Go convention is `bundleID`).

### 6.4 Deprecated Types Not Removed

```go
// internal/api/types/firmware.go
// FirmwareRelease represents a firmware release with its associated artifacts.
// Deprecated: use Bundle instead
type FirmwareRelease struct { ... }

type FirmwareReleaseDetails struct { ... }
type FirmwareReleaseListResponse struct { ... }
```

**Fix:** Remove deprecated types if they're not in use.

### 6.5 Unused Types

```go
type DeviceUpdateCheckPayload struct { ... }
type CheckUpdateRequest struct { ... }  // Different from CheckForUpdateRequest
type DeviceUpdateResult struct { ... }
type CheckUpdateResponse struct { ... }
type DeployReleasePayload struct { ... }
```

**Fix:** Review and remove if not used, or document their purpose.

---

## Part 7: Recommended Immediate Actions

### Priority 1 (Quick Fixes) - Do Now

| # | Action | File | Impact |
|---|--------|------|--------|
| 1 | Fix comment copy-paste error | `handler/firmware.go:21` | None |
| 2 | Remove duplicate constant | `constants/endpoints.go` | None |
| 3 | Standardize param naming (bundleId vs bundleID) | `constants/endpoints.go` | Low |
| 4 | Remove deprecated/unused types | `types/firmware.go` | Low |

### Priority 2 (CI/CD Separation) - This Sprint

| # | Action | Notes |
|---|--------|-------|
| 1 | Create `/cicd` base path for pipeline APIs | Separate from client APIs |
| 2 | Move `NotifyBundleUpload` to `/cicd/bundles` | CI/CD only endpoint |
| 3 | Move `ApproveBundle` to `/cicd/bundles/:bundleId/approve` | Release manager endpoint |
| 4 | Add CI/CD specific Swagger tag | "CI/CD API" |
| 5 | Document authentication pattern for CI/CD APIs | API key / service account |

### Priority 3 (Documentation) - This Sprint

| # | Action | Notes |
|---|--------|-------|
| 1 | Document that "firmware" = device update bundle | Add to README |
| 2 | Add Swagger description explaining bundle contents | Update handler annotations |
| 3 | Create API versioning strategy for future rename | Plan for v2 API |

### Priority 4 (Strategic Refactoring) - Next Quarter

| # | Action | Breaking Change? |
|---|--------|-----------------|
| 1 | Rename `/firmware` → `/device-updates` (client APIs) | Yes (API v2) |
| 2 | Rename interface `Firmware` → `DeviceUpdate` | No (internal) |
| 3 | Rename handler `FirmwareUpdateHandler` → `DeviceUpdateHandler` | No (internal) |
| 4 | Rename permissions `firmware.*` → `device-update.*` | Yes (DB migration) |
| 5 | Rename S3 bucket config key | Yes (env var change) |

---

## Part 8: Future-Proofing for Application Updates

**Important:** Application updates are a **completely separate module** from device updates. They will NOT share:
- The same bundle table
- The same API endpoints
- The same service/handler code

### Recommended Separate Module Structure

Device updates and application updates should be treated as two independent systems:

```
┌─────────────────────────────────────────────────────────────────┐
│                      UPDATE SYSTEMS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────┐   ┌─────────────────────────────┐  │
│  │   DEVICE UPDATES        │   │   APPLICATION UPDATES       │  │
│  │   (This Module)         │   │   (Future Separate Module)  │  │
│  ├─────────────────────────┤   ├─────────────────────────────┤  │
│  │ • /device-updates/*     │   │ • /app-updates/*            │  │
│  │ • /cicd/bundles/*       │   │ • /cicd/releases/*          │  │
│  │ • bundle table          │   │ • app_release table         │  │
│  │ • DeviceUpdateService   │   │ • AppUpdateService          │  │
│  └─────────────────────────┘   └─────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Recommended API Structure

**Device Updates (Current Module):**
```
CI/CD:   /api/v1/cicd/bundles/*
Client:  /api/v1/device-updates/*
```

**Application Updates (Future Module):**
```
CI/CD:   /api/v1/cicd/releases/*
Client:  /api/v1/app-updates/*
```

### Database Schema (Keep Separate)

Do NOT add `bundle_type` to the existing `bundle` table. Instead, create a separate table for application updates when that module is built:

```sql
-- Device updates (existing)
CREATE TABLE bundle (...);
CREATE TABLE bundle_update_status (...);

-- Application updates (future - separate tables)
CREATE TABLE app_release (...);
CREATE TABLE app_update_status (...);
```

### Code Structure (Keep Separate)

```
internal/
├── fusion/
│   ├── deviceupdate/          ← Device update module (current)
│   │   ├── service.go
│   │   ├── device_update.go
│   │   └── db/
│   │       └── service.go
│   │
│   └── appupdate/             ← Application update module (future)
│       ├── service.go
│       ├── app_update.go
│       └── db/
│           └── service.go
├── handler/
│   ├── device_update.go       ← Device update handlers
│   └── app_update.go          ← Application update handlers (future)
```

---

## Summary Recommendations

| Category | Current | Recommended | Priority |
|----------|---------|-------------|----------|
| CI/CD API Path | `/firmware/bundles` (POST) | `/cicd/bundles` | P2 |
| Client API Path | `/firmware/*` | `/device-updates/*` | P3 |
| Interface | `Firmware` | `DeviceUpdate` | P3 |
| Handler | `FirmwareUpdateHandler` | `DeviceUpdateHandler` | P3 |
| Types | Keep as `Bundle*` | ✅ Already good | - |
| Tables | `bundle`, `bundle_update_status` | ✅ Already good (dedicated to device updates) | - |
| S3 Config | `FirmwareUpdateBucket` | `DeviceUpdateBucket` | P3 |
| Permissions | `firmware.*` | `device-update.*` | P3 |
| Deprecated Types | Present | Remove | P1 |
| Duplicate Constants | Present | Remove | P1 |

---

## Appendix: Migration Checklist

When ready to rename (recommended for API v2):

### Phase 1: CI/CD API Separation
- [ ] Add new CI/CD base path constant (`EndpointCICD = "/cicd"`)
- [ ] Move `NotifyBundleUpload` to `/cicd/bundles` (POST)
- [ ] Move `ApproveBundle` to `/cicd/bundles/:bundleId/approve` (POST)
- [ ] Add CI/CD specific authentication (API key / service account)
- [ ] Update CI/CD pipeline scripts to use new endpoints
- [ ] Add Swagger tag "CI/CD API" for pipeline endpoints

### Phase 2: Client API Rename
- [ ] Update `constants/endpoints.go` - change base path to `/device-updates`
- [ ] Update `middleware/permissions.go` - rename permission constants
- [ ] Update permission setup function name
- [ ] Run database migration to update `feature` table with new names
- [ ] Update `config/s3.go` - rename config field
- [ ] Update `environment/constants.go` - rename env var key

### Phase 3: Internal Code Rename
- [ ] Rename files:
  - [ ] `internal/fusion/firmware.go` → `device_update.go`
  - [ ] `internal/fusion/firmware/` → `internal/fusion/deviceupdate/`
  - [ ] `internal/handler/firmware.go` → `device_update.go`
  - [ ] `internal/api/types/firmware.go` → `device_update.go` (or `bundle.go`)
- [ ] Update all import statements
- [ ] Update Swagger tags and descriptions
- [ ] Update README documentation

### Phase 4: Documentation & Cleanup
- [ ] Regenerate Swagger docs: `swag init`
- [ ] Update client applications to use new endpoints
- [ ] Add API v1 deprecation notice
- [ ] Update this review document to reflect completed changes

---

*Document generated by code review. For questions, reach out to the engineering team.*
