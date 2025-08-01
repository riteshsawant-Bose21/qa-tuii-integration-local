#pragma once
#ifndef DATASET_H
#define DATASET_H

#include <memory>
#include <vector>
#include <map>
#include "Bandwidth.h"
#include "Time/Timestamp.h"
#include "OctaveBandFrequencies.h"
#include "MeasurementTypes.h"
#include "Math/Vector.h"

namespace bosepro::measurement
{
	/**
	 * \class		CalcListener
	 *
	 * \brief		a listener may want to know when all calcs are generally starting/stopped
	 */
	class CalcListener
    {
    public:
        // just used as an interface, but... because it is virtual , the default destructor isn't and triggers a warning
                                    CalcListener()                      = default;
        virtual                     ~CalcListener()                     = default;
                                    CalcListener(const CalcListener&)   = default;
        CalcListener&               operator=(const CalcListener&)      = default;
                                    CalcListener(CalcListener&&)        = default;
        CalcListener&               operator=(CalcListener&&)           = default;

        virtual void                OnCalcStart() = 0;
        virtual void                OnCalcEnd(bool cancel) = 0;
        virtual void                OnCalcData(uint64_t fieldId) = 0;
		virtual void				OnMeasurementComplete(uint64_t measId) = 0;
    };

    using PairedData                = std::vector< std::pair< uint64_t, std::vector<double>>>; // this uses less memory and is faster to setup than unordered_map.  NOTE: this presumes you do NOT need to do quick lookups of point data.

    struct BasicArrivalData
    {
        // just essentials for arrival times to use
        math::Vec3 src;
        std::vector<double> gainInMag;
        std::vector<double> timeInSecs;
    };

    using PairedArrivalData         = std::vector< std::pair< uint64_t, std::vector<BasicArrivalData>>>;
        
    class DataSet;
    using DataSetPtr                = std::shared_ptr<DataSet>;

	/**
	 * \class		DataSet
	 *
	 * \brief		Container for acoustic engine output data
	 *				This is an interface that will wrap an impl.
	 */
	class DataSet
    {
    public:            
                                    DataSet()                           {m_Timestamp.set();}
        virtual                     ~DataSet()                          = default;
                                        
                                    //Non-copyable
                                    DataSet(const DataSet&)             = delete;
                                    DataSet& operator=(const DataSet&)  = delete;
                                    DataSet(DataSet&&)                  = delete;
                                    DataSet& operator=(DataSet&&)       = delete;

        inline const Timestamp&     getTimestamp() const                {return m_Timestamp;}
            			
        virtual bool			    GetSPL(PairedData& pd, const acoustics::Bandwidth bw, acoustics::Freqs freqs = {}, std::string stimulus = "", std::string weighting = "", bool dBInSPL = true) = 0;
		virtual bool				FindMinSPL(double& min, const acoustics::Bandwidth bw, acoustics::Freqs freqs = {},std::string stimulus = "",  std::string weighting = "", bool dBInSPL = true, bool nonZero = true) const = 0;
		virtual bool				FindMaxSPL(double& max, const acoustics::Bandwidth bw, acoustics::Freqs freqs = {},std::string stimulus = "",  std::string weighting = "", bool dBInSPL = true) const	= 0;
        virtual void    			GetFreqResponse(PairedData& pd, int smoothing = -1, std::string weighting = "", bool dBInSPL = true) = 0;
        virtual void    			GetPhaseResponse(PairedData& pd, int smoothing = -1, bool inDegrees = true) = 0;
        virtual void                GetArrivalData(PairedArrivalData& pd) = 0;
        virtual acoustics::Freqs    GetFreqResponseCenters() = 0;
        virtual acoustics::Freqs    GetArrivalCenters() = 0;
        virtual bool                HasData(MeasurementType measType) const = 0;

    private:
        Timestamp                   m_Timestamp;            			
    };
}//bosepro::measurement

#endif //DATASET_H