# Fusion Server API Policy

This document defines the intended boundary between dedicated public API
surfaces in `fusion-server` and the internal replicated state model.

## Purpose

`fusion-server` now exposes several kinds of APIs:

- generic replicated configuration/state
- domain-specific resources with lifecycle and behavior
- operational and control-plane endpoints

The goal of this policy is to keep those responsibilities from collapsing into a
single ambiguous API model.

## Core Principle

Use dedicated public endpoints for owned resources and configuration domains.

Do not expose the internal replicated state tree as the public API model.

Use dedicated endpoints for resources that have behavior, lifecycle, side
effects, operational semantics, or workflow-specific commands.

## Current Contract State

The current public contract is intentionally split by concern:

- `/device`
  Typed provisioning/import contract for the DSP deployment package.
- `/settings/audio/...`
  Runtime-oriented settings mutation and read surface.
- `/tasks`
  Typed task management contract.
- `/snapshots`
  Typed metadata and operation contract, with raw snapshot bodies still exposed
  at `GET /snapshots/{name}`.
- `/devices` and private `/device`
  Typed device metadata and patch surfaces.

This is the intended direction for the product. The internal state tree remains
an implementation detail.

## Allowed In Internal State

Internal replicated state may still contain declarative configuration sections
such as:

- `settings`
- `audio_streams`
- `devices`
- typed provisioning artifacts such as `dro_conditioned_output` and
  `fusion_connect_additions`

Those sections may be persisted and replicated, but that does not make them the
public API.

## Not Allowed As Public Tree Mutation

Data or resources should not be exposed as generic public tree mutation when any
of the following are true:

- The resource has its own lifecycle.
- The resource supports commands such as enable, disable, activate, trigger, reload, or reset.
- The server must maintain execution history or runtime state for the resource.
- The server must coordinate side effects beyond simple config reconciliation.
- The resource has behavior-oriented semantics rather than declarative state.
- The resource is operational, infrastructural, or device-control oriented.
- The resource needs domain-specific API affordances that do not fit generic tree mutation.

When these conditions apply, the resource must use a dedicated endpoint.

## Must Be Dedicated Endpoints

The following API groups should remain dedicated endpoints and should not be
folded into a generic config/document mutation surface:

- `/tasks`
  Tasks have lifecycle, enable/disable semantics, history, scheduler coupling,
  and execution behavior.
- `/snapshots`
  Snapshots support create, update, activate, and delete workflows.
- `/pava`
  PAVA resources are domain-specific and behavior-oriented.
- `/cluster`
  Cluster APIs are control-plane operations.
- `/devices` and `/device`
  Device management, provisioning, certificates, VIP updates, and operational
  metadata do not belong in a generic config tree API.
- `/controllers`
  Controller operations are device/control-plane behavior.
- `/health`, `/metrics`, `/metadata`, `/version`, `/sessions`, `/ws`
  These are introspection, runtime, or transport concerns.

## Internal State Ownership Rules

Each top-level internal state section should have an explicit owner.

An owner is responsible for:

- schema or structural validation
- normalization rules
- reconciliation behavior
- compatibility rules for that subtree

Top-level internal sections should not be treated as unowned arbitrary blobs
once the server is expected to understand and act on them.

## `/device` Policy

`/device` is now the canonical public bulk provisioning/import contract.

It should:

- accept a typed deployment package
- represent conditioned DRO output plus Fusion Connect additions
- map into existing internal sections without creating a second public config
  tree API
- be treated as authoritative provisioning input, not generic live tree
  mutation

## Tasks Policy

`/tasks` should remain the canonical API for task management.

Reasons:

- tasks are not just data; they are executable domain resources
- tasks have lifecycle operations
- tasks have history and runtime effects
- tasks require scheduler-specific validation and behavior

If task-related configuration needs to be persisted in replicated state, that
should be an implementation detail behind the `/tasks` API, not a second public
ownership model exposed through a generic config tree.

`/tasks` now uses protobuf-backed JSON request and response types.

## Snapshots Policy

`/snapshots` should remain the canonical API for snapshot lifecycle.

Current contract direction:

- snapshot metadata and operation endpoints are typed
- `GET /snapshots`
  returns typed metadata
- `GET /snapshots/meta/active`
  returns typed metadata
- create, activate, delete, and save operations return typed status payloads
- `GET /snapshots/{name}` still returns the raw stored snapshot payload

That split is intentional. Full snapshot bodies should only be typed if the
stored snapshot/state model is deliberately formalized.

## Devices Policy

`/devices` and the private-local `/device` metadata endpoints should remain the
canonical surface for device metadata and patching.

These endpoints now use typed request/response models and should not drift back
to ad hoc JSON maps.

## Settings Policy

`/settings/audio/...` is the canonical runtime settings API.

It remains intentionally separate from the bulk `/device` provisioning package:

- `/device`
  bulk authoritative provisioning/import
- `/settings/audio/...`
  runtime parameter reads and mutations

`/settings/audio/...` is still JSON-patch-oriented and is not protobuf-backed at
this time. That is acceptable because it is a runtime patch surface rather than
a bulk deployment contract.

## Legacy `/value` Direction

Public `/value` has been removed.

That remains the correct policy direction. The server may still keep internal
replicated state sections that originated in the old `/value` world, but that
state is not the public API model anymore.

## Why `/settings` Instead Of Generic Config Mutation

- it matches the actual launcher usage pattern
- it makes settings ownership explicit
- it removes arbitrary path-based tree mutation from the public API
- it allows parameter-specific validation and normalization
- it is a cleaner long-term public contract than exposing internal state paths

## Scope Rules For `/settings`

Data under `/settings` should still follow ownership rules.

- `/settings/audio/...`
  Owned by the audio/settings domain
- additional settings namespaces may be added only when they are still
  configuration-oriented and do not require separate resource lifecycle APIs

If a resource has commands, lifecycle, history, or runtime workflow semantics,
it should not be added under `/settings`. It should get its own dedicated API.

## Anti-Pattern To Avoid

Do not replace removed generic tree mutation with equivalent generic mutation
under a new name.

Examples to avoid:

- `PATCH /settings?key=...`
- `PATCH /config?path=...`
- generic subtree mutation that preserves the same arbitrary tree semantics

The replacement should be an owned, domain-shaped API, not the same mechanism
with different routing.

## Decision Rule For New APIs

When introducing a new resource, ask:

1. Is this primarily declarative configuration?
2. Is generic persistence/replication the main requirement?
3. Can the server treat changes as deterministic reconciliation of owned state?
4. Does the resource avoid dedicated commands, lifecycle, and history?

If the answer is yes to all or nearly all of the above, the resource may fit as
an internal owned state section and may be exposed through a dedicated
configuration API.

If not, it should get a dedicated endpoint.

## Summary

- internal state is the configuration substrate.
- dedicated endpoints own public resources and configuration domains.
- `/device` is the typed provisioning/import contract.
- `/tasks` is the typed task management contract.
- `/snapshots` metadata and operations are typed, while raw snapshot bodies
  remain untyped for now.
- `/devices` uses typed metadata contracts.
- `/settings/audio` remains the runtime patch surface.
- control-plane and operational APIs remain separate.
- `tasks` should stay under `/tasks`, not become a first-class generic config
  subtree for public mutation.
