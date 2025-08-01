#pragma once
#ifndef NODE_H
#define NODE_H

#include <vector>
#include <memory>
#include <deque> // this could change to list or other container depending on a node benchmark to be written
#include <unordered_set>
#include <unordered_map>
#include <algorithm>
#include <functional>
#include "Uid.h"
#include "Lock/Lock.h"

namespace bosepro
{
    class Node;
    using NodePtr                           = std::shared_ptr<Node>;
    using ConstNodePtr                      = std::shared_ptr<const Node>;	
    
	//-----------------------------------------------------------------------------------------------------------------
	// change these four rows to change the fundamental container.  KA: 5/15 deque performing better so far across add/remove/get in engine, will have node benchmark at some point to confirm for insert/traversal
	using Nodes                             = std::deque<NodePtr>; 
	
	using NodePs							= std::deque<Node*>;

	template<class T>
	using NodesT							= std::deque<T>;

	template<class T>
	using NodePtrsT							= std::deque<std::shared_ptr<T>>;
	//-----------------------------------------------------------------------------------------------------------------
	using NodeIdsCache						= std::unordered_map<uint64_t, NodePtr>; // we need two maps to support fast lookup of ID or fast lookup of ptr otherwise some ops are unduly expensive.
	using NodePtrsCache						= std::unordered_set<NodePtr>; // don't need this to be a map as ptr has the id :)

	template<class T>
	using Iterator							= typename NodesT<T>::iterator;

	template<class T>
	using ConstIterator						= typename NodesT<T>::const_iterator;


    using fnCanAdd                          = std::function<bool()>; // tried to pass two basic params over but std::placeholder isn't mapping so just have client pass all params it needs.

    /**
     * \class       Node
     *
     * \brief       Thread safe node object
     *
     * \details     Children need to override clone(), in virtually all cases
     */
    class Node : public Uid
    {
    public:
        virtual                             ~Node()                         noexcept;
                                            Node()                          = default;
                                            Node(const Node& other);
                                            Node(Node&& other)                                    noexcept  : Node(){swap(*this, other);}
        Node&                               operator=(Node&& other)                               noexcept  {swap(*this, other); return *this;}
        Node&                               operator=(const Node& other)                                    {auto tmp(other); swap(*this, tmp); return *this;}
                                            // flag is to be used by inherited class for whatever purpose needed., self assigned to avoid unreferenced warning.
        virtual Node*                       clone(bool flag = false)                        const           {flag = flag; return new Node(*this);}//todo //ADB would prefer this to be abstract

        inline const Lock&                  getLock()                                       const noexcept  {return m_Lock;}

                                            //Root node
        Node* const                         getRoot()                                       const;

                                            //Nodes.back() is root
        const NodePs						getRootPath()                                   const;

        inline Node* const                  getParent()                                     const noexcept  {return m_Parent;}
        inline void                         clearParent()                                                   {m_Parent = NULL;}

        inline bool                         isChildOf(const NodePtr& ptr)                   const noexcept  {return ptr == nullptr ? false : getParent() == ptr.get();}

        std::size_t                         getNumChildren()                                const noexcept;

                                            //Child add
        bool                                addChild(NodePtr ptr, fnCanAdd fn = nullptr);
        std::size_t                         addChildren(const Nodes& children, fnCanAdd f = nullptr);

                                            //Child insert (before|after target)
        bool                                insertChild(NodePtr ptr, 
                                                        NodePtr target, 
                                                        bool insertAfter = false,
                                                        fnCanAdd f = nullptr);

                                            //Child removal
        bool                                removeChild(uint64_t id);
        bool                                removeChild(const NodePtr& ptr);

        template <class T = Node>           //Child removal subset (return is # removed)
        std::size_t                         removeChildren(const NodesT<T>& children)
                                            {
                                                ScopedLock sl(getLock()); 

                                                std::size_t remove = 0;

                                                for(auto const& child : children)
                                                {
                                                    if(removeChild(child))
                                                    {
                                                        ++remove;
                                                    }
                                                }

                                                return remove;
                                            }

        template <class T = Node>           //Remove all
        void                                removeAllChildren()
                                            {
                                                ScopedLock sl(getLock()); 

                                                removeChildren(getChildren<T>());
                                            }

                                            //Child existence
        inline bool                         hasChild(uint64_t id)                           const           
											{
												// avoid the expensive dyanmic_pointer_cast just to find out if we have a child id!
												// getChild always does the expensive cast.
												return hasNodeId(id);
											}
        inline bool                         hasChild(const NodePtr& ptr)                    const           
											{
												return ptr == nullptr ? false : hasNodePtr(ptr);
											}

