#pragma once

namespace bosepro {

inline constexpr int kTelemetryProtocolVersion = 1;
inline constexpr int kTelemetrySchemaVersion = 1;

inline bool is_supported_telemetry_version(int requested_version, int current_version)
{
    return (requested_version == current_version) ||
           (requested_version == (current_version - 1));
}

inline bool is_supported_telemetry_protocol_version(int requested_version)
{
    return is_supported_telemetry_version(requested_version, kTelemetryProtocolVersion);
}

inline bool is_supported_telemetry_schema_version(int requested_version)
{
    return is_supported_telemetry_version(requested_version, kTelemetrySchemaVersion);
}

} // namespace bosepro
