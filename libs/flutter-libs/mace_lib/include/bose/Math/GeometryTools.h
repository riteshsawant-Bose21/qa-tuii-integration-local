#pragma once
#ifndef GEOMETRYTOOLS_H
#define GEOMETRYTOOLS_H

#include <algorithm>
#include <vector>
#include <cassert>
#include <optional>
#include "Matrix.h"
#include "Ray.h"
#include "Plane.h"
#include "Vector.h"
#include "Segment.h"
#include "Util/WarningDisable.h"

namespace bosepro::math
{
    /**
     * \class          GeometryDirection
     * \brief          Geometry direction options on a cartesian coordinate system: clockwise, counterclockwise, colinear
     */
    enum class GeometryDirection
    {
        Clockwise = 0,
        CounterClockwise = 1,
        Colinear = 2
    };

    /*
    \brief  Given a ray (which has origin and unit length direction),
            std::vector<Vec3> polygon vertices vertex0, vertex1, vertex2, ...
            compute if the ray hits the polygon's edges.
    \return If it hits, return true, and append to hits collection.
            If no hit, return false, and no hits
    */
    static inline bool CoplanarRayHitsPolygonEdges(const Ray& ray,
        const std::vector<Vec3>& vertices,
        std::vector<Vec3>& hits,
        bool testDirection = true,
        double tolerance = 1e-5 // 10 microns            
    )
    {
        // implementation simply using segment intersection
        // fewer edge cases to worry about.
        auto ret = false;
        hits.clear(); // ensure we start fresh.
        if (vertices.size() > 2) // triangles and up
        {
            auto testVal = Vec3::dot(ray.direction(), Vec3::cross((vertices.at(1) - vertices.at(0)).normalized(), (vertices.at(vertices.size() - 1) - vertices.at(0)).normalized()));
            auto coplanar = std::abs(testVal - 0.0) < tolerance;
            // test for coplanar, if not don't try to intersect.  
            if (coplanar)
            {
                // go through each edge to find out if any intersect with coplanar ray.
                for (std::size_t i = 0; i < vertices.size(); ++i)
                {
                    std::size_t plus1 = i + 1;
                    if (plus1 >= vertices.size())
                    {
                        plus1 = 0; // use first
                    }
                    auto segment = Segment(vertices.at(i), vertices.at(plus1));
                    Vec3 hit;
                    if (segment.intersect(ray, hit, true, testDirection, tolerance))
                    {
                        if (std::find(hits.begin(), hits.end(), hit) == hits.end()) // don't already have point. handles hitting a corner between two segments.
                        {
                            hits.push_back(hit); // simple.
                            ret = true;
                        }
                    }
                }
                // sort by length squared to ray origin for a consistent hit order.  we use squared simply to avoid having to take square roots, functionally same as sorting by length.
                std::sort(hits.begin(), hits.end(), [&ray](auto& a, auto& b){ return (a - ray.origin()).lengthSquared() < (b - ray.origin()).lengthSquared();});
            }
        }
        return ret;
    }

    /* 
    \brief  Given a ray origin, a unit length ray direction,
            three triangle vertices vertex0, vertex1, vertex2,
            compute if the ray hits the triangle.
    \return If it hits, return true, and fill in optional hit point and distance.
            If no hit, return false, and zero optional hit point and distance.
    */
    static inline bool RayIntersectsTriangle(const Vec3 & rayOrigin,
        const Vec3 & normalizedRayVector,
        const Vec3 & vertex0,
        const Vec3 & vertex1,
        const Vec3 & vertex2,
        Vec3 * outIntersectionPoint = nullptr,
        double * outDistance = nullptr
    )
    {
        // implement standard Möller–Trumbore intersection algorithm
        // https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm

        auto edge1 = vertex1 - vertex0;
        auto edge2 = vertex2 - vertex0;
        auto h = Vec3::cross(normalizedRayVector, edge2); // h perp to edge2 and to ray direction
        auto a = Vec3::dot(edge1, h);
        if (isApproximatelyZero(a))                     // is h is parallel to edge1?
            return false; // cannot hit

        auto f = 1 / a;
        auto s = rayOrigin - vertex0;
        auto u = f * (Vec3::dot(s, h));
        if (u < 0.0 || u > 1.0)
            return false;

        auto q = Vec3::cross(s, edge1);
        auto v = f * Vec3::dot(normalizedRayVector, q);

        if (v < 0.0 || u + v > 1.0)
            return false;

        // At this stage we can compute t to find out where the intersection point is on the line.
        auto t = f * Vec3::dot(edge2, q);

        // if behind ray or too close to origin of ray, no hit.
        if (t < 0.000001)
        {
            // This means that there is a line intersection but not a ray intersection.
            if (outDistance != nullptr) *outDistance = 0;
            if (outIntersectionPoint != nullptr) *outIntersectionPoint = { 0,0,0 };
            return false;
        }

        // ray hit. Compute intersection
        if (outDistance != nullptr)
            *outDistance = t;
        if (outIntersectionPoint != nullptr)
            *outIntersectionPoint = rayOrigin + normalizedRayVector * t;
        return true;
    }

