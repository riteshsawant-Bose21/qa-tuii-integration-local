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
#include "bose/OctaveBandFrequencies.h"
#include "bose/DataSet.h"

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


extern "C" int mace_get_spl_at(EngineHandle /*e*/,
                               FieldPointsHandle fph,
                               int bandwidth,
                               double freqHz,
                               double* outLevels,
                               double* actualFreqHz)
{

    if (actualFreqHz) *actualFreqHz = 0.0;
    if (!outLevels) return 0;

    auto data = EngineFactory::GetEngine()->GetData(fph);
    if (!data) return 0;

    const Bandwidth bw = static_cast<Bandwidth>(bandwidth);

    auto writeScalar = [&](const PairedData& d)->int {
        const int n = (int)d.size();
        for (int i=0; i<n; ++i) {
            outLevels[i] = d[i].second.empty() ? 0.0 : d[i].second[0];
        }
        return n;
    };

    PairedData pd;

    // Band sums (ignore freq)
    if (bw == Bandwidth::Broadband || bw == Bandwidth::VocalBands) {
        Freqs empty;
        data->getData()->GetSPL(pd, bw, empty);
        return writeScalar(pd);
    }

    // Fractional-octave path
    // 1) Try single-frequency (fast)
    if (freqHz > 0.0) {
        Freqs one{freqHz};
        data->getData()->GetSPL(pd, bw, one);
        if (!pd.empty() && !pd[0].second.empty()) {
            if (actualFreqHz) *actualFreqHz = freqHz;
            const int n = (int)pd.size();
            for (int i=0; i<n; ++i) outLevels[i] = pd[i].second[0];
            return n;
        }
    }

    // 2) Fallback: ISO centers, pick nearest
    Freqs freqs;
    auto push = [&](double f){ freqs.push_back(f); };

    if (bw == Bandwidth::Octave) {
        const double iso[] = {31.5,63,125,250,500,1000,2000,4000,8000,16000};
        for (double f : iso) push(f);
    } else { // Third or other fractional
        const double iso[] = {
                31.5,40,50,63,80,100,125,160,200,250,315,400,500,630,800,
                1000,1250,1600,2000,2500,3150,4000,5000,6300,8000,10000,12500,16000
        };
        for (double f : iso) push(f);
    }

    data->getData()->GetSPL(pd, bw, freqs);
    if (pd.empty() || pd[0].second.empty()) return 0;

    int bestIdx = 0;
    if (freqHz > 0.0) {
        double bestErr = std::abs(freqs[0] - freqHz);
        for (int i=1; i<(int)freqs.size(); ++i) {
            const double err = std::abs(freqs[i] - freqHz);
            if (err < bestErr) { bestErr = err; bestIdx = i; }
        }
    }
    if (actualFreqHz) *actualFreqHz = freqs[bestIdx];

    const int nPoints = (int)pd.size();
    for (int p=0; p<nPoints; ++p) {
        const auto& row = pd[p].second;
        outLevels[p] = (bestIdx < (int)row.size()) ? row[bestIdx] : 0.0;
    }
    return nPoints;
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
const char* mace_get_all_spl_json(EngineHandle /*e*/, FieldPointsHandle fph)
{
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

    // ---- Ask engine for native bins (preferred) ----
    Freqs thirdFreqs, octaveFreqs;

    // Best case: the SDK exposes available-frequency queries:
    // bool okThird  = data->getData()->GetAvailableFrequencies(acoustics::Bandwidth::Third,  thirdFreqs);
    // bool okOctave = data->getData()->GetAvailableFrequencies(acoustics::Bandwidth::Octave, octaveFreqs);

    // Portable fallback: call GetSPL with EMPTY Freqs to get native bin lengths,
    // then re-query with the engine's own freq vectors if you can obtain them.
    PairedData d_third, d_oct, d_bb, d_vb;

    { Freqs empty; data->getData()->GetSPL(d_third, acoustics::Bandwidth::Third,  empty); }
    { Freqs empty; data->getData()->GetSPL(d_oct,   acoustics::Bandwidth::Octave, empty); }
    { Freqs empty; data->getData()->GetSPL(d_bb,    acoustics::Bandwidth::Broadband, empty); }
    { Freqs empty; data->getData()->GetSPL(d_vb,    acoustics::Bandwidth::VocalBands, empty); }

    const int nPoints =
            !d_bb.empty()    ? (int)d_bb.size() :
            !d_vb.empty()    ? (int)d_vb.size() :
            !d_third.empty() ? (int)d_third.size() :
            !d_oct.empty()   ? (int)d_oct.size() : 0;

    // Infer native band counts from returned rows (safe even if some bands are missing)
    const int nThird  = (!d_third.empty() && !d_third[0].second.empty()) ? (int)d_third[0].second.size() : 0;
    const int nOctave = (!d_oct.empty()   && !d_oct[0].second.empty())   ? (int)d_oct[0].second.size()   : 0;

    printf("[mace_capi] points=%d, thirdBins=%d, octaveBins=%d\n", nPoints, nThird, nOctave);
    fflush(stdout);

    // If the SDK cannot return the actual frequency values, we still serialize matrices
    // correctly and omit/approximate the "frequencies" list per band.
    auto freqsToJson = [](const Freqs& f)->std::string {
        std::string s;
        s.reserve(f.size()*6);
        s += "[";
        for (size_t i=0;i<f.size();++i) {
            if (i) s += ",";
            double v = f[i];
            if ((double)(int)v == v) s += std::to_string((int)v);
            else                     s += std::to_string(v);
        }
        s += "]";
        return s;
    };

    // Try to populate thirdFreqs/octaveFreqs via an API if available.
    // If not available, we will skip "frequencies" or place placeholders.
    // --- BEGIN optional placeholder block ---
    if (thirdFreqs.empty() && nThird > 0) {
        // As a last resort, leave it empty; Dart should not rely on 'frequencies'
        // for band selection unless available. (We’ll still ship matrices.)
        // Alternatively, you can synthesize ISO centers of length nThird if you KNOW they match.
    }
    if (octaveFreqs.empty() && nOctave > 0) {
        // Same note as above.
    }
    // --- END optional placeholder block ---

    // ---- Build JSON ----
    std::string json;
    json.reserve(64u * (size_t)std::max(1, nPoints) * 4u);
    json += "{";

    // For backward compat, we keep a top-level "frequencies" but prefer third if present,
    // else octave; otherwise an empty array.
    json += "\"frequencies\":";
    if (!thirdFreqs.empty()) json += freqsToJson(thirdFreqs);
    else if (!octaveFreqs.empty()) json += freqsToJson(octaveFreqs);
    else json += "[]";
    json += ",";

    json += "\"bandwidths\":[\"oneThirdOctave\",\"oneOctave\",\"vocalBands\",\"broadband\"],";

    json += "\"points\":";
    json += std::to_string(nPoints);
    json += ",";

    json += "\"spl\":{";

    auto appendMatrix = [&](const PairedData& d, const char* key, int nCols) {
        json += "\""; json += key; json += "\":[";
        for (int p = 0; p < nPoints; ++p) {
            if (p) json += ",";
            json += "[";
            const auto& row = (p < (int)d.size()) ? d[p].second : std::vector<double>{};
            for (int f = 0; f < nCols; ++f) {
                if (f) json += ",";
                double v = (f < (int)row.size()) ? row[f] : 0.0;
                json += std::to_string(v);
            }
            json += "]";
        }
        json += "]";
    };

    // One-third octave (points x nThird)
    appendMatrix(d_third, "oneThirdOctave", nThird);
    json += ",";

    // One-octave (points x nOctave)
    appendMatrix(d_oct, "oneOctave", nOctave);
    json += ",";

    // Vocal bands (points)
    json += "\"vocalBands\":[";
    for (int p = 0; p < nPoints; ++p) {
        if (p) json += ",";
        double v = (p < (int)d_vb.size() && !d_vb[p].second.empty()) ? d_vb[p].second[0] : 0.0;
        json += std::to_string(v);
    }
    json += "],";

    // Broadband (points)
    json += "\"broadband\":[";
    for (int p = 0; p < nPoints; ++p) {
        if (p) json += ",";
        double v = (p < (int)d_bb.size() && !d_bb[p].second.empty()) ? d_bb[p].second[0] : 0.0;
        json += std::to_string(v);
    }
    json += "]";

    json += "}"; // spl
    json += "}"; // root

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