        template <class T = Node>           //Child retrieval by id
        std::shared_ptr<T>                  getChild(uint64_t id)                           const
                                            {
                                                ScopedLock sl(getLock());

                                                std::shared_ptr<T> ptr;
																								
                                                auto const& it = m_cachedIds.find(id);

                                                if(it != m_cachedIds.cend())
                                                {
													// TODO: anyway to avoid this cheaply (if T is Node???)
                                                    ptr = std::dynamic_pointer_cast<T>(it->second);
                                                }
                                                return ptr;
                                            }

		bool								hasNodeId(uint64_t id)                        const
											{												
												// this version used for hasChild to avoid dynamic_pointer_cast and pointer assign
												ScopedLock sl(getLock());												
												return m_cachedIds.find(id) != m_cachedIds.end();												
											}

		bool								hasNodePtr(const NodePtr& ptr)				   const
											{
												ScopedLock sl(getLock());
												return m_cachedPtrs.find(ptr) != m_cachedPtrs.end();
											}


        template <class T = Node>           //Child retrieval by index
        std::shared_ptr<T>                  getChildByIndex(std::size_t index)              const
                                            {
                                                ScopedLock sl(getLock());

                                                std::shared_ptr<T> ptr;

                                                assert(m_Children.size() > index);

                                                if (m_Children.size() > index)
                                                {
                                                    Nodes::const_iterator it = std::next(m_Children.cbegin(), index);

                                                    if (it != m_Children.cend())
                                                    {
                                                        ptr = std::dynamic_pointer_cast<T>(*it);
                                                    }
                                                }

                                                return ptr;
                                            }

        template <class T = Node>           //Children retrieval by type
		NodePtrsT<T>						getChildren()                                   const
                                            {
                                                ScopedLock sl(getLock());

												NodePtrsT<T> nodes;

                                                for(auto const& child : m_Children)
                                                {
                                                    //Add child if type T
                                                    if(auto p = (std::dynamic_pointer_cast<T>(child)))
                                                    {
                                                        nodes.emplace_back(p);
                                                    }
                                                }

                                                return nodes;
                                            }

                                            //Children ids
        std::vector<uint64_t>               getChildrenIds()                          const
                                            {
                                                ScopedLock sl(getLock());

                                                std::vector<uint64_t> ids;

                                                for(auto const& c : getChildren())
                                                {
                                                    if(c != nullptr)
                                                    {
                                                        ids.emplace_back(c->getId());
                                                    }
                                                }

                                                return ids;
                                            }

                                            //Sibling existence
        inline bool                         hasSibling(uint64_t id)                      const           {return getSibling(id) != nullptr;}
        inline bool                         hasSibling(const NodePtr& ptr)               const           {return ptr == nullptr ? false : hasSibling(ptr->getId());}

        template <class T = Node>           //Sibling retrieval
        std::shared_ptr<T>                  getSibling(uint64_t id)                      const
                                            {
                                                ScopedLock sl(getLock());

                                                std::shared_ptr<T> ptr;

                                                // this is slow!  we're getting copies of nodes, given a ptr ideally it'd be fast to get siblings.
												Nodes nodes = getSiblings();												
                                                auto const& it = itById(nodes, id);

                                                if(it != nodes.cend())
                                                {
                                                    ptr = std::dynamic_pointer_cast<T>(*it);
                                                }

                                                return ptr;
                                            }

        template <class T = Node>           //Sibling(s) retrieval by type
		NodePtrsT<T>						getSiblings(bool excludeSelf = true)            const
                                            {
                                                ScopedLock sl(getLock());

												NodePtrsT<T> nodes;

                                                if(Node* const parent = (getParent()))
                                                {
                                                    nodes = parent->getChildren<T>();

                                                    if(excludeSelf)
                                                    {
                                                        auto const& it = itById(nodes, getId());

                                                        if(it != nodes.cend())
                                                        {
                                                            nodes.erase(it);
                                                        }
                                                    }
                                                }

                                                return nodes;
                                            }

                                            //Sibling ids
        std::vector<uint64_t>               getSiblingIds(bool excludeSelf = true)          const
                                            {
                                                ScopedLock sl(getLock());

                                                std::vector<uint64_t> ids;

                                                for(auto const& s : getSiblings(excludeSelf))
                                                {
                                                    if(s != nullptr)
                                                    {
                                                        ids.emplace_back(s->getId());
                                                    }
                                                }

                                                return ids;
                                            }


