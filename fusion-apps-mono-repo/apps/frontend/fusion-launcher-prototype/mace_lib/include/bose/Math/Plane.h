#pragma once
#ifndef PLANE_H
#define PLANE_H

#include <optional>
#include "Vector.h"
#include "Ray.h"
#include "Matrix.h"
#include "Segment.h"
#include "Orthogonal.h"

namespace bosepro::math
{
    /**
     * \class   Plane
     *
     * \brief   A 2D plane in 3D space. Is a flat, two-dimensional surface that extends infinitely far.
     *          A plane in 3D coordinate space is determined by a point and a vector that is perpendicular (orthogonal) to the plane
     *          Handy for intersection
     *          This object is immutable sans cctor/mctor and operator=
     */
    class Plane final
    {
    public:
                        Plane(Vec3 point = {}, Vec3 normal = {}) noexcept
                        : _point(point),
                        _orthogonalDirection(normal.normalized())
                        {
                        }

                        Plane(Vec3 pointRef, Vec3 point2, Vec3 point3)
                        {
                            // 3 point version.  1st point is a reference point, next two are the segments of a line.
                            // we will create an orthogonal direction from the cross product between pt3 - pt2 and ptRef - pt2
                            auto lineDirNormal = (point3 - point2).normalized();
                            auto refToLineDirNormal = (pointRef - point2).normalized();
                            _orthogonalDirection = Vec3::cross(lineDirNormal, refToLineDirNormal).normalized();
                            if (math::isApproximatelyZero(_orthogonalDirection.length()))
                            {
                                throw std::invalid_argument("3 points must NOT be colinear.");
                            }
                            _point = pointRef;
                        }

                        // allow construction from a ray.  caller must specify vertical or horizontal to ray.
                        Plane(Ray ray, bool rayIsEdge = false)
                            : _point(ray.origin())
                        {
                            if (math::isApproximatelyZero(ray.direction().length()))
                            {
                                throw std::invalid_argument("ray direction must have length");
                            }

                            _orthogonalDirection = getOrthogonalToDirection(ray.direction(), rayIsEdge);
                        }

                        Plane(const Plane&)    noexcept = default;
                        Plane(Plane&&)         noexcept = default;
                        ~Plane()               noexcept = default;
Plane&                  operator=(const Plane&)  noexcept = default;
Plane&                  operator=(Plane&&)       noexcept = default;


Vec3                    point()    const noexcept { return _point; }
Vec3                    normal() const noexcept { return _orthogonalDirection; }
bool                    pointCoplanar(Vec3 pt, double tolerance = 1e-8)
                        {
                            auto ret = false;
                            // one might think to simply take the distance which is a similar calc.
                            // however, that leads to failures with high direction values even though the point is coplanar.
                            // so normalizing first gives us the magnitude of the perpendicular direction b/n the 2 directions, 0 being coplanar.
                            // It is possible to have a plane at 1.0 and a test point at 1.01 yet with a high magnitude of Z such as 3457892347892435
                            // in that case the 1.01 clearly isn't on the plane.
                            // KA: we can improve by combining with a distance check
                            auto testDir = (_point - pt);
                            auto testUnitDir = testDir.normalized();
                            auto magResult = std::abs(0.0 - Vec3::dot(_orthogonalDirection, testUnitDir));
                            auto distanceResult = std::abs(0.0 - Vec3::dot(_orthogonalDirection, testDir));
                            ret = (magResult < tolerance && distanceResult < tolerance); // check both, if either above a higher tolerance then we are NOT coplanar.
                            return ret;
                        }

double                  distanceFromPoint(Vec3 point)
                        {
                            auto planeToPointDirection = (point - _point);
                            auto distance = std::abs(Vec3::dot(planeToPointDirection, _orthogonalDirection)); // our normal is a unit vector so length is 1
                            return distance;
                        }

Vec3                    mirrorPoint(const Vec3 point)
                        {
                            Vec3 mirror;
                            const auto distanceToPlane = distanceFromPoint(point);
                            auto intersectionOnPlane1 = point + distanceToPlane * normal();
                            auto intersectionOnPlane2 = point - distanceToPlane * normal();
                            
                            // avoid fuzzy errors with testing that point is coplanar, just take shortest length.
                            if(distanceFromPoint(intersectionOnPlane1) < distanceFromPoint(intersectionOnPlane2))                            
                            {
                                // go the same distance from intersection to other side of plane
                                mirror = intersectionOnPlane1 + distanceToPlane * normal();
                            }
                            else // other direction                                
                            {                                
                                mirror = intersectionOnPlane2 - distanceToPlane * normal();
                            }
                            return mirror;                            
                        }

Vec3                    perpendicularPoint(const Vec3 point)
                        {
                            Vec3 pointOnPlane;
                            const auto distanceToPlane = distanceFromPoint(point);
                            auto intersectionOnPlane1 = point + distanceToPlane * normal();
                            auto intersectionOnPlane2 = point - distanceToPlane * normal();

                            // avoid fuzzy errors with testing that point is coplanar, just take shortest length.
                            pointOnPlane = intersectionOnPlane2;
                            if (distanceFromPoint(intersectionOnPlane1) < distanceFromPoint(intersectionOnPlane2))
                            {                                
                                pointOnPlane = intersectionOnPlane1;
                            }
                            return pointOnPlane;
                        }

Plane                   project(const Mat4 & transform) const noexcept
                        {
                            return Plane(transform * _point, transform * _orthogonalDirection - transform * Vec3{0, 0, 0});
                        }