    /** 
    \brief  Given a ray origin, a unit length ray direction,
            four quad vertices vertex0, vertex1, vertex2, vertex3,
            compute if the ray hits the quad.
            ASSUMES QUAD IS CONVEX! (cannot currently handle indented side quads)
    \return If it hits, return true, and fill in optional hit point and distance.
            If no hit, return false, and zero optional hit point and distance.
    */
    static inline bool RayIntersectsQuad(const Vec3 & rayOrigin,
        const Vec3 & normalizedRayVector,
        const Vec3 & vertex0,
        const Vec3 & vertex1,
        const Vec3 & vertex2,
        const Vec3 & vertex3,
        Vec3 * outIntersectionPoint = nullptr,
        double * outDistance = nullptr
    )
    {
        // this assumes quad points are numbered around the quad either clockwise or counter cw.
        // will still work with any corner as vertex0.
        // however, left to right, right to left, top to bottom or bottom to top numbering won't.
        // i.e.
        //  0   1       0   1
        //  3   2  ok   2   3  not ok

        // perf numbers on algorithm here:
        // http://graphics.cs.kuleuven.be/publications/LD05ERQIT/LD05ERQIT_paper.pdf
        // do one triangle
        if (RayIntersectsTriangle(rayOrigin,
            normalizedRayVector,
            vertex0,
            vertex1,
            vertex2,
            outIntersectionPoint,
            outDistance
        ))
            return true;
        // do a second, disjoint one
        if (RayIntersectsTriangle(rayOrigin,
            normalizedRayVector,
            vertex2,
            vertex3,
            vertex0,
            outIntersectionPoint,
            outDistance
        ))
            return true;
        return false;
    }

    /** 
    \brief  Given a ray origin, a unit length ray direction,
            sphere center and radius,
            compute if the ray hits the sphere.
    \return If it hits, return true, and fill in optional hit point and distance.
            If no hit, return false, and zero optional hit point and distance.
    */
    static inline bool RayIntersectsSphere(const Vec3 & rayOrigin,
        const Vec3 & normalizedRayVector,
        const Vec3 & sphereCenter,
        double sphereRadius,
        Vec3 * outIntersectionPoint = nullptr,
        double * outDistance = nullptr
    )
    {
        auto m = rayOrigin - sphereCenter;
        auto b = Vec3::dot(m, normalizedRayVector);
        auto c = Vec3::dot(m, m) - sphereRadius * sphereRadius;

        // check if origin outside sphere and pointing away from sphere
        if (c > 0.0 && b > 0.0)
            return false;

        // quadratic discriminant
        auto disc = b * b - c;

        // negative discriminant means ray missed sphere
        if (disc < 0.0)
            return false;

        // ray hits. Compute nearest t value via quadratic formula
        auto t = -b - sqrt(disc);

        // If t is negative, ray started inside sphere so clamp t to zero
        if (t < 0.0) t = 0.0;

        // ray hit. Compute intersection
        if (outDistance != nullptr)
            *outDistance = t;
        if (outIntersectionPoint != nullptr)
            *outIntersectionPoint = rayOrigin + normalizedRayVector * t;
        return true;
    }

    /** 
    \brief      Given a list of points in 3 space defining the ordered boundary of a polygon,
    \return     The area of the polygon.
    \comment    Assumes points are planar.
    */
    static inline double PolygonArea(const std::vector<Vec3> & points)
    {
        // algorithm is basically Stokes theorem
    // http://geomalgorithms.com/a01-_area.html

        auto len = points.size();
        if (len < 3)
            return 0;

        // normal
        const auto & p0 = points[0];
        const auto & p1 = points[1];
        const auto & p2 = points[2];

        auto normal = Vec3::cross(p0 - p1, p2 - p1);
        if (isApproximatelyZero(normal.length()))
            return 0; // no normal, fails an assumption

        // unit length
        normal = normal.normalized();

        // walk points applying stokes theorem
        Vec3 sum;
        for (std::size_t i = 0; i < len; ++i)
        {
            const auto & pA = points[i];
            const auto & pB = points[(i + 1) % len];
            sum = sum + Vec3::cross(pA, pB);
        }
        auto area = 0.5*Vec3::dot(normal, sum);
        return fabs(area);
    }

