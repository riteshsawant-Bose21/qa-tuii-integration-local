#pragma once
#ifndef ORIENTATION_H
#define ORIENTATION_H

#include "Math/Angle.h"
#include "Math/Quaternion.h"

namespace bosepro
{	
	/**
	 * \class		Orientation
	 *
	 * \brief		Simple object to encapsulate roll, pitch & yaw angles
	 *				See also Placement and Angle
	 */
	class Orientation
    {
    public:
        virtual                        ~Orientation()                                                           = default;
                                        Orientation()                                                           : Orientation(math::Angle(0.0), math::Angle(0.0), math::Angle(0.0)){}
                                        Orientation(math::Angle roll, math::Angle pitch, math::Angle yaw)       : m_Roll(roll), m_Pitch(pitch), m_Yaw(yaw){}
                                        Orientation(const Orientation&)                                         = default;
                                        Orientation(Orientation&&)                                              = default;
        Orientation&                    operator=(const Orientation&)                                           = default;
        Orientation&                    operator=(Orientation&&)                                                = default;

        friend bool                     operator==(const Orientation& lhs, const Orientation& rhs)              {return lhs.getQuaternion() == rhs.getQuaternion();}
        friend bool                     operator!=(const Orientation& lhs, const Orientation& rhs)              {return !(lhs == rhs);}

        friend Orientation              operator+(const Orientation& lhs, const Orientation& rhs)               {math::Angle r, p, y; (lhs.getQuaternion() * rhs.getQuaternion()).toRollPitchYaw(r, p, y); return Orientation(r, p, y);}
            
        static Orientation              combine(const Orientation& lhs, const Orientation& rhs)                 {return lhs + rhs;}

        inline const math::Angle&       getRoll()                                                       const   {return m_Roll;}
        inline const math::Angle&       getPitch()                                                      const   {return m_Pitch;}
        inline const math::Angle&       getYaw()                                                        const   {return m_Yaw;}
            
        inline void                     get(math::Angle& roll, math::Angle& pitch, math::Angle& yaw)    const   {roll = m_Roll; pitch = m_Pitch; yaw = m_Yaw; }
        math::Mat4                      getMatrix()                                                     const   {return static_cast<math::Mat4>(getQuaternion());}
        math::Quat                      getQuaternion()                                                 const   {return math::Quat::fromRollPitchYaw(m_Roll, m_Pitch, m_Yaw);}

        inline void                     setRoll(math::Angle val)                                                {m_Roll  = val;}
        inline void                     setPitch(math::Angle val)                                               {m_Pitch = val;}
        inline void                     setYaw(math::Angle val)                                                 {m_Yaw   = val;}
            
        inline void                     set(math::Angle roll, math::Angle pitch, math::Angle yaw)               {m_Roll = roll; m_Pitch = pitch; m_Yaw = yaw;}
        inline void                     set(const math::Quat& q)                                                {math::Angle r, p, y; q.toRollPitchYaw(r, p, y); set(r, p, y);}
		inline void                     set(const math::Mat4& m)												{set(math::Quat::getRotation(m));}
            
    private:
        math::Angle                     m_Roll;
        math::Angle                     m_Pitch;
        math::Angle                     m_Yaw;
    };	
}//bosepro

#endif //ORIENTATION_H