                                            //Descendant existence
        inline bool                         hasDescendant(uint64_t id)                      const           {return getDescendant(id) != nullptr;}
        inline bool                         hasDescendant(const NodePtr& ptr)               const           {return ptr == nullptr ? false : hasDescendant(ptr->getId());}

        template <class T = Node>           //Descendant retrieval
        std::shared_ptr<T>                  getDescendant(uint64_t id)                      const
                                            {
                                                ScopedLock sl(getLock());

                                                std::shared_ptr<T> ptr;

                                                Nodes nodes = getDescendants();

                                                auto const& it = itById(nodes, id);

                                                if(it != nodes.cend())
                                                {
                                                    ptr = std::dynamic_pointer_cast<T>(*it);
                                                }

                                                return ptr;
                                            }

        template <class T = Node>           //Descendant(s) retrieval by type
		NodePtrsT<T>						getDescendants()                                const
                                            {
                                                ScopedLock sl(getLock());

												NodePtrsT<T> nodes;

                                                for(auto const& child : m_Children)
                                                {
                                                    if(child != nullptr)
                                                    {
                                                        //Add child if type T
                                                        if(auto p = (std::dynamic_pointer_cast<T>(child)))
                                                        {
                                                            nodes.emplace_back(p);
                                                        }

                                                        //Add child's children of type T
														// list used splice, vector doesn't support that. nodes.splice(nodes.cend(), child->getDescendants<T>());
														auto descendants = child->getDescendants<T>();
                                                        nodes.insert(nodes.cend(), descendants.begin(), descendants.end());
                                                    }
                                                }

                                                return nodes;
                                            }

                                            //Descendant(s) ids
        std::vector<uint64_t>               getDescendantIds()                          const
                                            {
                                                ScopedLock sl(getLock());

                                                std::vector<uint64_t> ids;

                                                for(auto const& d : getDescendants())
                                                {
                                                    if(d != nullptr)
                                                    {
                                                        ids.emplace_back(d->getId());
                                                    }
                                                }

                                                return ids;
                                            }

        protected:
        inline friend void                  swap(Node& lhs, Node& rhs) noexcept
                                            {
                                                ScopedLockPair sl(lhs.getLock(), rhs.getLock());

                                                std::swap(static_cast<Uid&>(lhs)    , static_cast<Uid&>(rhs));
                                                std::swap(lhs.m_Parent              , rhs.m_Parent);
                                                std::swap(lhs.m_Children            , rhs.m_Children);
                                                // NOTE: MUST fix parent assignments otherwise they will be wrong
                                                for (auto child : lhs.m_Children)
                                                {
                                                    child->m_Parent = &lhs; // set to lhs
                                                }
                                                // same for rhs
                                                for (auto child : rhs.m_Children)
                                                {
                                                    child->m_Parent = &rhs; // set to rhs
                                                }


                                            }

    private:
        template <class T = Node>           //Internal helper to get iterator by id
        static Iterator<T> itById(NodesT<T>& nodes, uint64_t id){return std::find_if(nodes.begin(), nodes.end(), [&](auto const& p){return p != nullptr && p->getId() == id;});}

        template <typename T = Node>        //Internal helper to get const iterator by id
        static ConstIterator<T> itById(const NodesT<T>& nodes, uint64_t id){return std::find_if(nodes.begin(), nodes.end(), [&](auto const& p){return p != nullptr && p->getId() == id;});}


        template <typename T = Node>        //Internal helper to get iterator by ptr
        static Iterator<T> itByPtr(NodesT<T>& nodes, const NodePtr& ptr){return std::find_if(nodes.begin(), nodes.end(), [&](auto const& p){return p != nullptr && p == ptr;});}

        template <typename T = Node>       //Internal helper to get const iterator by ptr
        static ConstIterator<T> itByPtr(const NodesT<T>& nodes, const NodePtr& ptr){return std::find_if(nodes.cbegin(), nodes.cend(),[&](auto const& p){return p != nullptr && p == ptr;});}

        inline NodePtr                      getFront() const {return m_Children.empty() ? nullptr : m_Children.front();}
        inline NodePtr                      getBack()  const {return m_Children.empty() ? nullptr : m_Children.back();}

    private:
        Lock                                m_Lock;

        Node*                               m_Parent = nullptr;

        Nodes                               m_Children;
		NodeIdsCache						m_cachedIds; // cache ids to have faster lookup when adding. given id fast to get ptr
		NodePtrsCache						m_cachedPtrs; // cache ptrs too, given ptr, fast to lookup
    };
}//bosepro

#endif //NODE_H