    /** 
    \brief  Find the closest distance between segment p1 -> p2 and segment q1 -> q2
    \return Optional points p and q on the respective segments where the hit occurs
    */ // TODO: this belongs in Segment class.
    static inline double SegmentToSegmentDistance(const Vec3 & p1, const Vec3 & p2, const Vec3 & q1, const Vec3 & q2, Vec3 * p = nullptr, Vec3 * q = nullptr)
    {   // adapted from algorithm http://geomalgorithms.com/a07-_distance.html#dist3D_Segment_to_Segment()
        // Copyright 2001 softSurfer, 2012 Dan Sunday
        // This code may be freely used, distributed and modified for any purpose
        // providing that this copyright notice is included with it.
        // SoftSurfer makes no warranty for this code, and cannot be held
        // liable for any real or imagined damage resulting from its use.
        // Users of this code must verify correctness for their application.

        // This avoids the case where someone is doing line to point with p1, p2 as the line and q1, q2 as the point as this does not account for this right now
        assert((q1 != q2) || ((p1 == p2) || (q1 == q2)));

        auto seg1dif = p2 - p1;
        auto seg2dif = q2 - q1;
        auto ptDif = p1 - q1;

        auto seg1dot = Vec3::dot(seg1dif, seg1dif); // always >= 0
        auto seg1_2dot = Vec3::dot(seg1dif, seg2dif);
        auto seg2dot = Vec3::dot(seg2dif, seg2dif); // always >= 0
        auto seg1ptDot = Vec3::dot(seg1dif, ptDif);
        auto seg2ptDot = Vec3::dot(seg2dif, ptDif);

        // discriminant
        auto D = seg1dot * seg2dot - seg1_2dot * seg1_2dot; // always >= 0

        // compute the line parameters of the two closest points
        auto sD = D; // sc = sN / sD, default sD = D >= 0
        auto tD = D; // tc = tN / tD, default tD = D >= 0

        double sN, tN;

        if (isApproximatelyZero(D))
        { // the lines are almost parallel
            sN = 0.0; // force using point P0 on segment S1
            sD = 1.0; // to prevent possible division by 0.0 later
            tN = seg2ptDot;
            tD = seg2dot;
        }
        else
        { // get the closest points on the infinite lines
            sN = (seg1_2dot*seg2ptDot - seg2dot * seg1ptDot);
            tN = (seg1dot*seg2ptDot - seg1_2dot * seg1ptDot);
            if (sN < 0.0)
            { // sc < 0 => the s=0 edge is visible
                sN = 0.0;
                tN = seg2ptDot;
                tD = seg2dot;
            }
            else if (sN > sD)
            { // sc > 1  => the s=1 edge is visible
                sN = sD;
                tN = seg2ptDot + seg1_2dot;
                tD = seg2dot;
            }
        }

        if (tN < 0.0)
        { // tc < 0 => the t=0 edge is visible
            tN = 0.0;
            // recompute sc for this edge
            if (-seg1ptDot < 0.0)
                sN = 0.0;
            else if (-seg1ptDot > seg1dot)
                sN = sD;
            else
            {
                sN = -seg1ptDot;
                sD = seg1dot;
            }
        }
        else if (tN > tD)
        { // tc > 1  => the t=1 edge is visible
            tN = tD;
            // recompute sc for this edge
            if ((-seg1ptDot + seg1_2dot) < 0.0)
                sN = 0;
            else if ((-seg1ptDot + seg1_2dot) > seg1dot)
                sN = sD;
            else
            {
                sN = (-seg1ptDot + seg1_2dot);
                sD = seg1dot;
            }
        }
        // finally do the division to get sc and tc
        auto sc = isApproximatelyZero(sN) ? 0.0 : sN / sD;
        auto tc = isApproximatelyZero(tN) ? 0.0 : tN / tD;

        // closest points:
        auto pp = p1 + sc * seg1dif;
        auto qq = q1 + tc * seg2dif;

        // get the difference of the two closest points
        auto dP = pp - qq;

        // output points
        if (p != nullptr)
            *p = pp;
        if (q != nullptr)
            *q = qq;

        return dP.length();
    }

    /**
    \brief  Get the linear distance between to points in space
    \param  p1  :   Point 1
    \param  p2  :   Point 2
    */
    static inline double PointToPointDistance(const Vec3& p1, const Vec3& p2)
    {
        // KA: this already exists in Vec3, length function
        return (p2 - p1).length();            
    }

    /**
    \brief  Get the linear distance between to points in space ignoring Z
    \param  p1  :   Point 1
    \param  p2  :   Point 2
    */
    static inline double PointToPointDistanceIgnoreZ(const Vec3& p1, const Vec3& p2)
    {
        auto p1NoZ = Vec3(p1.x, p1.y, 0.0);
        auto p2NoZ = Vec3(p2.x, p2.y, 0.0);
        return (p2NoZ - p1NoZ).length();
    }

    /**
    \brief  Find the closest distance between segment p1 -> p2 and point q
    \return Optional point p on the segment where the hit occurs
    */
    static inline double PointToSegmentDistance(const Vec3& p1, const Vec3 & p2, const Vec3 & q, Vec3 * p = nullptr)
    {
        return SegmentToSegmentDistance(q, q, p1, p2, nullptr, p);
    }

    /** 
    \briefsee   If ray intersects a cylinder with spherical endcaps
    \return     Approximate distance (distance to point of closest approach to cylinder axis)
    */
    static inline bool RayIntersectsCappedCylinder(
        const Vec3& rayOrigin,
        const Vec3& normalizedRayVector,
        const Vec3& p1,
        const Vec3& p2,
        double cylinderRadius,
        Vec3* outIntersectionPoint = nullptr,
        double* outDistance = nullptr)
    {
        // need ray to shoot pretty far. Get distances to endpoints and multiple
        auto d1 = (rayOrigin - p1).length();
        auto d2 = (rayOrigin - p2).length();
        auto d = std::max(d1, d2) * 10;

        auto q1 = rayOrigin;
        auto q2 = rayOrigin + normalizedRayVector * d;
        Vec3 p;
        auto dist = SegmentToSegmentDistance(p1, p2, q1, q2, &p);

        if (dist > cylinderRadius)
            return false; // no hit

                            // have a hit
        if (outIntersectionPoint != nullptr)
            *outIntersectionPoint = p;
        if (outDistance != nullptr)
            *outDistance = (rayOrigin - p).length();

        return true;
    }

    DISABLE_WARNING_PUSH
    DISABLE_WARNING_POTENTIAL_DIVIDE_BY_ZERO

