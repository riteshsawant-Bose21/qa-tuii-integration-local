#pragma once
#ifndef OCTAVEBAND_H
#define OCTAVEBAND_H

#include <vector>

namespace bosepro::acoustics
{	

    class OctaveBand;
    using OctaveBands       = std::vector<OctaveBand>;

	/**
	 * \class		OctaveBand
	 *
	 * \brief		Simple object to encapsulate octave band frequencies
	 *				See also OctaveBandFrequencies
	 */
	class OctaveBand
	{
	public:
		virtual			    ~OctaveBand() noexcept = default;

                            OctaveBand(double lower = 0.0, double center = 0.0, double upper = 0.0, double nominal = 0.0) noexcept
								: m_Lower(lower), 
                                    m_Center(center), 
                                    m_Upper(upper), 
                                    m_Nominal(nominal)
							{
							}

                            OctaveBand(const OctaveBand&)	noexcept = default;
                            OctaveBand(OctaveBand&&)		noexcept = default;
		OctaveBand&			operator=(const OctaveBand&)	noexcept = default;
		OctaveBand&			operator=(OctaveBand&&)			noexcept = default;

		friend bool			operator==(const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return lhs.m_Center == rhs.m_Center;}
        friend bool			operator!=(const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return !(lhs == rhs);}
        friend bool			operator< (const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return lhs.m_Center < rhs.m_Center;}
        friend bool			operator> (const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return rhs < lhs;}
        friend bool			operator<=(const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return !(lhs > rhs);}
        friend bool			operator>=(const OctaveBand& lhs, const OctaveBand& rhs)	noexcept {return !(lhs < rhs);}

        friend int			compare(const OctaveBand& lhs, const OctaveBand& rhs)		noexcept {return lhs.m_Center > rhs.m_Center ? 1 : (lhs.m_Center < rhs.m_Center ? -1 : 0);}

        inline bool         contains(double freq)           const   {return m_Lower <= freq && freq <= m_Upper;}

		inline double       lowerFreq()		                const   {return m_Lower;}
		inline double       centerFreq()	                const   {return m_Center;}
		inline double       upperFreq()		                const   {return m_Upper;}
		inline double       nominalFreq()	                const   {return m_Nominal;}

		inline void		    lowerFreq  (double val)	                {m_Lower    = val;}
		inline void		    centerFreq (double val)	                {m_Center   = val;}
		inline void		    upperFreq  (double val)	                {m_Upper    = val;}
		inline void		    nominalFreq(double val)	                {m_Nominal  = val;}	   										

        inline bool         isValid()                       const   {return m_Lower  > 0.0 && m_Center > m_Lower && m_Upper  > m_Center;}

	private:
		double			    m_Lower;
		double			    m_Center;
		double			    m_Upper;
		double			    m_Nominal; //Nominal center
	};
}//bosepro

#endif //OCTAVEBAND_H