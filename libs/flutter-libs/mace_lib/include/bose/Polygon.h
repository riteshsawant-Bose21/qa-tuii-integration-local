#pragma once
#ifndef SURFACE_POLYGON_H__
#define SURFACE_POLYGON_H__

#include <memory>
#include "Surface.h"
#include <utility>
#include <algorithm>
#include <bose/Math/Plane.h>

namespace bosepro::model
{
    /**
     * \class       Polygon
     *
     * \brief       A Surface that can represent polygons with 3 or more vertices
     * \details     Useful for audience areas in 3d space.
     *              This object is immutable sans cctor/mmtor and operator=     
     */
    class Polygon : public Surface
	{
	public:
		Polygon() {}
        Polygon(std::vector<math::Vec3> vertices, math::Vec3 loc = {0.0, 0.0 ,0.0}, Orientation ori = {0.0, 0.0, 0.0}, SurfaceTypes surfaceType = SurfaceTypes::ListeningArea)
            : Surface(loc, std::move(ori), surfaceType), _vertices(std::move(vertices))
        {
            auto verts = getVertices();
            auto planePoly = getPlane(verts);
            bool inPlane = !math::isApproximatelyZero(planePoly.normal().length());
            if (inPlane)
            {
                for (auto& vertex : verts) // check that all vertices are in same plane!
                {
                    if (!planePoly.pointCoplanar(vertex))
                    {
                        inPlane = false;
                        break;
                    }
                }
            }
            if (!inPlane)
            {
                throw std::invalid_argument("3 or more non-colinear coplanar vertices required.");
            }
        }

		Polygon(const Polygon& other) noexcept;
		Polygon(Polygon&& other) noexcept;
		Polygon& operator=(const Polygon& other) noexcept;
		Polygon& operator=(Polygon&& other) noexcept;
		virtual ~Polygon() noexcept;

		bool operator==(const Polygon& other) const noexcept;
		bool operator!=(const Polygon& other) const noexcept;

		math::Vec3 getMaxPointOnXY() const override;
        math::Vec3 getMinPointOnXY() const override;
        math::Vec3 getMaxPointOnXZ() const override;
        math::Vec3 getMinPointOnXZ() const override;
		math::Vec3 getMaxPointOnYZ() const override;
		math::Vec3 getMinPointOnYZ() const override;

		bool hitTest(const math::Ray& ray, double segmentLength, std::shared_ptr<math::Vec3> where = nullptr) const override;

        Polygon project(const math::Mat4& transform) const noexcept
        {
            // better to use setLocation/setOrientation, but someone didn't apply those in getVertices
            std::vector<math::Vec3> verts = getVertices(false); // use local for this.
            std::for_each(verts.begin(), verts.end(), [&transform](auto& vert){vert = transform * vert; });
            return Polygon(verts, getLocation(), getOrientation()); // two points we can just apply transform.
        }

		std::vector<math::Vec3> getVertices(bool inWorld = true) const;
		bool getVertexAt(const size_t index, math::Vec3& vertex, bool inWorld = true) const;
        math::Vec3 getVertexAt(const size_t index, bool inWorld = true) const;
		size_t verticesCount() const;

        math::Plane getPlane(std::vector<bosepro::math::Vec3> verts = {}) const;

	private:
		Lock _lock;
		std::vector<math::Vec3> _vertices;
	};
}

#endif //SURFACE_POLYGON_H__