    static inline void ClipSlab(double dir, double minVal, double maxVal, double val, double & tMin, double & tMax)
    {
        // NOTE: DO NOT CHECK THIS FOR ZERO - IS DESIGNED TO WORK CORRECTLY WITH 0 UNDER IEEE RULES
        // This is designed to handle +- 0 IEEE floating point, which a direct test fails to catch!
        // in zero cast returns +- infinity as needed, and other comparisons work fine
        auto div = 1/dir;

        if (div >= 0)  // note - handles infinity cases also
        {
            tMin = (minVal - val) * div;
            tMax = (maxVal - val) * div;
        }
        else
        {
            tMin = (maxVal - val) * div;
            tMax = (minVal - val) * div;
        }
    }
    DISABLE_WARNING_POP

    /**
    \brief  Given a segment defined by two endpoints, and a box, clip the segment to the inside of the box
            the box is defined by a  min corner and max corner, where minCorner.W <= maxCorner.W for W = {X,Y,Z}
    \return True is anything is inside the box, which updates the points p1 and p2.
            If nothing is nothing is left inside, p1 and p2 unchanged, and returns false
    */
    static inline bool ClipSegmentToBox(Vec3& p1, Vec3& p2, const Vec3& minCorner, const Vec3& maxCorner)
    {
        // Smits’ method, with improvements from "An Efficient and Robust Ray–Box Intersection Algorithm" by Williams, Barrus, Morley, and Shirley

        // parametrize the line segment p1 -> p2 by
        // L(t) = p1 + (p2-p1)* t
        // as t goes 0-1, line goes p1 to p2
        // thus we want clips in t in 0,1

        auto dir = p2 - p1;
        double tmin, tmax, tymin, tymax, tzmin, tzmax;

        ClipSlab(dir.x, minCorner.x, maxCorner.x, p1.x, tmin, tmax);

        // early bailout
        if (tmax < 0 || 1 < tmin)
            return false;

        ClipSlab(dir.y, minCorner.y, maxCorner.y, p1.y, tymin, tymax);

        // early bailout
        if (tymax < 0 || 1 < tymin)
            return false;
        if (tmin > tymax || tymin > tmax)
            return false;

        // keep min values
        if (tymin > tmin)
            tmin = tymin;
        if (tymax < tmax)
            tmax = tymax;

        ClipSlab(dir.z, minCorner.z, maxCorner.z, p1.z, tzmin, tzmax);

        // early bailout
        if (tzmax < 0 || 1 < tzmin)
            return false;
        if ((tmin > tzmax) || (tzmin > tmax))
            return false;

        // get total bounds
        if (tzmin > tmin)
            tmin = tzmin;
        if (tzmax < tmax)
            tmax = tzmax;

        if (tmin <= 1 && 0 <= tmax)
        {
            // intersects. Clamp to 0,1 first
            if (tmin < 0) tmin = 0;
            if (1 < tmax) tmax = 1;

            p2 = p1 + dir * tmax;
            p1 = p1 + dir * tmin;
            return true;
        }

        return false;
    }

    /**
    * \brief   Get the comparison result of v1 and v2 based on the quadrant of both points
                                    Z ^
                            Q2      |      Q1
                    ->              |                      \
                    /                 |                       |
                |      ------------+------------> X        |
                |          Q3      |      Q4              /
                    \                 |                   <-
                                    |
                    So the quadrants order is Q1, Q4, Q3, Q2

    * \param   x1 : x of first vector
                y1 : y of first vector
                x2 : x of second vector
                y2 : y of second vector
    * \return bool : v1 < v2 in the orthogonal plane
    */
    static inline bool PlaneComparer(const double x1, const double y1, const double x2, const double y2)
    {
        constexpr int QUADRANT1 = 4;
        constexpr int QUADRANT2 = 1;
        constexpr int QUADRANT3 = 2;
        constexpr int QUADRANT4 = 3;

        int q1;
        int q2;

        if (x1 >= 0.0)
        {
            if (y1 >= 0.0)
                q1 = QUADRANT1;
            else //y1 < 0.0
                q1 = QUADRANT4;
        }
        else //x1 < 0.0
        {
            if (y1 >= 0.0)
                q1 = QUADRANT2;
            else //y1 < 0.0
                q1 = QUADRANT3;
        }

        if (x2 >= 0.0)
        {
            if (y2 >= 0.0)
                q2 = QUADRANT1;
            else //y2 < 0.0
                q2 = QUADRANT4;
        }
        else //x2 < 0.0
        {
            if (y2 >= 0.0)
                q2 = QUADRANT2;
            else //y2 < 0.0
                q2 = QUADRANT3;
        }

        if (q1 != q2)
            return q1 < q2;
        else
        {
            if ((q1 == QUADRANT1) || (q1 == QUADRANT4))
            {
                if (math::isApproximatelyEqual(y1, y2))
                    return x1 < x2;
                else
                    return y1 < y2;
            }
            else //if ((q1 == QUAD2) || (q1 == QUAD3))
            {
                if (math::isApproximatelyEqual(y1, y2))
                    return x1 < x2;
                else
                    return y1 > y2;
            }
        }
    }

    /**
    * \brief   Get the arc length of the generated arc by the chord and angle
    * \param    chordLength
    *           centralAngle
    * \return double : arc length
    */
    static inline double GetArcLength(const double chordLength, const Angle centralAngle)
    {
        double centralAngleRad = centralAngle.radians();
        double sinCalc = 2 * std::sin(centralAngleRad / 2);
            
        if (sinCalc == 0.0)
            return chordLength;

        double arcLength = (centralAngleRad * chordLength) / (sinCalc);
        return arcLength;
    }