                        // utility for drawing/debug
std::vector<Vec3>       getRectangleOnPlane(double width, double height)
                        {
                            std::vector<Vec3> vertices;

                            // we can get four points of edges from the point on the plane.
                            double r = 0.0;
                            std::optional<Angle> azimuthOpt;
                            std::optional<Angle> inclinationOpt;
                            if (_orthogonalDirection.directionToSphericalCoordinates(r, azimuthOpt, inclinationOpt) && azimuthOpt && inclinationOpt)
                            {
                                // create matrices for backing out the angles and apply them
                                // std::optional::value not available on mac until 10.14 compilation.  
                                auto& azimuth = *azimuthOpt;
                                auto& inclination = *inclinationOpt;
                                auto mat4BackoutAzimuthZ = math::isApproximatelyZero(azimuth.degrees()) ? Mat4() : Mat4::rotation(0, 0, -azimuth);
                                auto mat4BackoutInclinationY = math::isApproximatelyZero(inclination.degrees()) ? Mat4() : Mat4::rotation(0, -inclination, 0);

                                auto heightDir = getOrthogonalToDirection(_orthogonalDirection, false);
                                auto widthDir = getOrthogonalToDirection(_orthogonalDirection, true);

                                heightDir = mat4BackoutInclinationY * mat4BackoutAzimuthZ * heightDir;
                                widthDir = mat4BackoutInclinationY * mat4BackoutAzimuthZ * widthDir;

                                // e.g. pt1 = pt + tMag * pDir1, P2 = pt - tMin * pDir1;  tMag is mag clamped at max and tMin at min.
                                auto pt1 = _point - width * .5 * widthDir;
                                auto pt2 = _point + width * .5 * widthDir;
                                auto pt3 = _point - height * .5 * heightDir;
                                auto pt4 = _point + height * .5 * heightDir;
                                // could give us something like this which isn't quite the vertices we want for a rectangle.
                                //                      pt3
                                //   .   pt1                         pt2
                                //                      pt4
                                // we need the corners.  for those, quickest approach is to back out the sperical angles and
                                // munge the pt1 with pt3 for c1, pt3 with pt2 for c2, etc.
                                //       c1             pt3           c2
                                //   .   pt1                         pt2
                                //       c4             pt4           c3
                                // then reapply the inverse of what was backed out and we should have the final rectangle.

                                // backed out points // direction is now z = 1 so our plane's points are on X/Y with Z = 0
                                // invert the angles on points and add them.
                                vertices.push_back(mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * Vec3(pt1.x, pt3.y, 0.0)); // c1
                                vertices.push_back(mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * Vec3(pt2.x, pt3.y, 0.0)); // c2
                                vertices.push_back(mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * Vec3(pt2.x, pt4.y, 0.0)); // c3
                                vertices.push_back(mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * Vec3(pt1.x, pt4.y, 0.0)); // c4
                            }

                            return vertices;
                        }

