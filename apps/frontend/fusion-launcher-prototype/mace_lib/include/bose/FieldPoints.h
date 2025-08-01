#pragma once
#ifndef FIELDPOINTS_H
#define FIELDPOINTS_H

#include "FieldPoint.h"
#include "Time/Timestamp.h"
#include "DataSet.h"
#include "Lock/Lock.h"
#include "Uid.h"
#include "Math/MathUtils.h"
#include "Enum.h"

namespace bosepro::simulation
{    
    enum class HitTestMode : int64_t
    {
        None,
        ClusterMid,
        PerCabinet,
    };

    class FieldPoints;
    using FieldPointsPtr = std::shared_ptr<FieldPoints>;
       
	/**
	 * \class			FieldPoints
	 *
	 * \brief			A collection of FieldPoint entries. Could be used for input or output.  Associated data will be in FieldPointData.
	 * 
	 * \details			Found things more performant keeping associated data separate.  So we could use
     *                  std::move to go from input points to output.  Although a copy of a million points 
     *                  around 23ms isn't terrible.  Optimization: This class isa vector for getArrivals to use collection.
     *                  Note this has lock protection.  Chunk was clearing points while we had em on a dif
     *                  thread.  Can't allow that.
	 */
	using fpVector = std::vector<FieldPoint>; // TODO: can this be a SaferVector??
	class FieldPoints : public fpVector,
						public Uid
    {
    public:
                                    FieldPoints()
                                    {
                                        _ts.set();
                                    }
									FieldPoints(std::initializer_list<FieldPoint> l) : fpVector(l)
                                    {
	                                    _ts.set();
                                    }
                                    ~FieldPoints()              = default;
                                        
                                    FieldPoints(const FieldPoints& other) : fpVector(other)
                                    {
                                        ScopedLock sl(other._lock);

                                        _ts            = other._ts;                                            
                                        _hitTestMode   = other._hitTestMode.load();
                                    }

                                    FieldPoints(FieldPoints&& other) noexcept : fpVector(std::move(other))
                                    {
                                        ScopedLock sl(other._lock);

                                        _ts            = std::move(other._ts);
                                        _hitTestMode   = std::move(other._hitTestMode.load());
                                    }

        FieldPoints&			    operator=(const FieldPoints& other)
                                    {
                                        if(this != &other)
                                        {
                                            ScopedLockPair sl(_lock, other._lock);

                                            fpVector::operator=(other); // implicitly assign this base portion
                                            _ts            = other._ts;    
                                            _hitTestMode   = other._hitTestMode.load();
                                        }

                                        return *this;
                                    }

        FieldPoints&                operator=(FieldPoints&& other) noexcept
        {
                                        if(this != &other)
                                        {
                                            ScopedLockPair sl(_lock, other._lock);

                                            fpVector::operator=(other); // implicitly assigns this base portion
                                            _ts            = std::move(other._ts);               
                                        }

                                        return *this;
                                    }

                                    //Equality operators
        friend bool                 operator==(const FieldPoints& lhs, const FieldPoints& rhs)  {return lhs.samePoints(rhs);}
        friend bool                 operator!=(const FieldPoints& lhs, const FieldPoints& rhs)  {return !(lhs == rhs);}

                                    // for a class that hold a member and reassigns data (chunks)
        void                        updateTimestamp()
                                    {
                                        ScopedLock sl(_lock);
                                        _ts.set();
                                    }

        Timestamp                   getTimestamp() const
                                    {
                                        ScopedLock sl(_lock);
                                        return _ts;
                                    }

        auto&                       getHitTestMode() const
                                    {
                                        return _hitTestMode;
                                    }

        void                        setHitTestMode(int64_t mode)
                                    {
                                        _hitTestMode = mode;
                                    }                        

        bool                        samePoints(const FieldPoints& other) const
                                    {
                                        ScopedLockPair sl(_lock, other._lock);
                                        if(empty() && other.empty())
                                        {
                                            return true; // if both empty they're the same. avoid accessing elements and crashing.
                                        }

                                        if(size() != other.size())
                                        {
                                            return false; // a 1 x 20 and a 2 x 10 will yield same #, so size alone isn't sufficient.  Yes, std::equal will compare size, but this is a fast exit condition early on since we need to 
                                        }

                                        if(front() != other.front() || back() != other.back()) // first and last will catch basic rotation.
                                        {
                                            return false;
                                        }
                                        if(getTimestamp() == other.getTimestamp()) // jic
                                        {
                                            return true;
                                        }
                                        return std::equal(cbegin(), cend(), other.cbegin());
                                    }

		/**
		 * \fn			Is2dColinear
		 * \brief		utility function, points in same 2d view (ignores Z)
		 * \return		true/false if points are in line
		 */		
        bool Is2dColinear() const noexcept
        {
            auto ret = false;
            // simple algebra.  y = mx + b
            // get first point and last point, ignore z.
            // compute the slope of the line, then check if each point is on same line.
            // Was created to check if points provided for level over distance are in a line.
            if (size() == 2) // if we only have 2 points of course everything is on same line!
            {
                ret = true;
            }
            else if (size() > 2) // for this, all points must be on same line.
            {
                auto pt1 = begin();
                auto pt2 = rbegin();
                if (pt1 != end() && pt2 != rend())
                {
                    // compute initial slope given the two outer points.
                    const double boundingSlope = math::SafeDivide((pt2->y - pt1->y), (pt2->x - pt1->x));
                    const double tolerance = .01;
                    // test all other points.
                    ret = true;
                    for (std::size_t ix = 1; ix < (size() - 1); ++ix)
                    {
                        const double compareSlope = math::SafeDivide((at(ix).y - pt1->y), (at(ix).x - pt1->x));
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

    private:
        Timestamp                   _ts;
        Lock                        _lock;            
        std::atomic_int64_t         _hitTestMode = {enumToUnderlying(HitTestMode::ClusterMid)}; // since there's currently no measurable dif in release builds, default to on
    };


	/**
	 * \class			FieldPointsData
	 *
	 * \brief			The return data to caller that contains a DataSet AND the FieldPoints that were valid at the
     *                  time Calculate was called.
	 *
	 * \details			Originally this class didn't have a lock due to it's usage.  Engine creates, tells app 
     *                  data is ready, then app picks it up.  There shouldn't be contention but if usage ever 
     *                  changes, we don't want to worry that it's not thread safe, hence the addition of the 
     *                  lock.
	 */
    class FieldPointsData
    {
    public:

                                    FieldPointsData() : m_surfaceId(0)
                                    {}

                                    FieldPointsData(const FieldPointsData&) = delete;
        FieldPointsData&            operator=(const FieldPointsData&)       = delete;
                                    FieldPointsData(FieldPointsData&&)      = delete;
        FieldPointsData&            operator=(FieldPointsData&&)            = delete;

        void                        addPoints(const FieldPoints& pts, const uint64_t surfaceId)
        {
            ScopedLock sl(m_Lock);
            m_pts = pts;  // express intent more clearly, vs std::copy
            m_surfaceId = surfaceId;
        }
        void                        setData(measurement::DataSetPtr p)
        {
            ScopedLock sl(m_Lock);
            m_data = std::move(p); 
        }

        measurement::DataSetPtr     getData() const
        {
            ScopedLock sl(m_Lock);
            return m_data;
        }

        const FieldPoints&          points() const
        {
            ScopedLock sl(m_Lock);
            return m_pts;
        }

        uint64_t                    getSurfaceId() const
        {
            ScopedLock sl(m_Lock);
            return m_surfaceId;
        }

        Timestamp                   getDataTimestamp() const
        {
            ScopedLock sl(m_Lock);

            if(m_data != nullptr)
                return m_data->getTimestamp();
            Timestamp t;
            t.reset();
            return t;
        }

    private:
        uint64_t                    m_surfaceId;
        FieldPoints                 m_pts;
        measurement::DataSetPtr     m_data;

        Lock                        m_Lock;
    };

    using FieldPointsDataPtr = std::shared_ptr<FieldPointsData>;
} // bosepro::simulation

#endif // !FIELDPOINTS_H

