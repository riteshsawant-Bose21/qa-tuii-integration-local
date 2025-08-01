#pragma once
#ifndef COVERAGEMAPFREQS_H
#define COVERAGEMAPFREQS_H

#include <unordered_map>
#include <utility>
#include "OctaveBandFrequencies.h"


namespace bosepro::acoustics
{	
    /**
        * \brief       Static method to calculate all frequency data for the bandwidths supported 
        *               by the coverage map. Includes frequencies for band lower/upper edges, actual/nominal
        *               centers and string variants for bandwidth and nominal centers.
        *
        * \details     Currently we are only supporting Oct & 3rd Oct bandwidths from 31.5Hz to 16kHz
        *               However if this were ever to change, this is the location that should be updated.
        *
        *               Use getCoverageMapFreqs() to calculate freq data (method only calculates once)
        *               See CoverageMapFreqs for method return type and data extraction
        */
    class CoverageMapFreqs
    {
    public:
                                    CoverageMapFreqs(Bandwidth bw, std::string bwStr, Freqs centerFreqsActual, Freqs centerFreqsNominal, FreqStrings freqStrs, OctaveBands bands)
                                        : m_BW(bw),
                                            m_sBW(std::move(bwStr)),
                                            m_FreqsActualCenter(std::move(centerFreqsActual)),
                                            m_FreqsNominalCenter(std::move(centerFreqsNominal)),
                                            m_sFreqs(std::move(freqStrs)),
                                            m_Bands(std::move(bands))
                                    {
                                        assert(!m_sBW.empty());
                                        assert(!m_FreqsActualCenter.empty());
                                        assert(m_FreqsActualCenter.size() == m_sFreqs.size());
                                        assert(m_FreqsActualCenter.size() == m_Bands.size());
                                        assert(m_FreqsActualCenter.size() == m_FreqsNominalCenter.size());

                                        if(m_FreqsActualCenter.size() != m_sFreqs.size() || m_FreqsActualCenter.size() != m_Bands.size() || m_FreqsActualCenter.size() != m_FreqsNominalCenter.size())
                                        {
                                            m_FreqsActualCenter.clear();
                                            m_FreqsNominalCenter.clear();
                                            m_sFreqs.clear();
                                            m_Bands.clear();
                                        }
                                    }

                                    CoverageMapFreqs(const CoverageMapFreqs&)               = default;
                                    CoverageMapFreqs& operator=(const CoverageMapFreqs&)    = default;
                                    CoverageMapFreqs(CoverageMapFreqs&&)                    = default;
                                    CoverageMapFreqs& operator=(CoverageMapFreqs&&)         = default;
        virtual                     ~CoverageMapFreqs()                                     = default;

        inline Bandwidth            getBandwidth()                                  const   {return m_BW;}
        inline const std::string&   getBandwidthString()                            const   {return m_sBW;}
        inline const Freqs&         getNominalCenterFreqs()                         const   {return m_FreqsNominalCenter;}
        inline const Freqs&         getActualCenterFreqs()                          const   {return m_FreqsActualCenter;}
        inline const FreqStrings&   getNominalCenterFreqStrings()                   const   {return m_sFreqs;}
        inline const OctaveBands&   getOctaveBands()                                const   {return m_Bands;}

        inline unsigned int         size()                                          const   {return static_cast<unsigned int>(m_FreqsActualCenter.size());}

    private:
        Bandwidth                   m_BW;
        std::string                 m_sBW;
        Freqs                       m_FreqsActualCenter;
        Freqs                       m_FreqsNominalCenter;
        FreqStrings                 m_sFreqs;
        OctaveBands                 m_Bands;
    };


    using BandwidthFreqsMap         = std::unordered_map<Bandwidth, CoverageMapFreqs>;



    /**
        * method      	getCoverageMapFreqs()
        *					
        * \param      	void
        *					
        * \return     	BandwidthFreqsMap& 
        *					
        * \brief          Static method to calculate all frequency data for the bandwidths supported 
        *                  by the coverage map. Includes frequencies for band lower/upper edges, actual/nominal
        *                  centers and string variants for bandwidth and nominal centers.	
        *                 
        * \details    	Return value is safe to reference as it is static and only created once. 
        *                  See also getCoverageMapCenterFreqs if you only need center frequencies.
        */
    static const BandwidthFreqsMap& getCoverageMapFreqs()
    {
        static BandwidthFreqsMap map;

        //Supported bandwidths
        static const std::vector<Bandwidth> bws = {Bandwidth::Octave, Bandwidth::Third, Bandwidth::VocalBands, Bandwidth::AllBands};

        if(map.empty())
        {
            //Build map
            for(auto const& bw : bws)
            {
                Freqs       a;
                Freqs       n;
                FreqStrings s;
                OctaveBands b;
                        
                // we have two ranged bands (vocal, all)
                // Freqs will contain JUST the center/nominal value of the range to avoid asserts
                if(Bandwidth::AllBands == bw)
                {
                    const double center = (Frequency::max - Frequency::min) * 0.5 + Frequency::min;
                    a = n = {center};
                    s = OctaveBandFrequencies::freqsToString({Frequency::min, Frequency::max}, true, true);
                    b.emplace_back(OctaveBand(Frequency::min, center, Frequency::max, center));
                }
                else if(Bandwidth::VocalBands == bw)
                {
                    const double center = (Frequency::maxVocal - Frequency::minVocal) * 0.5 + Frequency::minVocal;
                    a = n = {center};
                    s = OctaveBandFrequencies::freqsToString({Frequency::minVocal, Frequency::maxVocal}, true, true);
                    b.emplace_back(OctaveBand(Frequency::minVocal, center, Frequency::maxVocal, center));
                }
                else
                {
                    a = OctaveBandFrequencies::getCenterFreqs(bw, Frequency::min, Frequency::max, false);
                    n = OctaveBandFrequencies::getCenterFreqs(bw, Frequency::min, Frequency::max, true);
                    s = OctaveBandFrequencies::freqsToString(n);
                    b = OctaveBandFrequencies::getBands(bw, Frequency::min, Frequency::max);
                } 

                map.emplace(std::make_pair(bw, CoverageMapFreqs(bw, bandwidthToString(bw), a, n, s, b)));
            }
        }

        return map;
    }


    /**
        * method      	getCoverageMapCenterFreqs(Bandwidth bw, bool nominal)
        *					
        * \param      	bw      : Bandwidth
        * \param      	nominal : Nominal or actual center frequencies
        *					
        * \return     	Freqs&  : Frequencies
        *					
        * \brief      	Helper to get center freqs by bandwidth. See also getCoverageMapFreqs
        *                 
        * \details    	This just nullifies the tedium of calling getCoverageMapFreqs and searching for bw
        */
    static inline const Freqs& getCoverageMapCenterFreqs(Bandwidth bw, bool nominal)
    {
        static const Freqs doh;

        auto it = getCoverageMapFreqs().find(bw);
                
        return it == getCoverageMapFreqs().cend() ? doh : (nominal ? it->second.getNominalCenterFreqs() : it->second.getActualCenterFreqs());
    }

}//bosepro::acoustics

#endif //COVERAGEMAPFREQS_H
