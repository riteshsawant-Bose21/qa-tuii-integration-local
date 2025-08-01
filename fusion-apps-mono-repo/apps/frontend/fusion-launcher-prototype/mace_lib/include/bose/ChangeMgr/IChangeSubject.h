#pragma once
#ifndef ICHANGESUBJECT_H
#define ICHANGESUBJECT_H

namespace bosepro
{
    /**
     * \class       IChangeSubject
     *
     * \brief       Abstract interface for ChangeMsg subject.  See also IChangeListener.
     *
     * \details     This is subject payload in the Observer Pattern. See also ChangeMsg.
     * 			 Inheritance is all that is required, however GetChangeSubjectHint() can be overridden for customization
     */
    class IChangeSubject
    {
    public:
        virtual                     ~IChangeSubject()                               = default;

                                    IChangeSubject()                                = default;
                                    IChangeSubject(const IChangeSubject&)           = default;
                                    IChangeSubject(IChangeSubject&&)                = default;

        IChangeSubject&             operator=(const IChangeSubject&)                = default;
        IChangeSubject&             operator=(IChangeSubject&&)                     = default;

        virtual std::size_t			GetChangeSubjectHint()                          {return GetDefaultHint();}

    private:
        std::size_t                 GetDefaultHint()                        const   {return typeid(*this).hash_code();}
    };
}

#endif //ICHANGESUBJECT_H