    /**
    * \brief    Get the radius of the circle generated by the given chord length and the angle
    * \param    chordLength
    *           centralAngle   
    * \return double : circle radius
    */
    static inline double GetCircleRadius(const double chordLength, const Angle centralAngle)
    {
        double centralAgnleRad = centralAngle.radians();
        double sinCalc = std::sin(centralAgnleRad / 2);
            
        if (sinCalc == 0)
            return chordLength;

        double radius = chordLength / (2 * sinCalc);
        return radius;
    }

    /**
    * \brief    Get the central angle given a radius of a circle and a chord length
    * \param    chordLength
    */
    static inline Angle GetCentralAngle(const double radius, const double chordLength)
    {
        // we could use law of cosines since we know three sides of the isoceles triangle (radius is two sides)
        // however, it's less operations to just use arc sin and 1/2 the chord. (opposite over hypot)
        // 2x that angle gives us the central angle.
        Angle angle;
        if (!isApproximatelyZero(radius) && !isApproximatelyZero(chordLength))
        {
            angle = 2 * std::asin(SafeDivide(chordLength*.5, radius));
        }
        return angle;
    }

    /**
    \brief  Return the Y coordinate corresponding the provided X of the line - anywhere in the infinite line defined by (x1, y1) and (x2, y2).
    \param  x1 : The X coordinate of point 1
    \param  y1 : The Y coordinate of point 1
    \param  x2 : The X coordinate of point 2
    \param  y2 : The Y coordinate of point 2
    \param  x  : The X coordinate of the sought point's Y
    \return double  : The Y coordinate seeked by X
    */
    static inline double GetLinearFunctionY(const double x1, const double y1, const double x2, const double y2, const double x)
    {
        double y;

        if (isApproximatelyEqual(x1, x2))
        {
            y = y2;
        }
        else
        {
            double m = (y2 - y1) / (x2 - x1);
            y = m * (x - x1) + y1;
        }

        return y;
    }

