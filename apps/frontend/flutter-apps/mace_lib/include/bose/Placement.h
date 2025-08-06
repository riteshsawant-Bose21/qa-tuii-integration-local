#pragma once
#ifndef PLACEMENT_H
#define PLACEMENT_H

#include "Math/Angle.h"
#include "Orientation.h"
#include "Lock/Lock.h"

namespace bosepro
{	
	/**
	 * \class		Placement
	 *
	 * \brief		The combination of position and orientation and the associated transforms
	 * \details		Thread safe
	 *				Handy for objects like loudspeakers, flybars and rigging accessories
	 *				See also Orientation
	 */
    class Placement
    {
    public:
        virtual                         ~Placement() = default;

        Placement(math::Vec3 loc = {0.0, 0.0 ,0.0}, Orientation ori = {0.0, 0.0, 0.0}, math::Vec3 origin = {0.0, 0.0, 0.0})
                                            : m_Location({0.0, 0.0 ,0.0}),
                                                m_Orientation({0.0, 0.0, 0.0}),
                                                m_Origin({0.0, 0.0, 0.0})
                                        {
                                            setLocation(loc);
                                            setOrientation(ori);
                                            setOrigin(origin);
                                        }

                                        Placement(const Placement& other)
                                        {
                                            ScopedLock sl(other.m_Lock);

                                            m_Location      = other.m_Location;
                                            m_Orientation   = other.m_Orientation;
                                            m_Origin        = other.m_Origin;
                                            m_Transform     = other.m_Transform;
                                            m_TransformInv  = other.m_TransformInv;
                                        }

                                        Placement(Placement&& other) noexcept
                                        {
                                            ScopedLock sl(other.m_Lock);

                                            m_Location      = std::move(other.m_Location);
                                            m_Orientation   = std::move(other.m_Orientation);
                                            m_Origin        = std::move(other.m_Origin);
                                            m_Transform     = std::move(other.m_Transform);
                                            m_TransformInv  = std::move(other.m_TransformInv);
                                        }

        Placement&                      operator=(const Placement& other)
                                        {
                                            if(this != &other)
                                            {
                                                ScopedLockPair sl(m_Lock, other.m_Lock);

                                                m_Location      = other.m_Location;
                                                m_Orientation   = other.m_Orientation;
                                                m_Origin        = other.m_Origin;
                                                m_Transform     = other.m_Transform;
                                                m_TransformInv  = other.m_TransformInv;
                                            }

                                            return *this;
                                        }

        Placement&                      operator=(Placement&& other) noexcept
        {
                                            if(this != &other)
                                            {
                                                ScopedLockPair sl(m_Lock, other.m_Lock);

                                                m_Location      = std::move(other.m_Location);
                                                m_Orientation   = std::move(other.m_Orientation);
                                                m_Origin        = std::move(other.m_Origin);
                                                m_Transform     = std::move(other.m_Transform);
                                                m_TransformInv  = std::move(other.m_TransformInv);
                                            }

                                            return *this;
                                        }

                                        //Equality operators
        friend bool                     operator==(const Placement& lhs, const Placement& rhs)          {ScopedLockPair sl(lhs.m_Lock, rhs.m_Lock); return lhs.m_Transform == rhs.m_Transform;}
        friend bool                     operator!=(const Placement& lhs, const Placement& rhs)          {return !(lhs == rhs);}

        friend Placement                operator+(const Placement& lhs, const Placement& rhs)           {return fromMatrix(rhs.getTransform() * lhs.getTransform());}

        static Placement                combine(Placement lhs, Placement rhs)                           {return lhs + rhs;}

                                        //Local to world/parent transform
        inline const math::Mat4         getTransform()                                          const   {ScopedLock sl(m_Lock); return m_Transform;}

                                        //world/parent to local transform
        inline const math::Mat4         getTransformInv()                                       const   {ScopedLock sl(m_Lock); return m_TransformInv;}

                                        //Location in world/parent space
        inline const math::Vec3         getLocation()                                           const   {ScopedLock sl(m_Lock); return m_Location;}
        bool                            setLocation(math::Vec3 val)                                     {return set(val, getOrientation(), getOrigin());}

                                        //Orientation in world/parent space
        inline const Orientation        getOrientation()                                        const   {ScopedLock sl(m_Lock); return m_Orientation;}
        bool                            setOrientation(Orientation val)                                 {return set(getLocation(), val, getOrigin());}

                                        //Origin in local space
        inline const math::Vec3         getOrigin()                                             const  {ScopedLock sl(m_Lock); return m_Origin;}
        bool                            setOrigin(math::Vec3 val)                                      { return set(getLocation(), getOrientation(), val); }


                                        //Set in world/parent space
        inline bool                     set(math::Vec3 loc, Orientation ori, math::Vec3 origin)
                                        {
                                            ScopedLock sl(m_Lock); 

                                            //Return true if val was not clamped
                                            bool valid  = true;

                                            //Validate and set location
                                            valid          &= validate(loc);
                                            m_Location      = loc;

                                            //Validate and set orientation
                                            valid          &= validate(ori);
                                            m_Orientation   = ori;

                                            valid          &= validate(origin);
                                            m_Origin        = origin;

                                            auto mat4 = toMatrix(m_Location, m_Orientation);

                                            // apply any origin offset
                                            if (m_Origin != math::Vec3(0.0, 0.0, 0.0))
                                            {
                                                // back out orientation on transform, then translate, then reapply orientation
                                                auto pivot = math::Mat4::translation(m_Origin);
                                                mat4 = m_Orientation.getMatrix() * pivot.inverse() * m_Orientation.getMatrix().inverse() * mat4;
                                            }
                                            
                                            setMatrix(mat4);

                                            return valid;
                                        }

                                        //Conversion helpers
        static Placement                fromMatrix(math::Mat4 m)
                                        {
                                            const auto v = m.getTranslation();
                                            const auto q = math::Quat::getRotation(m);

                                            math::Angle r, p, y;
                                            q.toRollPitchYaw(r, p, y);

                                            return Placement(v, Orientation(r, p, y));
                                        }

        static math::Mat4               toMatrix(const math::Vec3& loc, const Orientation& ori)
                                        {
                                            return math::Mat4::translation(loc) * ori.getMatrix();
                                        }
    protected:
                                        //Internal helpers for child override, thus allowing for
                                        //clamping or testing of inputs.
                                        //Current values are not set until after this call.
                                        //Return false if input was clamped.
        virtual bool                    validate(math::Vec3&) {return true;}
        virtual bool                    validate(Orientation&){return true;}

                                        //Child override for change callback
        virtual void                    onPlacementChange(){}

    private:
                                        //Set new transform & inv transform
        void                            setMatrix(math::Mat4 val)
                                        {
                                            m_Transform    = val;
                                            m_TransformInv = m_Transform.inverse();

                                            onPlacementChange();
                                        }

    private:
        Lock                            m_Lock;
        math::Vec3                      m_Location;
        Orientation                     m_Orientation;
        math::Vec3                      m_Origin; // typically 0,0,0 but could be changed to support different pivot point (pickpoints)
        math::Mat4                      m_Transform;
        math::Mat4                      m_TransformInv;
    };

    using PlacementPtr                  = std::shared_ptr<Placement>;
}//bosepro

#endif //PLACEMENT_H