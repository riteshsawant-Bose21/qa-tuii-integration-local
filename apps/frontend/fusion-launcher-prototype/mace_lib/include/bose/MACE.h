#ifndef BOSEACOUSITCS_H
#define BOSEACOUSITCS_H


#if defined(_WIN32)
// Override any custom calling conventions, stick with the COM compatible
// STDCALL calling convention This fixes any issues when including in code with
// different calling conventions.
#define BOSECALL __stdcall
#else // nop for everyone else.
#define BOSECALL
#endif

#include <memory> // for shared_ptr
#include <string>
#include <tuple>

#include "Surface.h"
#include "LoudspeakerCluster.h"
#include "Loudspeaker.h"
#include "FieldPoints.h"
#include "MeasurementTypes.h"
#include "Transducer2UIDs.h"
#include "FilterInterface.h"
#include "Math/Segment.h"

/**
 * \brief	bosepro is the top level namespace grouping all functionality that the MACE team incorporated. 
 *          It also contains classes that didn't necessarily fit other categories, or were not yet reorganized into other categories.
 *          The Class Index in Classes is a good place to view the relation between namespace and classes.
 *
 * \ingroup	bosepro
 */
namespace bosepro
{   
    class IMACE;
    using IMACEPtr = std::shared_ptr<IMACE>;
    /**
     * \class       IMACE
     *
     * \brief       Facade API Interface for client applications to use.
     *              This is an interface class.  The real work is done in the impl derivation.
     *              Unfortunately one can't just use the __interface keyword as that's not standard c++
     *              Every function in the interface is pure virtual.
     *
     * \details     NOTE: while this library could be built with Qt or other frameworks, 
     *              it should not directly utilize those types. 
     *              Only std library and primitive types should be employed here such
     *              that the library could be built without Qt for other projects.  In some cases
     *              may need to thunk from framework object types to primitives to use the internal IP.
     *              If that is needed, an adapter class could be a shim on the client
     *              application side.
     */
    class IMACE
    {
    public:
                                                IMACE()                     = default;
        virtual                                 ~IMACE()                    = default;
                                                IMACE(const IMACE&)         = delete;
        IMACE&                                  operator=(const IMACE&)     = delete;
                                                IMACE(IMACE&&)              = delete;
        IMACE&                                  operator=(IMACE&&)          = delete;

        enum class AccelMode { sumGPU, sumCPU, sum1CPU };

                                                            /** \brief Library version info */
        virtual std::string                     BOSECALL    GetLibVersion()                                                     const       = 0;

        virtual bool                            BOSECALL    CheckVersion(int maj, int min) const = 0;

                                                            //
        virtual void                            BOSECALL    StartEngine()                                                                   = 0;
        virtual void                            BOSECALL    StopEngine()                                                                    = 0;

                                                            //Why: to calc in terms of venue its acoustical impact
        virtual void                            BOSECALL    AddSurface(model::SurfacePtr ptr)                                               = 0;
        virtual void                            BOSECALL    RemoveSurface(model::SurfacePtr ptr)                                            = 0;
        virtual void                            BOSECALL    RemoveAllSurfaces()                                                             = 0;
        virtual std::size_t                     BOSECALL    GetSurfaceCount()                                                   const       = 0;
        virtual model::SurfacePtr               BOSECALL    GetSurface(uint64_t id)                                             const       = 0;
        virtual Uid::Ids                        BOSECALL    GetSurfaceList()                                                    const       = 0;
        virtual std::tuple<math::Segments, Uid::Ids> BOSECALL    GetCutSegments(math::Vec3 origin, Orientation orientation)     const       = 0;

                                                            //Who: to calc in terms of acoustic sources
        virtual uint64_t                        BOSECALL    CreateCluster()                                                                 = 0;
        virtual void                            BOSECALL    AddCluster(model::LoudspeakerClusterPtr ptr)                                    = 0;
        virtual void                            BOSECALL    RemoveCluster(model::LoudspeakerClusterPtr ptr)                                 = 0;
        virtual void                            BOSECALL    RemoveAllClusters()                                                             = 0;
        virtual std::size_t                     BOSECALL    GetClusterCount()                                                   const       = 0;
        virtual model::LoudspeakerClusterPtr    BOSECALL    GetCluster(uint64_t id)                                             const       = 0;
        virtual bool                            BOSECALL    HasCluster(uint64_t id)                                             const       = 0;
        virtual std::size_t                     BOSECALL    GetTotalArrivals()                                                  const       = 0;
        virtual Uid::Ids                        BOSECALL    GetClusterList()                                                    const       = 0;

        virtual bool                            BOSECALL    AddSystemFilter(acoustics::FilterDataSet fd)                                    = 0;
        virtual acoustics::FiltersData          BOSECALL    ListSystemFilters()                                                             = 0;
        virtual bool                            BOSECALL    RemoveSystemFilter(std::string type)                                            = 0;
        virtual void                            BOSECALL    RemoveAllSystemFilters()                                                        = 0;

                                                            // accessors (can't have templates and virtual together)
        virtual hardware::HardwareComponentPtr  BOSECALL    GetHWComponentFromClusters(uint64_t id)                             const       = 0;
        virtual hardware::LoudspeakerPtr        BOSECALL    GetLoudspeakerFromClusters(uint64_t id)                             const       = 0;
        virtual std::shared_ptr<Placement>      BOSECALL    GetPlacementFromClusters(uint64_t id)                               const       = 0;
        virtual NodePtr                         BOSECALL    GetNodeFromClusters(uint64_t id)                                    const       = 0;


