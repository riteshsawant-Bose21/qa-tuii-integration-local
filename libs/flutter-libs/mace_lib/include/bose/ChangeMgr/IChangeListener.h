#pragma once
#ifndef ICHANGELISTENER_H
#define ICHANGELISTENER_H

#include "ChangeMgr/ChangeMsg.h"

namespace bosepro
{
        /**
         * \class       IChangeListener
         *
         * \brief       Abstract interface for ChangeMsg listeners. See also ChangeMsg.
         *
         * \details     This is just an observer in the Observer Pattern.
         */
        class IChangeListener
        {
        public:
            virtual                 ~IChangeListener()                          = default;
                                    IChangeListener()                           = default;
                                    IChangeListener(const IChangeListener&)     = default;
            IChangeListener&        operator=(const IChangeListener&)           = default;
                                    IChangeListener(IChangeListener&&)          = default;
            IChangeListener&        operator=(IChangeListener&&)                = default;

            virtual void            OnChangeMsg(ChangeMsg* const pMsg)          = 0;
        };
    
}

#endif //ICHANGELISTENER_H