#pragma once
#ifndef UID_H
#define UID_H

#include <cassert>
#include <atomic>
#include <limits>
#include <algorithm>
#include <vector>


namespace bosepro
{
    /**
     * \class       Uid
     *
     * \brief       Unique id base class
     *
     * \details     Thread safe
     *               A new id is only generated on construction, copy construction and copy assignment
     *               Will auto wrap to 0 at 18446744073709551615
     *               Which is Eighteen quintillion, four hundred forty-six quadrillion, 
     *               seven hundred forty-four trillion, seventy-three billion, seven hundred nine million, 
     *               five hundred fifty-one thousand, six hundred fifteen
     *               In seconds this is 586,549,402,018 years, 3 weeks, 3 days, 15 hours, 30 minutes, 7 seconds.
     *               So no, we are not concerned with this wrapping within any possible call volume.
     */
    class Uid
    {
    public:
		using Ids													= std::vector<uint64_t>;
        static constexpr auto NOID                                          = 0ull;
        virtual                     ~Uid()                                  = default;
                                    Uid()                                   : _id(getNextId()){}
                                    Uid(const Uid&)                         : Uid(){}
                                    Uid(Uid&& other)            noexcept    : Uid(){swap(*this, other);}
        Uid&                        operator=(Uid&& other)      noexcept    {swap(*this, other); return *this;}
        Uid&                        operator=(const Uid& other)             {auto tmp(other); swap(*this, tmp); return *this;}

        inline uint64_t             getId()               const noexcept    {return _id;}

    protected:
        static uint64_t             getNextId()                 noexcept
                                    {
                                        // 0 is NOID, meaning a way caller can test if not created.
                                        static std::atomic<uint64_t> id(1); 

                                        if(id == std::numeric_limits<uint64_t>::max())
                                        {
                                            //wow!
                                            assert(0);
                                            id = 0;
                                        }

                                        return id++;
                                    }

        inline friend void          swap(Uid& lhs, Uid& rhs) noexcept
                                    {
                                        std::swap(lhs._id, rhs._id);
                                    }

    private:
        uint64_t                    _id;
    };

}//bosepro

#endif //UID_H