                                                            //What: collection
        virtual uint64_t                        BOSECALL    CreateGroup()                                                                   = 0;
        virtual void                            BOSECALL    RemoveGroup(Uid::Ids uids)                                                      = 0;
        virtual bool                            BOSECALL    HasGroup(uint64_t groupId)                                          const       = 0;
        virtual void                            BOSECALL    AddToGroup(uint64_t groupId, Uid::Ids uidMembers)                               = 0;
        virtual void                            BOSECALL    RemoveFromGroup(uint64_t groupId, Uid::Ids uidsRemove)                          = 0;
        virtual Uid::Ids                        BOSECALL    GetGroupList(uint64_t groupId)                                      const       = 0;
        virtual Uid::Ids                        BOSECALL    GetGroupsList()                                                     const       = 0;
        virtual void                            BOSECALL    RemoveAllGroups()                                                               = 0;

                                                            //Where: to calc spatially
        virtual void                            BOSECALL    AddFieldPoints(uint64_t sourceId, simulation::FieldPointsPtr ptr)               = 0;
        virtual void                            BOSECALL    RemoveFieldPoints(uint64_t sourceId)                                            = 0;
        virtual void                            BOSECALL    RemoveAllFieldPoints()                                                          = 0;
        virtual bool                            BOSECALL    HasField(uint64_t uid)                                              const       = 0;
        virtual std::size_t                     BOSECALL    GetFieldCount()                                                     const       = 0;
        virtual std::tuple<math::Vec3s, std::vector<uint64_t>, bool>  BOSECALL    GetLinePoints(math::Segments segments, Uid::Ids uids, std::vector<double> earHeights, double resolution, double startOffset, double endOffset) const       = 0;

                                                            //Simulation related //TODO: refine the sim & model stuff out to respective objects.        
        virtual uint64_t                        BOSECALL    CreateMeasurement(MeasurementType mt)                                           = 0;
        virtual void                            BOSECALL    RemoveMeasurements(Uid::Ids ids)                                                = 0;
        virtual bool                            BOSECALL    HasMeasurement(uint64_t measurementId)                              const       = 0;
        virtual Uid::Ids                        BOSECALL    GetMeasurementsList(MeasurementType* pmt)                           const       = 0;
        virtual bool                            BOSECALL    AddGroupsToMeasurement(uint64_t measurementId, Uid::Ids uids)                   = 0;
        virtual bool                            BOSECALL    RemoveGroupsFromMeasurement(uint64_t measurementId, Uid::Ids uids)              = 0;
        virtual Uid::Ids                        BOSECALL    GetMeasurementGroupList(uint64_t measurementId)                     const       = 0;
        virtual void                            BOSECALL    RemoveAllMeasurements()                                                         = 0;
        virtual MeasurementType                 BOSECALL    GetMeasurementType(uint64_t measurementId)                          const       = 0;
        virtual bool                            BOSECALL    IsMeasurementBusy(uint64_t measurementId)                           const       = 0;
        virtual void                            BOSECALL    SetMeasurementPropagationDelay(uint64_t measurementId, double d)                = 0;
        virtual double                          BOSECALL    GetMeasurementPropagationDelay(uint64_t measurementId)              const       = 0;


                                                            //When: to calculate, on demand or on change
        virtual void                            BOSECALL    SetAutocalc(bool b)                                                             = 0;
        virtual bool                            BOSECALL    GetAutocalc()                                                       const       = 0;

        virtual void                            BOSECALL    SetAccelMode(int mode)                                                          = 0;
        virtual int                             BOSECALL    GetAccelMode()                                                      const       = 0;

                                                            // benchmark function used to use conditional compile for perf stats, 
                                                            // but now that static library is linked, we needed a switch
        virtual void                            BOSECALL    SetCollectStats(bool b)                                                         = 0;
        virtual bool                            BOSECALL    GetCollectStats()                                                   const       = 0;

        virtual void                            BOSECALL    SetStimulus(std::string stim)                                                   = 0;
        virtual std::string                     BOSECALL    GetStimulus()                                                       const       = 0;
            
        virtual void                            BOSECALL    Calculate(bool bWait = false, 
                                                                Uid::Ids * pIds = nullptr, 
                                                                Uid::Ids * pIdsCancel = nullptr)                                    = 0;
            
                                                            //Resultant data from a calculation
        virtual simulation::FieldPointsDataPtr  BOSECALL    GetData(uint64_t sourceId)                                          const       = 0;

                                                            //Calculation completion notification
        virtual void                            BOSECALL    AddListener(measurement::CalcListener* const p)                                             = 0; 
        virtual void                            BOSECALL    RemoveListener(measurement::CalcListener* const p)                                          = 0;

                                                            //Clears all collections. Resets auto-calc to off.
        virtual void                            BOSECALL    Clear()                                                                         = 0;

        virtual bool                            BOSECALL    AnyJobsRunning()                                                    const       = 0;

        virtual hardware::TransducerCacheData   BOSECALL    GetTransducerUIDData(math::Vec3 globalLoc)                          const       = 0;

    };

    /**
     * \class       EngineFactory
     *
     * \brief       Factory for IMACE engine lifetime management
     */
    class EngineFactory
    {
    public:
        enum class EngineId
        {
            MAIN_ENGINE
        };

        static std::shared_ptr<IMACE>           GetEngine(EngineId engineId = EngineId::MAIN_ENGINE);
        static void                             DestroyEngine(EngineId engineId = EngineId::MAIN_ENGINE);
    };
}//bosepro
#endif // MACE_H
