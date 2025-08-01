#pragma once
#ifndef CLUSTERS_H
#define CLUSTERS_H

#include <memory>

#include "LoudspeakerCluster.h"
#include "Lock/Lock.h"
#include "Node.h"


/**
 * \brief	model represents classes that relate to a tangible physical model (sound system or venue audience areas)
 *
 * \ingroup	model
 */
namespace bosepro::model
{
    /**
	 * \class		ClusterSystem
	 *
	 * \brief		Represents a collection of one or more clusters that exist in an audio system in a venue.
	 * \details		This object provides for add/remove api from application.       
     *				This is an implicit collection of *all* and is the top level root node
     * \details		This object has NO bearing on Placement of all child components.  Mostly hiearchical.
     *				Has a representation for a filter and the acoustic stimulus.
     *              Must be public for dynamic cast to work!
	 */
    class ClusterSystem       : public Node, 
                                public acoustics::FilterInterface
    {
    public:
                                                ClusterSystem();
                                                ~ClusterSystem()
                                                {
                                                    clearAll();
                                                }
                                                    
                                                // we're using a scoped lock so don't allow copy or =
                                                ClusterSystem(const ClusterSystem&)                     = default;
                                                ClusterSystem(ClusterSystem&&)                 noexcept = default;
                                                ClusterSystem& operator=(ClusterSystem&&)      noexcept = default;
                                                ClusterSystem& operator=(const ClusterSystem&)          = default;

	    bool   					                addCluster(LoudspeakerClusterPtr ptr);
	    bool					                removeCluster(const LoudspeakerClusterPtr& ptr);
	    Uid::Ids								list()									const;

        virtual bool                            addFilter(acoustics::FilterDataSet) = 0;
        virtual acoustics::FiltersData          listFilters()                       = 0;
        virtual bool                            removeFilter(std::string type)      = 0;
        virtual void                            removeAllFilters()                  = 0;

        std::size_t                             size()                                  const  noexcept { return Node::getNumChildren(); }
        bool                                    empty()                                 const  noexcept { return Node::getNumChildren() < 1; }
        
	    void                                    clearAll();

        std::size_t                             getMaxArrivals()                        const;

        // node things
        //UID
        uint64_t                                getId()                                 const   noexcept { return Node::getId(); }

        //Component existence
        inline bool                             hasCluster(uint64_t id)                 const { return hasChild(id); }

        template <class T = hardware::HardwareComponent>  //Component retrieval by id
        std::shared_ptr<T>                      getComponent(uint64_t id)               const { return getDescendant<T>(id); }

        template <class T = LoudspeakerCluster> //Cluster retrieval by id
        std::shared_ptr<T>                      getCluster(uint64_t id)                 const { return getChild<T>(id); }

        template <class T = LoudspeakerCluster> //Component retrieval by index
        std::shared_ptr<T>                      getClusterByIndex(std::size_t index)    const { return getChildByIndex<T>(index); }

        template <class T = LoudspeakerCluster> //Components retrieval
	    NodePtrsT<T>							getClusters()                           const { return getChildren<T>(); }

        //Component ids
        std::vector<uint64_t>                   getClusterIds()                         const { return getChildrenIds(); }
                
        bool									setStimulus(std::string stim);

        std::string								getStimulus()                           const noexcept { ScopedLock sl(getLock()); return _stimulus; }

    private:
        std::string								_stimulus;
    };
} // bosepro::model
#endif // CLUSTERS_H
