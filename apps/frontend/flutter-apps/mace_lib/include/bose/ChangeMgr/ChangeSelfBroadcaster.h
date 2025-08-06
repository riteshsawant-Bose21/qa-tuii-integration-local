#pragma once
#ifndef CHANGEBROADCASTERSUBJECT_H
#define CHANGEBROADCASTERSUBJECT_H

#include "ChangeMgr/ChangeBroadcaster.h"
#include "Math/FuzzyCompare.h"

namespace bosepro
{
    /**
     * \class       ChangeSelfBroadcaster
     *
     * \brief       A wrapper for a IChangeSubject with its own listeners. Can broadcast its changes to listeners
     *				 
     *
     * \details     All calls are blocking and are performed synchronously.
     */
    class ChangeSelfBroadcaster : public IChangeSubject
    {
    public:

        virtual                     ~ChangeSelfBroadcaster()                                        noexcept {RemoveAllListeners();}
                                    ChangeSelfBroadcaster()                                                  = default;
                                    ChangeSelfBroadcaster(const ChangeSelfBroadcaster& other)                : ChangeSelfBroadcaster(){_broadcaster = other._broadcaster;}
                                    ChangeSelfBroadcaster(ChangeSelfBroadcaster&& other)            noexcept : ChangeSelfBroadcaster(){_broadcaster = std::move(other._broadcaster);}
        ChangeSelfBroadcaster&      operator=(ChangeSelfBroadcaster&& other)                        noexcept {_broadcaster = std::move(other._broadcaster); return *this;}
        ChangeSelfBroadcaster&      operator=(const ChangeSelfBroadcaster& other)                            {auto tmp(other); std::swap(_broadcaster, tmp._broadcaster); return *this;}

        bool						Contains(IChangeListener* const pListener) const                        {return _broadcaster.Contains(pListener);}
        auto                        Size() const                                                            {return _broadcaster.Size(); }

                                    // Add single listener with optional aspect to listen for
        auto						AddListener(IChangeListener* const pListener, const ChangeAspect& aspects = ChangeAspect::DefaultChangeAspect())
                                    {
                                        _broadcaster.AddListener(pListener, aspects);
                                    }

                                    // Remove single listener
        void						RemoveListener(IChangeListener* const pListener)
                                    {
                                        _broadcaster.RemoveListener(pListener);
                                    }

                                    // Remove all listeners
        void						RemoveAllListeners()
                                    {
                                        _broadcaster.RemoveAllListeners();
                                    }

                                    // Notify all listetners 
        inline void                 NotifyListeners(ChangeMsg* const pMsg)
                                    {
                                        if(pMsg != nullptr)
                                        {
                                            _broadcaster.NotifyListeners(pMsg);
                                        }
                                    }

                                    // Notify all listeners 
        inline void                 NotifyListeners(const ChangeAspect& aspect = ChangeAspect::DefaultChangeAspect())
                                    {
                                        ChangeMsg msg(this, aspect);
                                        NotifyListeners(&msg);
                                    }


        template<typename T>        //Set cur to val and notify all listeners with the given message if cur was not equal to val
        void                        SetAndNotifyIfChanged(T& cur, T val, const ChangeAspect& aspect = ChangeAspect::DefaultChangeAspect())
                                    {
                                        if(!math::isApproximatelyEqual(cur, val))
                                        {
                                            cur = val;
                                            NotifyListeners(aspect);
                                        }
                                    }

    private:
        ChangeBroadcaster           _broadcaster;
    };
}

#endif //CHANGESELFBROADCASTER
