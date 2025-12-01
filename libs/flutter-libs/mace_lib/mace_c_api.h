#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Export macro (Windows-focused)
#if defined(_WIN32) || defined(_WIN64)
  #if defined(MACE_C_API_BUILD)
    #define MACE_API __declspec(dllexport)
  #else
    #define MACE_API __declspec(dllimport)
  #endif
#else
  #define MACE_API
#endif

typedef uint64_t EngineHandle;
typedef uint64_t SurfaceHandle;
typedef uint64_t ClusterHandle;
typedef uint64_t FieldPointsHandle;

// String utilities
MACE_API const char* mace_get_lib_version(void);
MACE_API void        mace_free_string(const char* s);

// Debug helpers
MACE_API void        mace_debug_speakers(void);

// Engine lifecycle
MACE_API EngineHandle mace_create_engine(const char* speakerDefsPath);
MACE_API void         mace_destroy_engine(void);
MACE_API void         mace_clear(uint64_t e);

// Geometry / scene setup
MACE_API SurfaceHandle     mace_add_polygon(EngineHandle e,
                                            const double* xyz,
                                            int count);
MACE_API ClusterHandle     mace_add_speaker_cluster(EngineHandle e,
                                                    const char*  speakerName,
                                                    double       x,
                                                    double       y,
                                                    double       z,
                                                    double       gain,
                                                    double       roll,
                                                    double       pitch,
                                                    double       yaw);
MACE_API FieldPointsHandle mace_add_field_points(EngineHandle e,
                                                 const double* xyz,
                                                 int          count);

// Measurement & groups
MACE_API uint64_t mace_create_measurement(int measurementType);
MACE_API uint64_t mace_create_group(void);
MACE_API void     mace_add_to_group(uint64_t groupId,
                                    uint64_t sourceId,
                                    uint64_t fieldPointsId);
MACE_API void     mace_add_groups_to_measurement(uint64_t measurementId,
                                                 uint64_t groupId);

// Calculation
MACE_API void mace_run_calculation(EngineHandle e);

// SPL accessors
MACE_API int mace_get_spl(EngineHandle      e,
                          FieldPointsHandle fph,
                          double*           outLevels,
                          int               freqHz);

MACE_API int mace_get_spl_at(EngineHandle      e,
                             FieldPointsHandle fph,
                             int               bandwidth,
                             double            freqHz,
                             double*           outLevels,
                             double*           actualFreqHz,
                             const char*       weighting);

// Multi-band SPL JSON
MACE_API const char* mace_get_all_spl_json(EngineHandle      e,
                                           FieldPointsHandle fph);

#ifdef __cplusplus
} // extern "C"
#endif
