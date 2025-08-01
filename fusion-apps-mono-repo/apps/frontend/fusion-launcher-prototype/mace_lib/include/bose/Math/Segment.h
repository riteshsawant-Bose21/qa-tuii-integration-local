#pragma once
#ifndef SEGMENT_H
#define SEGMENT_H

#include <optional>
#include <vector>
#include <limits>

#include "Vector.h" // *not* the collection in std.
#include "Matrix.h"
#include "Ray.h"
#include "Orthogonal.h"

namespace bosepro::math
{ 
    /**
     * \class       Segment
     *
     * \brief       A portion of a line which starts at a point and ends at another point
     * \details     Handy for 2d edges in 3d space.
     *              This object is immutable sans cctor/mmtor and operator=
     *              Similar to Ray, will use with Plane
     */
    class Segment final
    {
    public:
                                Segment(Vec3 pointA = {}, Vec3 pointB = {}) noexcept
                                    : _pointA(pointA),
                                        _pointB(pointB)
                                {
                                }

                                Segment(const Segment&)                 noexcept = default;
                                Segment(Segment&&)                      noexcept = default;
                                ~Segment()                              noexcept = default;
        Segment&                operator=(const Segment&)               noexcept = default;
        Segment&                operator=(Segment&&)                    noexcept = default;

        bool                    operator==(const Segment& other) const noexcept
                                {
                                    return (_pointA == other._pointA &&
                                        _pointB == other._pointB  &&
                                        _type == other._type);
                                }

        bool                    operator!=(const Segment& other) const noexcept
                                {
                                    return !(*this == other);
                                }

        Vec3                    pointA()        const noexcept {return _pointA;}
        Vec3                    pointB()        const noexcept {return _pointB;}
        double                  length()        const noexcept { return std::abs((_pointB - _pointA).length()); }
        double                  lengthSquared() const noexcept { return std::abs((_pointB - _pointA).lengthSquared()); }
        Vec3                    directionAtoB() const noexcept { return (_pointB - _pointA).normalized(); }
        Vec3                    directionBtoA() const noexcept { return (_pointA - _pointB).normalized(); }
        Ray                     rayAB()         const noexcept { return Ray(_pointA, directionAtoB()); }
        Ray                     rayBA()         const noexcept { return Ray(_pointB, directionBtoA()); }
        Vec3                    middle()        const noexcept { return Vec3::lerp(_pointA, _pointB, .5); }

        Segment                 project(const Mat4& transform) const noexcept
                                {
                                    return Segment(transform * _pointA, transform * _pointB); // two points we can just apply transform.
                                }

        Segment                 zeroZ() const noexcept
                                {
                                    return Segment(Vec3(_pointA.x, _pointA.y, 0.0), Vec3(_pointB.x, _pointB.y, 0.0));
                                }

        Segment                 rotateYAroundA(Angle angle, Angle azimuthToBackout = Angle()) const noexcept
                                {
                                    // first version of this tried to be clever and auto remove azimuth (handling in 3d)
                                    // however, when doing multiple segments it can flip from one direction to another and
                                    // introduce errors, so instead pass in a fixed azimuth to back out for all segments.
                                    // must back out passed azimuth to correctly rotate on Y
                                    auto translateAToOrigin = Mat4::translation(-1.0 * _pointA);
                                    Mat4 backoutAzimuth;
                                    if (!math::isApproximatelyZero(azimuthToBackout.radians()) && !math::isApproximatelyEqual(std::abs(azimuthToBackout.radians()), math::DoublePi<>)) // not 0 or 360
                                    {
                                        backoutAzimuth = Mat4::rotation(0.0, 0.0, -1.0 * azimuthToBackout);
                                    }
                                    auto rotate = Mat4::rotation(0.0, angle, 0.0);
                                    // pt A doesn't rotate so it doesn't need any transforms
                                    auto MB = translateAToOrigin.inverse() * backoutAzimuth.inverse() * rotate * backoutAzimuth * translateAToOrigin;
                                    return Segment( _pointA, MB * _pointB);
                                }