    /**
    \brief  Return the linear distance between the line (x1, y1) and (x2, y2)
    \param  x1 : The X coordinate of point 1
    \param  y1 : The Y coordinate of point 1
    \param  x2 : The X coordinate of point 2
    \param  y2 : The Y coordinate of point 2
    */
    static inline double GetLinearLength(const double x1, const double y1, const double x2, const double y2)
    {
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    /**
    \brief  Get the coordinates of the intersection between the two lines created between line 1 (x11, y11), (x12, y12) 
            and line 2 (x21, y21), (x22, y22).
    \param  x11 :   The X coordinate of point 1 of line 1
    \param  y11 :   The Y coordinate of point 1 of line 1
    \param  x12 :   The X coordinate of point 2 of line 1
    \param  y12 :   The Y coordinate of point 2 of line 1
    \param  x21 :   The X coordinate of point 1 of line 2
    \param  y21 :   The Y coordinate of point 1 of line 2
    \param  x22 :   The X coordinate of point 2 of line 2
    \param  y22 :   The Y coordinate of point 2 of line 2
    \param  x (OUT) :   The X coordinate of the intersection point (if such)
    \param  y (OUT) :   The Y coordinate of the intersection point (if such)
    \return True if the lines intersect, false otherwise (parallel).
    */
    static inline bool GetIntersectingPoint(const double x11, const double y11, const double x12, const double y12,
                                        const double x21, const double y21, const double x22, const double y22,
                                        double& x, double& y)
    {
        x = 0.0;
        y = 0.0;
            
        if (isApproximatelyEqual(x11, x12) && isApproximatelyEqual(x21, x22))
            return isApproximatelyEqual(x11, x21);

        double m1 = 0.0;
        double c1 = x12;
        if (!isApproximatelyEqual(x11, x12))
        {
            m1 = (y12 - y11) / (x12 - x11);
            c1 = y11 - m1 * x11;
        }

        double m2 = 0.0;
        double c2 = x21;
        if (!isApproximatelyEqual(x21, x22))
        {
            m2 = (y22 - y21) / (x22 - x21);
            c2 = y22 - m2 * x22;
        }

        if (isApproximatelyEqual(m1, m2))
            return isApproximatelyEqual(c1, c2);    //if no intersection, the lines are parallel
            
        x = (c2 - c1) / (m1 - m2);
        y = m1 * x + c1;
        return true;
    }

    /**
    \brief  Get a point to the provided point that is mirrored along the symmetry axis described by the line y = mx + b on the Z axis.
    \param  point   :   The point to be mirrored
    \param  m       :   The slope of the symmetry axis
    \param  b       :   b = y - mx
    */
    static inline Vec3 GetMirrorPointToSymmetryXZAxis(const Vec3& point, double m, double b)
    {
        if (isnan(m))
            return { point.x - 2 * (point.x - b), 0.0, point.z };
        else if (m == 0)
            return { point.x, 0.0, point.z - 2 * (point.z - b) };

        //y = mx + b
        //Find intersection point to mirror across (xi, 0.0, zi)
        double m2 = -1 / m;
        double b2 = point.z - m2 * point.x;

        double xi = (b2 - b) / (m - m2);
        double zi = m * xi + b;
        Vec3 intersectionPoint = { xi, 0.0, zi };

        Vec3 pointVector = point - intersectionPoint;
        Vec3 mirrorPointVector = -pointVector;

        Vec3 mirrorPoint = mirrorPointVector + intersectionPoint;

        return mirrorPoint;
    }

    /**
    \fn     Is2DPointNearLine
    \brief  Is the provided point on a line described by two points.
    \param  ax
    \param  ay
    \param  bx
    \param  by
    \param  tx
    \param  ty
    \param  tolerance
    */
    template <typename T>
    static inline bool Is2DPointNearLine(T ax, T ay, T bx, T by, T tx, T ty, const double tolerance = 0.01)
    {            
        // compute initial slope given the two points.
        const double boundingSlope = math::SafeDivide((by - ay), (bx - ax));            

        const double compareSlope = math::SafeDivide((ty - ay), (tx - ax));
        return (std::abs(compareSlope - boundingSlope) <= tolerance);            
    }

    /**
    \brief  Calculate the distance betwen a point to a line
    \param  startPoint  : The start of the line in global coordinates
    \param  endPoint    : The end of the line in global coordinates
    \param  refPoint    : The reference point to calculate the distance from it to the line in global coordinates
    \note   The point coordinates do not have to be all in global space, but they do have to be all in the same place to get correct distance
    \return The perpendicular distance between the line and the point
    */
    static inline double CalculatePerpendicularDistanceXZ(const Vec3& startPoint, const Vec3& endPoint, const Vec3& refPoint)
    {
        double perpendicularDistance = 0.0;

        if (startPoint == endPoint)
            return perpendicularDistance;

        Vec3 startPointRef = startPoint - refPoint;
        Vec3 endPointRef = endPoint - refPoint;

        if (isApproximatelyEqual(startPointRef.x, endPointRef.x))         //Parallel to Y axis
            perpendicularDistance = startPointRef.x;
        else if (isApproximatelyEqual(startPointRef.z, endPointRef.z))    //Parallel to Z axis
            perpendicularDistance = startPointRef.z;
        else
        {
            double a = startPointRef.z - endPointRef.z;     //z1 - z2
            double b = endPointRef.x - startPointRef.x;     //x2 - x1
            double c = startPointRef.x * endPointRef.z - startPointRef.z * endPointRef.x;       //(x1 * z2) - (x2 * z1)
            perpendicularDistance = std::abs(c) / std::sqrt(a * a + b * b);
        }

        return perpendicularDistance;
    }

    /**
    \brief  Rotates points on XY plane around a specific point
    \note   §rotate2d.m
    \param  rotatePointX    :   The X coordinate of the point to rotate
    \param  rotatePointY    :   The Y coordinate of the point to rotate
    \param  rotateAroundX   :   The X coordinate of the point to rotate around (center)
    \param  rotateAroundY   :   The Y coordinate of the point to rotate around (center)
    \param  rotation        :   The rotation angle in radians positive is towards -Z
    */
    static inline std::pair<double, double> rotateAroundPoint2D(const double rotatePointX, const double rotatePointY, const double rotateAroundX, const double rotateAroundY, const Angle rotation)
    {
        // Trying to do y-based rotation (with passed X as X and passed Y (which is Z) as Z.
        // Didn't get correct results for resulting splay angles.
        // But, doing z-based worked and matches numbers from hand coded matrices in original implementation.

        // Z-based rotation.  use as XY with 0 Z
        Mat4 a = Mat4::translation(Vec3(rotateAroundX, 0.0, rotateAroundY));
        Mat4 b = Mat4::rotation(0.0, rotation, 0.0);
        Mat4 c = a.inverse();//Mat4::translation(Vec3(-rotateAroundX, 0.0, -rotateAroundY));

        Mat4 M = a * b * c;
        Vec3 point{rotatePointX, 0.0, rotatePointY};
        auto rotatedPoint = M * point;

        return {rotatedPoint.x, rotatedPoint.z};
    }

    /**
    \brief  Get the angle between two provided points in 3D relative to X axis
    \       Assumes positive is down towards ground.  Similar to pitch.
    \param  point1
    \param  point2
    \return Angle   :   the angle between point1 and point 2.
    \details Handles up to but not including +/- 180.  
    */
    static inline Angle getXAngleBetweenPoints(const Vec3& pointref1, const Vec3& pointref2, Angle azimuthToBackout = Angle())
    {
        auto translate1ToOrigin = Mat4::translation(-1.0 * pointref1);
        Mat4 backoutAzimuth;
        if (!math::isApproximatelyZero(azimuthToBackout.radians()) && !math::isApproximatelyEqual(std::abs(azimuthToBackout.radians()), math::DoublePi<>)) // not 0 or 360
        {
            backoutAzimuth = Mat4::rotation(0.0, 0.0, -1.0 * azimuthToBackout);
        }

        auto point1 = translate1ToOrigin * pointref1;
        auto point2 = backoutAzimuth * translate1ToOrigin * pointref2;

        Angle angle; // could be 0 if two points are the same.
        Vec3 point2Direction = (point2 - point1);
        
        // avoid weird issues if a tiny negative # close to 0
        point2Direction = Vec3(math::isApproximatelyZero(point2Direction.x) ? 0.0 : point2Direction.x,
                               math::isApproximatelyZero(point2Direction.y) ? 0.0 : point2Direction.y,
                               math::isApproximatelyZero(point2Direction.z) ? 0.0 : point2Direction.z);

        std::optional<Angle> azimuth;
        std::optional<Angle> elevation;
        double radius = 0.0;
        if (point2Direction.directionToSphericalCoordinates(radius, azimuth, elevation, true))
        {
            // NOTE: either we backed out yaw... or the starting azimuth is 0. However, azimuth could flip which indicates we have gone past +/- 90            
            if (azimuth && (isApproximatelyEqual(std::abs((*azimuth).radians()), math::pi)))
            {
                if (*elevation > 0)
                {
                    angle = *elevation - math::pi; // handle -90.5 and so on.
                }
                else
                {
                    angle = math::pi + *elevation; // handle 90.5 and so on.
                }
            }
            else
            {
                angle = -1 * *elevation;
            }
        }
        return angle;
    }

    /**
    \fn     DistanceFromPolylineAtLength
    \brief  alternate method to DistanceFromPolyline. Uses the length and interpolation results with less computation.
    \param  polyline
    \param  point
    \param  length
    */
    static inline double DistanceFromPolylineAtLength(const std::vector<Vec3>& polyline, const Vec3& point, double length)
    {
        // difference from DistanceFromPolyline is that this uses the actual length to get the exact point to calculate
        // a distance from.  Needed to determine an accurate gain adjustment.
        double result = std::numeric_limits<double>::max();

        //Check each segment in the polyline, polyline is collection of vec3s so starting with index 1 gives us first segment.
        double curTotalLength = 0;
        // walk all segments until length is in range.
        for (std::size_t index = 1; index < polyline.size(); ++index)
        {
            Vec3 currentPoint = polyline.at(index);
            Vec3 previousPoint = polyline.at(index - 1);

            auto segLength = Vec3::distance(currentPoint, previousPoint);
            auto startLength = curTotalLength;
            curTotalLength += segLength;
                
            if (curTotalLength < length) // not in range of segment yet.
            {
                continue;
            }
            if (startLength > length)
            {
                break; // we are past
            }

            // if we get here we are >= segment
            if (math::Between(length, startLength, curTotalLength))
            {
                // it's less math to simply interpolate on the line to get the point at the same length
                // and then do a distance than it is to do the segment to segment thing.
                auto delta = length - startLength;
                auto fraction = math::SafeDivide(static_cast<double>(delta), segLength);
                // get interpolated point on segment to get distance
                auto ptOnSegment = Vec3::lerp(previousPoint, currentPoint, fraction);
                result = Vec3::distance(point, ptOnSegment);
                break;
            }
        }
        return result;
    }

        
    static inline double DistanceFromPolyline(const std::vector<Vec3>& polyline, const Vec3& point)
    {
        double result = std::numeric_limits<double>::max();

        //Check each segment in the polyline
        for (std::size_t index = 1; index < polyline.size(); ++index)
        {
            Vec3 currentPoint = polyline.at(index);
            Vec3 previousPoint = polyline.at(index - 1);

            double segmentDistance = PointToSegmentDistance(currentPoint, previousPoint, point);
            result = std::min(segmentDistance, result);
        }

        return result;
    }

    static inline double DistanceFromPolyline2(const std::vector<Vec3>& polyline, const Vec3& point)
    {
        // alternate impl using plane
        const auto maxDouble = std::numeric_limits<double>::max();
        double result = maxDouble;

        Plane pTest;        

        //Check each segment in the polyline
        for (std::size_t index = 1; index < polyline.size(); ++index)
        {
            Vec3 currentPoint = polyline.at(index);
            Vec3 previousPoint = polyline.at(index - 1);

            Segment seg(previousPoint, currentPoint);
            auto direction = seg.directionAtoB();
            Vec3 k1 = currentPoint; // if we have no direction on polyline cur/prev, then just use the point.

            if (!isApproximatelyZero(direction.length()))
            {
                pTest = Plane(Ray(previousPoint, direction), true);
                k1 = pTest.perpendicularPoint(point);
            }
            double segmentDistance = (k1 - point).length();            
            Vec3 ptDummy;
            if (segmentDistance < result && (isApproximatelyZero(seg.length()) || seg.intersect(Segment(point, k1), ptDummy)))
            {
                result = segmentDistance;
            }
            // handle not found
            if (isApproximatelyEqual(result, maxDouble) && index == polyline.size() - 1)
            {
                // is the point before or after the polyline?
                // test for before if that's false, then it's after.
                // depending on which (before or after) we'll just take the simple linear distance to the end point.
                // testing if before in 3d.  pt   A + - + - + - B
                // pt - A length is < pt - B length
                auto pa = (point - polyline.front()).length();
                auto pb = (point - polyline.back()).length();
                result = pb;
                if (pa < pb)
                {
                    result = pa;
                }
            }
        }
        return result;
    }


    /**
    * \brief find start/end ix and end points for ideal keel given two points specifying the range
    */
    static inline std::pair<std::size_t, std::size_t> GetPolylineRange(const std::vector<Vec3>& polyline, const std::pair<Vec3, Vec3> inPoints, std::pair<Vec3, Vec3>& outPoints)
    {
        // find where point1 and point2 are closest
        double result1 = std::numeric_limits<double>::max();
        double result2 = result1;
        std::pair<std::size_t, std::size_t> found = {0,0};        

        auto point1 = inPoints.first;
        auto point2 = inPoints.second;

        if (polyline.size() > 0)
        {
            // which point is closest to start of ideal keel?
            // whatever that is is the start
            auto& firstPoint = polyline.at(0);
            if ((point1 - firstPoint).length() > (point2 - firstPoint).length())
            {
                // reversed.
                point2 = point1;
                point1 = inPoints.second;
            }

            //Check each segment in the polyline
            // do two passes, 1st to find start, then once we have that apply translate such that bottom perp point is more accurate
            // if start ix provided go up from it until we exceed segment
            Plane pTest;
            for (std::size_t index = 1; index < polyline.size(); ++index)
            {
                Vec3 currentPoint = polyline.at(index);
                Vec3 previousPoint = polyline.at(index - 1);
                Segment seg(previousPoint, currentPoint);
                auto direction = seg.directionAtoB();
                Vec3 k1 = currentPoint; // if we have no direction on polyline cur/prev, then just use the point.

                if (!isApproximatelyZero(direction.length()))
                {
                    pTest = Plane(Ray(previousPoint, direction), true);
                    k1 = pTest.perpendicularPoint(point1);
                }

                double segmentDistance1 = (k1 - point1).length();
                Vec3 ptDummy;
                if (segmentDistance1 < result1 && (isApproximatelyZero(seg.length()) || seg.intersect(Segment(point1, k1), ptDummy)))
                {
                    found.first = index - 1;
                    result1 = std::min(segmentDistance1, result1);
                    outPoints.first = k1;                    
                }
                else if (index == 1 && segmentDistance1 < result1)
                {
                    // handle first index, if intersection is before beginning, then just use 0 as start.
                    if (seg.intersect(Segment(point1, k1), ptDummy, false))
                    {
                        // see if ptDummy if < seg.pointA()
                        if (seg.getClosestPoint(ptDummy) == previousPoint)
                        {
                            found.first = index - 1;
                            result1 = std::min(segmentDistance1, result1);
                            outPoints.first = k1;
                        }
                    }
                }
                else if (segmentDistance1 > result1)
                {
                    break; // once distance goes up we are done finding
                }
            }

            // 2nd loop for end, we can start at first ix            
            auto translate4Start = Mat4::translation(outPoints.first - point1);
            // rather than translate poly line, translate point2 then correct point on polyline is returned at the right distance.
            point2 = translate4Start * point2;

            std::size_t startIx = std::max(found.first, static_cast<std::size_t>(1));
            for (std::size_t index = startIx; index < polyline.size(); ++index)
            {
                Vec3 currentPoint = polyline.at(index);
                Vec3 previousPoint = polyline.at(index - 1);
                Segment seg(previousPoint, currentPoint);
                auto direction = seg.directionAtoB();
                Vec3 k2 = currentPoint;

                if (!isApproximatelyZero(direction.length()))
                {
                    pTest = Plane(Ray(previousPoint, direction), true);                    
                    k2 = pTest.perpendicularPoint(point2);
                }
                                
                Vec3 ptDummy;                
                double segmentDistance2 = (k2 - point2).length();
                if (segmentDistance2 < result2 && (isApproximatelyZero(seg.length()) || seg.intersect(Segment(point2, k2), ptDummy)))
                {
                    found.second = index - 1;
                    result2 = std::min(segmentDistance2, result2);
                    outPoints.second = k2;
                }
                // once k2 is past segment we are done searching
                else if (segmentDistance2 > result2)
                {
                    break; // once distance goes up we are done finding
                }
                if (found.second < found.first && index == polyline.size() - 1 && segmentDistance2 < result2)
                {
                    // just use last point that mapped on plane to extend
                    found.second = index;
                    result2 = std::min(segmentDistance2, result2);
                    outPoints.second = k2;
                }
            }
        }
        return found;
    }

    /**
 * \fn			Is2dColinear
 * \brief		utility function, points in same 2d view (ignores Z)
 * \return		true/false if points are in line
 */
    static bool Is2dColinear(const std::vector<Vec3>& points) noexcept
    {
        auto ret = false;
        // simple algebra.  y = mx + b
        // get first point and last point, ignore z.
        // compute the slope of the line, then check if each point is on same line.
        // Was created to check if points provided for level over distance are in a line.
        if (points.size() == 2) // if we only have 2 points of course everything is on same line!
        {
            ret = true;
        }
        else if (points.size() > 2) // for this, all points must be on same line.
        {
            // compute initial slope given the two outer points.
            auto pt1 = points.begin();
            auto pt2 = points.rbegin();
            if (pt1 != points.end() && pt2 != points.rend())
            {                
                const double boundingSlope = math::SafeDivide((pt2->y - pt1->y), (pt2->x - pt1->x));
                const double tolerance = .01;
                // test all other points.
                ret = true;
                for (std::size_t ix = 1; ix < (points.size() - 1); ++ix)
                {
                    const double compareSlope = math::SafeDivide((points.at(ix).y - pt1->y), (points.at(ix).x - pt1->x));
                    if (std::abs(compareSlope - boundingSlope) > tolerance)
                    {
                        ret = false;
                        break; // not colinear!
                    }
                }
            }
        }
        return ret;
    }
} // namespace bosepro::math
#endif // GEOMETRYTOOLS_H
