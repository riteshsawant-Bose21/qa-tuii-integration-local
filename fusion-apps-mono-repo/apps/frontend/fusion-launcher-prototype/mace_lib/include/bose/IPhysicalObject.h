#pragma once
#ifndef PHYSICAL_OBJECT_H__
#define PHYSICAL_OBJECT_H__

#include "Math/BBox.h"

namespace bosepro::hardware
{
    class IPhysicalObject
    {
    public:
        virtual ~IPhysicalObject() {} // one might think just having destructor, rule of 5 might apply where a derived class cannot be moved/copied, 
                                      // however, as this is a fully abstract class, tests of a derived class using the std::is_copy_constructible, etc. all pass! (easier via AssertHelpers.h macros IS_COPY, IS_CCTOR, IS_MOVE, IS_MCTOR etc.)
        virtual math::BBox	getBounds()     const = 0; //Local space

        virtual double		getWeight()     const = 0; //kg
        virtual double		getHeight()     const = 0; //meters
        virtual double		getWidth()      const = 0; //meters
        virtual double		getDepth()      const = 0; //meters
    };
}

#endif //PHYSICAL_OBJECT_H__
