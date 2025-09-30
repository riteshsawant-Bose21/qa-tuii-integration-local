// mace_c_api.cpp

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <string>
#include <filesystem>

#include "bose/MACE.h"
#include "bose/Polygon.h"
#include "bose/HardwareComponentFactory.h"
#include "bose/FieldPoints.h"
#include "bose/FieldPoint.h"
#include "bose/LoudspeakerCluster.h"
#include "bose/MeasurementTypes.h"
#include "bose/DataSet.h"
#include "bose/Bandwidth.h"
#include "bose/Enum.h"

namespace fs = std::filesystem;

extern "C" {

using namespace bosepro;
using namespace bosepro::hardware;
using namespace bosepro::model;
using namespace bosepro::simulation;
using namespace bosepro::acoustics;
using namespace bosepro::measurement;

using EngineHandle      = uint64_t;
using SurfaceHandle     = uint64_t;
using ClusterHandle     = uint64_t;
using FieldPointsHandle = uint64_t;

const char* mace_get_lib_version()
{
    auto eng = EngineFactory::GetEngine();
    auto ver = eng ? eng->GetLibVersion() : std::string();
    // strdup uses malloc under the hood
    return strdup(ver.c_str());
}

void mace_free_string(const char* s)
{
    if (s) std::free((void*)s);
}

/// Debug: dump what speaker files were loaded
void mace_debug_speakers()
{
    auto &f = HardwareComponentFactory::instance();
    printf("[mace_capi] factory.isInitialized() = %s\n",
           f.isInitialized() ? "true" : "false");
    printf("[mace_capi] factory.getPath()       = \"%s\"\n",
           f.getPath().c_str());

    auto names = f.getLoudspeakerNames();
    if (names.empty())
    {
        printf("[mace_capi] getLoudspeakerNames() => (none)\n");
    }
    else
    {
        for (auto &n : names)
            printf("[mace_capi] Speaker loaded: \"%s\"\n", n.c_str());
    }
    fflush(stdout);
}

/// Create & start engine, using the path provided from Dart
EngineHandle mace_create_engine(const char* speakerDefsPath)
{
    printf("[mace_capi] Enter mace_create_engine\n");
    fflush(stdout);

    printf("[mace_capi] Initializing speaker factory with \"%s\"\n",
           speakerDefsPath);
    fflush(stdout);

    bool ok = HardwareComponentFactory::instance()
                  .initialize(speakerDefsPath);
    printf("[mace_capi] Factory.initialize returned %s\n",
           ok ? "true" : "false");
    fflush(stdout);

    // optional: print out what was loaded
    mace_debug_speakers();

    auto eng = EngineFactory::GetEngine();
    printf("[mace_capi] EngineFactory::GetEngine returned %p\n",
           (void*)eng.get());
    fflush(stdout);

    eng->StartEngine();
    printf("[mace_capi] Engine started\n");
    fflush(stdout);

    return reinterpret_cast<EngineHandle>(eng.get());
}

/// Stop & destroy engine
void mace_destroy_engine()
{
    printf("[mace_capi] Enter mace_destroy_engine\n");
    fflush(stdout);

    auto eng = EngineFactory::GetEngine();
    if (eng) {
        eng->StopEngine();
        printf("[mace_capi] Engine stopped\n");
    }
    EngineFactory::DestroyEngine();
    printf("[mace_capi] Engine destroyed\n");
    fflush(stdout);
}

/// Add a polygon surface
SurfaceHandle mace_add_polygon(
    EngineHandle /*e*/,
    const double* xyz,
    int           count
) {
    printf("[mace_capi] Enter mace_add_polygon (count=%d)\n", count);
    fflush(stdout);

    std::vector<math::Vec3> verts;
    verts.reserve(count);
    for (int i = 0; i < count; ++i) {
        math::Vec3 v(xyz[3*i], xyz[3*i+1], xyz[3*i+2]);
        verts.push_back(v);
        printf("[mace_capi]  vert[%d] = (%.2f, %.2f, %.2f)\n",
               i, v.x, v.y, v.z);
    }
    fflush(stdout);

    auto poly = std::make_shared<model::Polygon>(std::move(verts));
    EngineFactory::GetEngine()->AddSurface(poly);
    SurfaceHandle id = poly->getId();
    printf("[mace_capi] Surface added with id=%llu\n",
           (unsigned long long)id);
    fflush(stdout);

    return id;
}

/// Add a speaker cluster
ClusterHandle mace_add_speaker_cluster(
    EngineHandle /*e*/,
    const char*  speakerName,
    double       x, double y, double z,
    double       gain,
    double roll,
    double pitch,
    double yaw
) {
    printf("[mace_capi] Enter mace_add_speaker_cluster "
           "(name=\"%s\", x=%.2f, y=%.2f, z=%.2f, "
           "gain=%.2f, roll=%.2f, pitch=%.2f, yaw=%.2f)\n",
           speakerName, x, y, z, gain, roll, pitch, yaw);
    fflush(stdout);

    auto spk = HardwareComponentFactory::instance()
                   .getLoudspeaker(speakerName);
    if (!spk) {
        printf("[mace_capi] ERROR: getLoudspeaker(\"%s\") returned nullptr\n",
               speakerName);
        fflush(stdout);
    }

    auto cluster = model::LoudspeakerCluster::create();
    printf("[mace_capi] Created LoudspeakerCluster %p\n",
           (void*)cluster.get());
    fflush(stdout);

    cluster->addComponent(spk);
    cluster->setLocation({x, y, z});
    cluster->setOrientation({roll, pitch, yaw});
    // cluster->setMaxGain();
    cluster->setGain(gain);
    EngineFactory::GetEngine()->AddCluster(cluster);

    ClusterHandle id = cluster->getId();
    printf("[mace_capi] Cluster added with id=%llu\n",
           (unsigned long long)id);
    fflush(stdout);

    return id;
}

/// Add field points
FieldPointsHandle mace_add_field_points(
    EngineHandle    /*e*/,
    const double*   xyz,
    int             count
) {
    printf("[mace_capi] Enter mace_add_field_points (count=%d)\n", count);
    fflush(stdout);

    simulation::FieldPoints pts;
    for (int i = 0; i < count; ++i) {
        simulation::FieldPoint fp{xyz[3*i], xyz[3*i+1], xyz[3*i+2]};
        pts.emplace_back(fp);
        printf("[mace_capi]  point[%d] = (%.2f, %.2f, %.2f)\n",
               i, fp.x, fp.y, fp.z);
    }
    fflush(stdout);

    pts.setHitTestMode(enumToUnderlying(
        simulation::HitTestMode::ClusterMid));
    printf("[mace_capi] HitTestMode set to ClusterMid\n");
    fflush(stdout);

    auto fpPtr = std::make_shared<simulation::FieldPoints>(pts);
    EngineFactory::GetEngine()->AddFieldPoints(fpPtr->getId(), fpPtr);

    FieldPointsHandle id = fpPtr->getId();
    printf("[mace_capi] FieldPoints added with id=%llu\n",
           (unsigned long long)id);
    fflush(stdout);

    return id;
}

/// Create a Measurement
uint64_t mace_create_measurement(int measurementType)
{
    printf("[mace_capi] Enter mace_create_measurement (type=%d)\n",
           measurementType);
    fflush(stdout);

    auto id = EngineFactory::GetEngine()
                  ->CreateMeasurement(static_cast<MeasurementType>(measurementType));
    printf("[mace_capi] Measurement created id=%llu\n",
           (unsigned long long)id);
    fflush(stdout);
    return id;
}

/// Create a Group
uint64_t mace_create_group()
{
    printf("[mace_capi] Enter mace_create_group\n");
    fflush(stdout);

    auto id = EngineFactory::GetEngine()->CreateGroup();
    printf("[mace_capi] Group created id=%llu\n",
           (unsigned long long)id);
    fflush(stdout);
    return id;
}

/// Add to Group
void mace_add_to_group(uint64_t groupId,
                       uint64_t sourceId,
                       uint64_t fieldPointsId)
{
    printf("[mace_capi] mace_add_to_group (group=%llu, src=%llu, fph=%llu)\n",
           (unsigned long long)groupId,
           (unsigned long long)sourceId,
           (unsigned long long)fieldPointsId);
    fflush(stdout);

    EngineFactory::GetEngine()->AddToGroup(
        groupId, Uid::Ids{sourceId, fieldPointsId});
}

/// Add Groups to Measurement
void mace_add_groups_to_measurement(uint64_t measurementId,
                                    uint64_t groupId)
{
    printf("[mace_capi] mace_add_groups_to_measurement "
           "(meas=%llu, group=%llu)\n",
           (unsigned long long)measurementId,
           (unsigned long long)groupId);
    fflush(stdout);

    EngineFactory::GetEngine()->AddGroupsToMeasurement(
        measurementId, Uid::Ids{groupId});
}

/// Run the calculation
void mace_run_calculation(EngineHandle /*e*/)
{
    printf("[mace_capi] Enter mace_run_calculation\n");
    fflush(stdout);

    EngineFactory::GetEngine()->Calculate(true);

    printf("[mace_capi] Calculation complete\n");
    fflush(stdout);
}

/// Get SPL results
int mace_get_spl(
    EngineHandle      /*e*/,
    FieldPointsHandle fph,
    double*           outLevels,
    int               freqHz
) {
    printf("[mace_capi] Enter mace_get_spl (fph=%llu, freqHz=%d)\n",
           (unsigned long long)fph, freqHz);
    fflush(stdout);

    auto data = EngineFactory::GetEngine()->GetData(fph);
    if (!data) {
        printf("[mace_capi] ERROR: GetData(%llu) returned nullptr\n",
               (unsigned long long)fph);
        fflush(stdout);
        return 0;
    }

    PairedData dBs;
    Freqs freqs{ static_cast<double>(freqHz) };
    data->getData()->GetSPL(dBs, Bandwidth::Third, freqs);

    int n = static_cast<int>(dBs.size());
    printf("[mace_capi] Retrieved %d SPL entries\n", n);
    fflush(stdout);

    for (int i = 0; i < n; ++i) {
        double lvl = dBs[i].second.empty() ? 0.0 : dBs[i].second[0];
        outLevels[i] = lvl;
        printf("[mace_capi]  outLevels[%d] = %.2f\n", i, lvl);
    }
    fflush(stdout);

    return n;
}

/// Computes SPL for all default ISO center frequencies across:
/// - oneThirdOctave (Bandwidth::Third)
/// - oneOctave      (Bandwidth::Octave)
/// - vocalBands     (Bandwidth::VocalBands)
/// - broadband      (Bandwidth::Broadband)
///
/// Returns: JSON string
///
/// JSON:
/// {
///   "frequencies":[100,125,...,10000],
///   "bandwidths":["oneThirdOctave","oneOctave","vocalBands","broadband"],
///   "points": N,
///   "spl": {
///     "oneThirdOctave": [[p0f0, p0f1, ...], [p1f0, ...], ...],
///     "oneOctave":      [[...], ...],
///     "vocalBands":     [vb0, vb1, ...],   // one value per point
///     "broadband":      [bb0, bb1, ...]
///   }
/// }
const char* mace_get_all_spl_json(
    EngineHandle      /*e*/,
    FieldPointsHandle fph
) {
    printf("[mace_capi] Enter mace_get_spl_multi_json (fph=%llu)\n",
           (unsigned long long)fph);
    fflush(stdout);

    auto data = EngineFactory::GetEngine()->GetData(fph);
    if (!data) {
        printf("[mace_capi] ERROR: GetData(%llu) returned nullptr\n",
               (unsigned long long)fph);
        fflush(stdout);
        return strdup("{}");
    }

    // Default ISO centers (Hz)
    static const double kFreqs[] = {
        100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
        1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000
    };
    static const int kNFreqs = (int)(sizeof(kFreqs) / sizeof(kFreqs[0]));

    // Prepare frequency vector (non-broadband/vocal queries)
    Freqs freqs;
    freqs.reserve(kNFreqs);
    for (int i = 0; i < kNFreqs; ++i) freqs.emplace_back(kFreqs[i]);

    // Fetch SPL for required bandwidths
    PairedData d_third, d_oct, d_bb, d_vb;
    data->getData()->GetSPL(d_third, acoustics::Bandwidth::Third,     freqs);
    data->getData()->GetSPL(d_oct,   acoustics::Bandwidth::Octave,    freqs);
    { Freqs empty; data->getData()->GetSPL(d_bb, acoustics::Bandwidth::Broadband, empty); }
    { Freqs empty; data->getData()->GetSPL(d_vb, acoustics::Bandwidth::VocalBands, empty); }

    // Point count (prefer broadband if present)
    const int nPoints =
        !d_bb.empty()   ? (int)d_bb.size() :
        !d_vb.empty()   ? (int)d_vb.size() :
        !d_third.empty()? (int)d_third.size() :
        !d_oct.empty()  ? (int)d_oct.size() : 0;

    printf("[mace_capi] SPL all-bw: points=%d, freqs=%d\n", nPoints, kNFreqs);
    fflush(stdout);

    // ---- Build JSON ----
    std::string json;
    json.reserve(64u * (size_t)std::max(1, nPoints) * 4u);

    json += "{";

    // frequencies
    json += "\"frequencies\":[";
    for (int i = 0; i < kNFreqs; ++i) {
        if (i) json += ",";
        if (kFreqs[i] == (int)kFreqs[i]) json += std::to_string((int)kFreqs[i]);
        else                              json += std::to_string(kFreqs[i]);
    }
    json += "],";

    // bandwidths
    json += "\"bandwidths\":[\"oneThirdOctave\",\"oneOctave\",\"vocalBands\",\"broadband\"],";

    // points
    json += "\"points\":";
    json += std::to_string(nPoints);
    json += ",";

    // spl object
    json += "\"spl\":{";

    // Helper: append 2D matrix [points][freqs] from PairedData
    auto appendMatrixFromPaired = [&](const PairedData& d, const char* key) {
        json += "\""; json += key; json += "\":[";
        for (int p = 0; p < nPoints; ++p) {
            if (p) json += ",";
            json += "[";
            const auto& row = (p < (int)d.size()) ? d[p].second : std::vector<double>{};
            for (int f = 0; f < kNFreqs; ++f) {
                if (f) json += ",";
                double v = (f < (int)row.size()) ? row[f] : 0.0;
                json += std::to_string(v);
            }
            json += "]";
        }
        json += "]";
    };

    // oneThirdOctave
    appendMatrixFromPaired(d_third, "oneThirdOctave");
    json += ",";

    // oneOctave
    appendMatrixFromPaired(d_oct, "oneOctave");
    json += ",";

    // vocalBands: flat array [points]
    json += "\"vocalBands\":[";
    for (int p = 0; p < nPoints; ++p) {
        if (p) json += ",";
        double v = (p < (int)d_vb.size() && !d_vb[p].second.empty()) ? d_vb[p].second[0] : 0.0;
        json += std::to_string(v);
    }
    json += "],";

    // broadband: flat array [points]
    json += "\"broadband\":[";
    for (int p = 0; p < nPoints; ++p) {
        if (p) json += ",";
        double v = (p < (int)d_bb.size() && !d_bb[p].second.empty()) ? d_bb[p].second[0] : 0.0;
        json += std::to_string(v);
    }
    json += "]";

    json += "}"; // spl
    json += "}"; // root

    // malloc-dup for caller
    char* out = (char*)std::malloc(json.size() + 1);
    if (!out) {
        printf("[mace_capi] ERROR: malloc failed for JSON out\n");
        fflush(stdout);
        return strdup("{}");
    }
    std::memcpy(out, json.c_str(), json.size());
    out[json.size()] = '\0';
    return out;
}


/// Clear all engine state (surfaces, clusters, measurements, etc.)
void mace_clear(uint64_t /*e*/)
{
    printf("[mace_capi] Enter mace_clear\n");
    fflush(stdout);

    auto eng = EngineFactory::GetEngine();
    if (eng) {
        eng->Clear();
        printf("[mace_capi] Engine cleared\n");
    } else {
        printf("[mace_capi] WARNING: Clear() but engine==nullptr\n");
    }
    fflush(stdout);
}

} // extern "C"