                                /**
                                * This does line intersection, meaning the other segment is two points on a line.
                                * If you want to know if the two segments intersect with each other, test both ways
                                * e.g.  seg -- segOther |  
                                * if(seg.intersect(segOther, pt1) && segOther.intersect(seg, pt2)) // true if the two segments intersect with each other
                                */
        bool                    intersect(const Segment& line, Vec3& pt, bool onSegment = true, double tolerance = 1e-13) const
                                { 
                                    auto ret = false;
                                    // http://mathworld.wolfram.com/Line-LineIntersection.html
                                    // in 3d; will also work in 2d if z components are 0
                                    auto dirA = _pointB - _pointA; // x2 - x1
                                    auto dirB = line.pointB() - line.pointA(); // x4 - x3
                                    if (isApproximatelyZero(dirB.length()))
                                    {
                                        // if the provided segment is zero length then the point is likely already on the segment
                                        // to make sure, just use one of the points as the direction assuming 0,0,0 as the other point
                                        dirB = line.pointB();
                                    }
                                    auto dirC = line.pointA() - _pointA; // x3 - x1

                                    const auto crossAB = Vec3::cross(dirA, dirB);

                                    if (std::abs(0.0 - Vec3::dot(dirC, crossAB)) < tolerance ) // 4 points should be coplanar
                                    {
                                        if (!isApproximatelyZero(crossAB.lengthSquared())) // not parallel
                                        {
                                            auto s = SafeDivide(Vec3::dot(Vec3::cross(dirC, dirB), crossAB), crossAB.lengthSquared());
                                            auto near0 = std::abs(0.0 - s);
                                            auto near1 = std::abs(1.0 - s);
                                            if (!onSegment || 
                                                ((s > 0.0 || near0 < tolerance) &&
                                                (s < 1.0 || near1 < tolerance)) ) // we can get an intersection point anywhere OR we can constrain to our segment bounds.
                                            {
                                                s = (math::isApproximatelyZero(s)) ? 0.0 : s;
                                                pt = _pointA + s * dirA;
                                                ret = true;
                                            }
                                        }
                                    }
                                    return ret;
                                }

                                // convenience helper
        bool                    intersect(const math::Ray& ray, Vec3& pt, bool onSegment = true, bool testDirection = true, double tolerance = 1e-13)
                                {
                                    auto ret = false;
                                    Segment other(ray.origin(), ray.origin() + ray.direction());
                                    if (intersect(other, pt, onSegment, tolerance))
                                    {
                                        // because ray was given it has a direction.  if ray is opposite the segment to intersect, and client wants to respect a direction test
                                        // then check that origin to hit direction is same as ray direction.
                                        ret = true;
                                        if (testDirection)
                                        {                                            
                                            if (pt != ray.origin()) // edge case:  ray origin is hit point, in that case there's no direction.
                                            {
                                                auto dirToPoint = (pt - ray.origin()).normalized();
                                                ret = ray.direction().isNear(dirToPoint, tolerance);// use same tolerance on dir test.
                                            }                                         
                                        }
                                    }
                                    return ret;
                                }

        /**
        * \brief    In 3d there's an infinite number of valid normals.  This is a convenience helper to give you one of two.
        *           If you consider a segment -- a typical normal is to get |  this is the dir is edge == true behavior.
        *           Put another way, if direction is along X axis, you will get a normal on Z
        *           If dirIsEdge == false, then instead of Z you will get a normal on Y.
        *           This will cache the normal for possible future use.
        */
        Vec3                    getANormal(bool dirIsEdge = true) 
                                { 
                                    Vec3 normal;
                                    if (dirIsEdge)
                                    {
                                        if (_edgeNormal.has_value())
                                        {
                                            normal = *_edgeNormal;
                                        }
                                        else
                                        {
                                            normal = getOrthogonalToDirection(directionAtoB(), dirIsEdge);
                                            _edgeNormal = normal;
                                        }
                                    }
                                    else
                                    {
                                        if (_faceNormal.has_value())
                                        {
                                            normal = *_faceNormal;
                                        }
                                        else
                                        {
                                            normal = getOrthogonalToDirection(directionAtoB(), dirIsEdge);
                                            _faceNormal = normal;
                                        }
                                    }
                                    return normal;
                                }

        void                    setType(int32_t type) noexcept { _type = type; }
        int32_t                 getType()        const noexcept { return _type; }

        void                    setUserId(std::size_t id) { _userId = id; }
        std::size_t             getUserId() const { return _userId; }

        Vec3                    getClosestPoint(Vec3 origin) const { return (_pointB - origin).length() < (_pointA - origin).length() ? _pointB : _pointA; }
        Vec3                    getFurthestPoint(Vec3 origin) const { return (_pointA - origin).length() > (_pointB - origin).length() ? _pointA : _pointB; }

    private:
        Vec3                    _pointA;
        Vec3                    _pointB;
        std::optional<Vec3>     _edgeNormal; // optionally facillitate optimization, by storing the perpendicular direction in the segment to be reused.
        std::optional<Vec3>     _faceNormal;

        std::size_t             _userId{std::numeric_limits<std::size_t>::max()};

        int32_t                 _type{0}; // one use case is to set the surface type this segment was created from, but we don't want to have surface definitions in this class.

    };

    using                   Segments = std::vector<math::Segment>;

}//bosepro::math

#endif //SEGMENT_H
