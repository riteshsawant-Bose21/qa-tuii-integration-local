#pragma once
#ifndef CHANGEMSG_H
#define CHANGEMSG_H

#include <utility>
#include "ChangeMgr/IChangeSubject.h"
#include "ChangeMgr/ChangeAspect.h"

namespace bosepro
{
    /**
     * \class       ChangeMsg
     *
     * \brief       Object passed to IChangeListener objects.
     *
     * \details     This object houses the subject in an Observer Pattern.
     * 			 See also IChangeSubject and ChangeAspect.
     */
    class ChangeMsg
    {
    public:
                            ChangeMsg(IChangeSubject* const pSubject, ChangeAspect aspect)
                                : _subject{ pSubject },
                                _aspect{ std::move(aspect) }
                            { }

                            ChangeMsg(IChangeSubject* const pSubject)                           : ChangeMsg(pSubject, ChangeAspect::DefaultChangeAspect()) { }

                            ChangeMsg(IChangeSubject* const pSubject, const std::size_t uiHint) : ChangeMsg(pSubject, ChangeAspect(uiHint)) { }
                            ~ChangeMsg()                                                        = default;
                            ChangeMsg(const ChangeMsg&)                                         = delete;
                            ChangeMsg(ChangeMsg&&)                                              = delete;

        auto                operator=(const ChangeMsg&)                                         = delete;
        auto                operator=(ChangeMsg&&)                                              = delete;

        const auto&		    GetAspect() const                                                   { return _aspect; }
        auto				GetAspectHint() const                                               { return _aspect.GetHint(); }

        auto                GetSubject() const                                                  { return _subject; }
        auto				GetSubjectHint() const                                              { return _subject != nullptr ? _subject->GetChangeSubjectHint() : 0; }

        template<typename T>
        auto                GetSubject() const                                                  { return dynamic_cast<T* const>(_subject); }

    protected:
        IChangeSubject*     _subject;
        ChangeAspect        _aspect;
    };
}

#endif //CHANGEMSG_H