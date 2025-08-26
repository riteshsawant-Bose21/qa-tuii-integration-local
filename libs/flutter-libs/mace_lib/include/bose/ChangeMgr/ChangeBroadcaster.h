#pragma once
#ifndef CHANGEBROADCASTER_H
#define CHANGEBROADCASTER_H

#include <unordered_map>
#include "Lock/Lock.h"
#include "ChangeMgr/ChangeAspect.h"
#include "ChangeMgr/IChangeListener.h"
#include "ChangeMgr/ChangeMsg.h"

namespace bosepro
{
    /**
     * \class       ChangeBroadcaster
     *
     * \brief       Simple container for thread safe handling of IChangeListener pointers.
     * 			 See also IChangeListener, IChangeSubject, ChangeMsg
     *
     * \details     All calls are blocking and are performed synchronously.
     */
    class ChangeBroadcaster
    {
    public:
        virtual                     ~ChangeBroadcaster()                                    noexcept {ScopedLock lock(_lock); RemoveAllListeners();}
                                    ChangeBroadcaster()                                              = default;
                                    ChangeBroadcaster(const ChangeBroadcaster& other)                : ChangeBroadcaster(){ScopedLockPair sl(_lock, other._lock); auto map(other._map); std::swap(_map, map);}
                                    ChangeBroadcaster(ChangeBroadcaster&& other)            noexcept : ChangeBroadcaster(){ScopedLockPair sl(_lock, other._lock); _map = std::move(other._map);}
        ChangeBroadcaster&          operator=(ChangeBroadcaster&& other)                    noexcept {ScopedLockPair sl(_lock, other._lock); _map = std::move(other._map); return *this;}
        ChangeBroadcaster&          operator=(const ChangeBroadcaster& other)                        {ScopedLockPair sl(_lock, other._lock); auto tmp(other); std::swap(_map, tmp._map); return *this;}

        bool						Contains(IChangeListener* const pListener) const                 {ScopedLock sl(_lock); return _map.find(pListener) != _map.end();}
        std::size_t                 Size() const                                                     {ScopedLock sl(_lock); return _map.size();}

                                    // Add single listener with optional aspect to listen for
        bool						AddListener(IChangeListener* const pListener, const ChangeAspect& aspects = ChangeAspect::DefaultChangeAspect())
                                    {
                                        ScopedLock sl(_lock);
                                        bool success = false;

                                        const auto it = _map.find(pListener);

                                        if (it == _map.end())
                                        {
                                            success = true;
                                            _map.insert({ pListener, aspects });
                                        }

                                        return success;
                                    }

                                    // Remove single listener
        void						RemoveListener(IChangeListener* const pListener)
                                    {
                                        ScopedLock sl(_lock);
                                        const auto it = _map.find(pListener);
                                        if (it != _map.end())
                                        {
                                            _map.erase(it);
                                        }
                                    }

                                    // Remove all listeners
        void						RemoveAllListeners()
                                    {
                                        ScopedLock sl(_lock);
                                        _map.clear();
                                    }

                                    // Notify all listeners with the given message
        void						NotifyListeners(ChangeMsg* const pMsg)
                                    {
                                        if (pMsg != nullptr)
                                        {
                                            ScopedLock sl(_lock);

                                            for (auto it : _map)
                                            {
                                                assert(it.first);

                                                if (it.first != nullptr && pMsg->GetAspect().Matches(it.second))
                                                {
                                                    it.first->OnChangeMsg(pMsg);
                                                }
                                            }
                                        }
                                    }

    private:
        std::unordered_map<IChangeListener*, const ChangeAspect> _map;
        Lock                                                     _lock;
    };
}

#endif //ChangeBroadcaster_H
