#pragma once
#ifndef DXFFACE_H
#define DXFFACE_H

#include <utility>
#include <vector>
#include "Math/MathUtils.h"


namespace bosepro::hardware
{
    class DXFFace;
    using DXFFaces                  = std::vector<DXFFace>;

    /**
     * \class       DXFFace
     *
     * \brief       Represents a face consisting of 4 vertices
     *
     * \details     The desired visibility of the 4 edges is indicated via a flag, see isFlagSet().
     */
    class DXFFace
    {
    public:
        using Vertices              = std::vector<math::Vec3>;

                                    DXFFace(Vertices v, unsigned int flags)
                                        : m_Flags(flags),
                                            m_Verts(std::move(v))
                                    {
                                    }

        virtual                     ~DXFFace()                  = default;
                                    DXFFace()                   = default;
                                    DXFFace(const DXFFace&)     = default;
                                    DXFFace(DXFFace&&)          = default;
        DXFFace&                    operator=(const DXFFace&)   = default;
        DXFFace&                    operator=(DXFFace&&)        = default;

        inline friend bool          operator!=(const DXFFace& lhs, const DXFFace& rhs) {return !(lhs == rhs);}
        inline friend bool          operator==(const DXFFace& lhs, const DXFFace& rhs)
                                    {
                                        bool equal = false;

                                        if(lhs.m_Flags == rhs.m_Flags && lhs.m_Verts.size() == rhs.m_Verts.size())
                                        {
                                            equal = true;

                                            for(unsigned int i = 0; i < lhs.m_Verts.size(); ++i)
                                            {
                                                if(lhs.m_Verts[i] != rhs.m_Verts[i])
                                                {
                                                    equal = false;
                                                    break;
                                                }
                                            }
                                        }

                                        return equal;
                                    }

        enum class                  Flag{Edge1Visible = 0x1,            //Render edge v0 -> v1 only if bit is set 
                                            Edge2Visible = 0x2,            //Render edge v1 -> v2 only if bit is set
                                            Edge3Visible = 0x4,            //Render edge v2 -> v3 only if bit is set
                                            Edge4Visible = 0x8};           //Render edge v3 -> v0 only if bit is set

        inline void                 setFlags(unsigned int val)          {m_Flags = val;}
        inline unsigned int         getFlags() const                    {return m_Flags;}
        inline bool                 isFlagSet(Flag e) const             {return (static_cast<unsigned>(e) & m_Flags) == 0;}

        inline void                 setVertices(Vertices v)             {m_Verts = std::move(v);}
        inline const Vertices&      getVertices() const                 {return m_Verts;}        

    protected:
        unsigned int                m_Flags;

        Vertices                    m_Verts;
    };
}//bosepro::hardware

#endif //DXFFACE_H