                        /**
                         * method   intersects
                         * \brief   3D intersection of two planes
                         * \param   plane1
                         * \param   plane2
                         * \param   <optional> ray providing point and direction
                         * \return  true if intersection was found (uses Ray for a point and direction on the line)
                         */
                        static bool intersects(Plane plane1, Plane plane2, std::optional<Ray>& ray, bool subCall = false)
                        {
                            auto ret = false;
                            constexpr auto xcoord = 1;
                            constexpr auto ycoord = 2;
                            constexpr auto zcoord = 3;

                            // References Joseph O'Rourke, "Search and Intersection" in Computational Geometry in C (2nd Edition) (1998)
                            auto intersectDir = Vec3::cross(plane1.normal(), plane2.normal()); // cross product of the normals (orthogonal direction vectors will give us a perpendicular vector which is the intersection, or 0 if they are the same line.

                            // find intersection if the two planes are not parallel (or coincident)
                            if (!isApproximatelyZero(intersectDir.length())) // plane1 and plane2 are near parallel, either disjoint or coinciding.  Neither one will give a line.  We really don't need to know this but if you do, taking dot product of plane1's orthogonalDirection (normal) with the direction vector of plane2.point - plane1.point will give 0 for coincident.
                            {
                                // we have an intersection
                                // determine which axis to zero in order to find a point on line
                                bool intersectDirXZero = isApproximatelyZero(intersectDir.x);
                                bool intersectDirYZero = isApproximatelyZero(intersectDir.y);
                                bool intersectDirZZero = isApproximatelyZero(intersectDir.z);

                                Vec3 intersectPoint;

                                auto sumIntersectDirZero = static_cast<int>(intersectDirXZero) + static_cast<int>(intersectDirYZero) + static_cast<int>(intersectDirZZero);

                                // special case when cross product has one or more directions that are 0
                                if (sumIntersectDirZero > 0 && !subCall) // avoid stack overflow.  only call ourselves 1x
                                {
                                    // if two direction coordinates are 0 then we are axis aligned <1,0,0>, <0,1,0>, or <0,0,1> and the computation for 
                                    // we could also have an issue with only 1 axis 0 like <0,1,1>, <1,0,1>, <1,1,0>
                                    // intersection point will not work as expected as the solution depends on all values
                                    // This is rife with various special cases.  So if this one or two directions are zero, it's cleaner to rotate 45 on opposite axis
                                    // do all the math, then backout the transform to get the final results.
                                    Mat4 mat45;
                                    if (intersectDirZZero) // resulting intersection line is in XY plane with no change to Z
                                    {   
                                        if (intersectDirYZero) // line along X axis so rotate on Y to get values where there were 0's
                                        {
                                            mat45 = Mat4::rotation(0, Angle(45.0, Angle::Units::Degrees), 0);                                               
                                        }
                                        else // line along Y axis so rotate on X, if all three lineDir axis are 0 that would have been rejected above so we don't have to test that here.
                                        {
                                            mat45 = Mat4::rotation(Angle(45.0, Angle::Units::Degrees), 0, 0);                                            
                                        }
                                    } // handled z zero, directions x or y
                                    // y or x could still be 0 so handle y here.
                                    // potentially have done one rotation if Z was 0. hence the multiplies here to preserve that.
                                    if (intersectDirYZero) 
                                    {
                                         // line is along Z or ZX, rotate on X                                        
                                         mat45 = Mat4::rotation(Angle(45.0, Angle::Units::Degrees), 0, 0) * mat45;
                                    }
                                    else if(intersectDirXZero) // and zero x
                                    {
                                         // line is along Z or ZY, rotate on Y
                                         mat45 = Mat4::rotation(0, Angle(45.0, Angle::Units::Degrees), 0) * mat45;
                                    }

                                    auto p1_45 = plane1.project(mat45);
                                    auto p2_45 = plane2.project(mat45);
                                    std::optional<Ray> ray45opt;
                                    if (intersects(p1_45, p2_45, ray45opt, true) && ray45opt)
                                    {
                                        auto& ray45 = *ray45opt;
                                        auto rayResult = ray45.project(mat45.inverse()); // backout so we should have proper point and vector.
                                        intersectPoint = rayResult.origin();
                                        ret = true;
                                    }                            
                                }
                                else
                                {
                                    unsigned int zerocoord = 0;
                                    if (intersectDir.isXMax() || intersectDir.x == intersectDir.y)
                                    {
                                        zerocoord = xcoord;
                                    }
                                    else if (intersectDir.isYMax())
                                    {
                                        zerocoord = ycoord;
                                    }
                                    else
                                    {
                                        zerocoord = zcoord;
                                    }

                                    // for an intersection point, zero the coordinate we determined and solve the others.  
                                    // if cross product vector members are 0 (as they would be for axis aligned cases) safe divide will return 0.
                                    
                                    const double negDot1 = -Vec3::dot(plane1.normal(), plane1.point());
                                    const double negDot2 = -Vec3::dot(plane2.normal(), plane2.point());

                                    switch (zerocoord)
                                    {
                                    case xcoord:
                                        intersectPoint.x = 0;
                                        intersectPoint.y = SafeDivide(negDot2 * plane1.normal().z - negDot1 * plane2.normal().z, intersectDir.x);
                                        intersectPoint.z = SafeDivide(negDot1 * plane2.normal().y - negDot2 * plane1.normal().y, intersectDir.x);
                                        break;
                                    case ycoord:
                                        intersectPoint.x = SafeDivide(negDot1 * plane2.normal().z - negDot2 * plane1.normal().z, intersectDir.y);
                                        intersectPoint.y = 0;
                                        intersectPoint.z = SafeDivide(negDot2 * plane1.normal().x - negDot1 * plane2.normal().x, intersectDir.y);
                                        break;
                                    case zcoord:
                                        intersectPoint.x = SafeDivide(negDot2 * plane1.normal().y - negDot1 * plane2.normal().y, intersectDir.z);
                                        intersectPoint.y = SafeDivide(negDot1 * plane2.normal().x - negDot2 * plane1.normal().x, intersectDir.z);
                                        intersectPoint.z = 0;
                                    }
                                    ret = true;
                                }
                                ray = Ray(intersectPoint, intersectDir);                                
                            }
                            return ret;
                        }

    private:


        Vec3            _point;
        Vec3            _orthogonalDirection; // aka normal in geometry literature.
    };
}//bosepro::math

#endif //PLANE_H