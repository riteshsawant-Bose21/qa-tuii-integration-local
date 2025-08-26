#pragma once
#ifndef TRANSDUCER2UIDS

#include <map>
#include <cmath>
#include <memory>
#include "Lock/Lock.h"
#include "Math/Vector.h"
#include "Clusters.h"
#include "Loudspeaker.h"
#include "Node.h"

namespace bosepro::hardware
{
	/**
	* \brief controlled lookup for transducer, could change to UUID. For now, use location in whole millimeters to avoid issues with float/double fuzzy matching.
	*/
	class TransducerCacheKey final
	{
    public:
                                TransducerCacheKey(math::Vec3 loc)
                                {
                                    _x = static_cast<int64_t>(std::round(loc.x * 1000.0)); // round to nearest millimeter
                                    _y = static_cast<int64_t>(std::round(loc.y * 1000.0)); // round to nearest millimeter
                                    _z = static_cast<int64_t>(std::round(loc.z * 1000.0)); // round to nearest millimeter
                                }
                                ~TransducerCacheKey()                           = default;
                                TransducerCacheKey(const TransducerCacheKey&)   = default;
        TransducerCacheKey&     operator=(const TransducerCacheKey&) = delete;
                                TransducerCacheKey(TransducerCacheKey&&) = delete;
        TransducerCacheKey&     operator=(TransducerCacheKey&&) = delete;

		const bool              operator < (const TransducerCacheKey& other) const noexcept
		                        {
			                        // sort order doesn't matter as much as having consistent behavior.
			                        auto ret = (_x < other._x);
			                        if (_x == other._x)
			                        {
				                        ret = (_y < other._y);
				                        if (_y == other._y)
				                        {
					                        ret = (_z < other._z);
				                        }
			                        }
			                        return ret;
		                        }

	protected:
		int64_t                 _x;
		int64_t                 _y;
		int64_t                 _z;
	};

	struct TransducerCacheData
	{
		uint64_t clusterUID{0};
		uint64_t loudspeakerUID{0};
		std::string ampChannel{};
	};
	/**
	* \brief	Provide ability to find what loudspeaker and cluster own a particular transducer based on arrival data of src location.  
	* \details	Current key of the transducers is its global location.  This should probably change to a UUID to avoid fuzzy matching.
	*			This is a cache to provide rapid lookup rather than traversing a node tree.  Like all caches it must be kept up to date.
	*/
	class Transducer2UIDs
	{
    public:
        bool rebuildCache(std::unique_ptr<model::ClusterSystem>& system )
        {
            auto ret = false;

            {
                ScopedLock sl(_lock);
                _mapTransducer2UIDs.clear();
            }

            auto clusters = system->getChildren<model::LoudspeakerCluster>();
            for (auto& cluster : clusters)
            {
                if (cluster == nullptr)
                {
                    continue;
                }

                auto clusterUID = cluster->getId();
                auto loudspeakers = cluster->getChildren<hardware::Loudspeaker>();
                for (auto const& loudspeaker : loudspeakers)
                {
                    if (loudspeaker == nullptr)
                    {
                        continue;
                    }
                    auto loudspeakerUID = loudspeaker->getId();
                    auto mapChanLocs = loudspeaker->getTransducerLocsPerAmpChan();
                    for(auto& chan: mapChanLocs)
                    {
                        auto& connectionName = chan.first;
                        for(auto& lsLocalTLoc: chan.second)
                        {
                            auto globalLoc = cluster->getTransform()* loudspeaker->getTransform()* lsLocalTLoc;
                            addTransducer(globalLoc, clusterUID, loudspeakerUID, connectionName);
                            ret = true;
                        }
                    }
                }
            }
            return ret;
        }

		auto getTransducerUIDData(math::Vec3 globalLoc)
		{
            ScopedLock sl(_lock);
			TransducerCacheData td;
			TransducerCacheKey tk(globalLoc);
			auto it = _mapTransducer2UIDs.find(tk);
			if (it != _mapTransducer2UIDs.end())
			{
				td = it->second;
			}
			return td;
		}

    protected:
        void addTransducer(math::Vec3 globalLoc, uint64_t clusterUID, uint64_t loudspeakerUID, std::string ampChannelName)
        {
            ScopedLock sl(_lock);
            TransducerCacheKey tk(globalLoc);
            TransducerCacheData td{clusterUID, loudspeakerUID, ampChannelName};
            _mapTransducer2UIDs[tk] = td;
        }

	private:
		// It seems simpler to duplicate the cluster uid and loudspeaker uid fields in the amp channel row.
		// rather than having a map of map of map,  one lookup vs 3.
		// overview:
		// system ->
		//	clusters ->
		//		loudspeakers ->
		//			ampChan		
		std::map<TransducerCacheKey, TransducerCacheData> _mapTransducer2UIDs;
        Lock _lock;
	};
}
#endif
