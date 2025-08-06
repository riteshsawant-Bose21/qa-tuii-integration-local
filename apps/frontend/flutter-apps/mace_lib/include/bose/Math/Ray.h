#pragma once
#ifndef RAY_H
#define RAY_H

#include "Vector.h"
#include "Matrix.h"

namespace bosepro::math
{
    /**
     * \class       Ray
     *
     * \brief       A portion of a line which starts at a point and goes off in a particular direction to infinity
     *
     * \details     Handy for hit testing
     *               This object is immutable sans cctor/mmtor and operator=
     */
    class Ray final
    {
    public:
                                Ray(Vec3 origin = {}, Vec3 direction = {}) noexcept
                                    : _origin(origin),
                                      _direction(direction.normalized())
                                {
                                }

                                Ray(const Ray&)        noexcept = default;
                                Ray(Ray&&)             noexcept = default;
                                ~Ray()                 noexcept = default;
        Ray&                    operator=(const Ray&)  noexcept = default;
        Ray&                    operator=(Ray&&)       noexcept = default;

        Vec3                    origin()    const noexcept {return _origin;}
        Vec3                    direction() const noexcept {return _direction;}

        Ray                     project(const Mat4& transform) const noexcept
                                {
                                    return Ray(transform * _origin, transform * _direction - transform * Vec3{0, 0, 0});
                                }
    private:
        Vec3                    _origin;
        Vec3                    _direction;
    };
}//bosepro::math

#endif //RAY_H