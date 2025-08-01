#pragma once
#ifndef OCTAVEBANDFREQUENCIES_H
#define OCTAVEBANDFREQUENCIES_H

#include <sstream>
#include <vector>
#include <cassert>
#include <algorithm>
#include "OctaveBand.h"
#include "Bandwidth.h"
#include "Math/MathUtils.h"

namespace bosepro::acoustics
{		
    using Freqs                 = std::vector<double>;
    using FreqStrings           = std::vector<std::string>;

	/**
	 * \class		OctaveBandFrequencies
	 *
	 * \brief		Static class to calc base 10 IEC freqs for fractional octave bands
	 * \details		Based on ISO 266	
	 *
	 *              Technically freqs for any fractional octave band can be calculated
	 *              However for ease of use, only octave and a finite set of fractional octaves are supported.
	 *
	 *              See also getCoverageMapFreqs() for a wrapper method for supported coverage map values.
	 */
	class OctaveBandFrequencies
    {
    public:
                                //Static class
                                OctaveBandFrequencies() = delete;

                                //Get center freqs at the specified bandwidth for all bands between minFreq & maxFreq inclusive
        static Freqs            getCenterFreqs(Bandwidth bw, const double& minFreq, const double& maxFreq, bool nominal = false)
								{
									Freqs freqs;

                                    assert(isFractionalOctave(bw) && minFreq > 0.0 && minFreq < maxFreq);

									if(isFractionalOctave(bw) && minFreq > 0.0 && minFreq < maxFreq)
									{
                                        unsigned fractionalOctave = bandwidthToUint(bw);

										double lower	= minFreq;
										double center	= 0.0;
										double upper	= 0.0;

										int band = 0;

										//get freqs below 1000Hz (exclusive)
										while(lower >= minFreq)
										{
											center = getFreqExact(fractionalOctave, --band, &lower, &upper);
                                            if (nominal)
                                            {
                                                center = getFreqNominal(center, fractionalOctave); // convert to nominal before testing!
                                            }

											if(center < minFreq)
											{
												break;
											}

											if(center >= minFreq)
											{
												freqs.emplace_back(center);
											}
										}

										//get freqs 1000Hz and above (inclusive)
										band  = 0;
										lower = 0.0;
										upper = 0.0;

										while(upper <= maxFreq)
										{
											center = getFreqExact(fractionalOctave, band++, &lower, &upper);
                                            if (nominal)
                                            {
                                                center = getFreqNominal(center, fractionalOctave); // convert to nominal before testing!
                                            }

											if(center > maxFreq)
											{
												break;
											}

											if(center >= minFreq)
											{
												freqs.emplace_back(center);
											}
										}
									}
                                        
									std::sort(freqs.begin(), freqs.end());

									return freqs;
								}

                                //Get full set of band freqs {lower edge, actual center, upper edge & nominal center}
	    static OctaveBands      getBands(Bandwidth bw, const double& minFreq, const double& maxFreq)
					            {
					                OctaveBands bands;
                                    
                                    assert(isFractionalOctave(bw) && minFreq > 0.0 && minFreq < maxFreq);

					                if(isFractionalOctave(bw) && minFreq > 0.0 && minFreq < maxFreq)
					                {
                                        const unsigned fractionalOctave = bandwidthToUint(bw);

					                	double lower = minFreq;
						                double upper = 0.0;

						                int band = 0;
                                    
										//get freqs below 1000Hz (exclusive)
										while(lower >= minFreq)
					                	{
							                const double center = getFreqExact(fractionalOctave, --band, &lower, &upper);
                                    
					                		if(center < minFreq)
					                		{
					                			break;
					                		}
                                    
					                		if(center >= minFreq)
					                		{
								                const double nominal = getFreqNominal(center, fractionalOctave);
                                    
					                			bands.emplace_back(OctaveBand(lower, center, upper, nominal));
					                		}
					                	}

										//get freqs 1000Hz and above (inclusive)
										band  = 0;
										lower = 0.0;
										upper = 0.0;

					                	while(upper <= maxFreq)
					                	{
							                const double center = getFreqExact(fractionalOctave, band++, &lower, &upper);
                                    
					                		if(center > maxFreq)
					                		{
					                			break;
					                		}
                                    
					                		if(center >= minFreq)
					                		{
								                const double nominal = getFreqNominal(center, fractionalOctave);
                                    
					                			bands.emplace_back(OctaveBand(lower, center, upper, nominal));
					                		}
					                	}
					                }
                                    
									std::sort(bands.begin(), bands.end());

					                return bands;
					            }

                                //Get freq as string w/without Hz|kHz suffix
        static FreqStrings      freqsToString(const Freqs& freqs, bool suffix = true, bool range = false)
							    {
							        FreqStrings strs;
                                        
                                    if(range && freqs.size() == 2)
                                    {
                                        strs.emplace_back(formatFreq(freqs[0], suffix) + " - " + formatFreq(freqs[1], suffix));
                                    }
                                    else
                                    {
                                        for(auto f : freqs)
                                        {
                                            strs.emplace_back(formatFreq(f, suffix));
                                        }
                                    }           

							        return strs;
							    }

    protected:
                                //Internal helper to convert bandwidth to unsigned
        static unsigned         bandwidthToUint(Bandwidth bw){return static_cast<unsigned>(bw);}

                                //Get exact center freq and optionally lower/upper edge freqs (index = 0 corresponds to 1000Hz)
	    static double           getFreqExact(unsigned fractionalOctave, int index, double* const pLowerFreq = nullptr, double* const pUpperFreq = nullptr)
						        {
						            double freq = 0.0;

									assert(fractionalOctave > 0);

						            if(fractionalOctave > 0)
						            {
						            	//Nominal frequency ratio @ base 10 : pow(10.0, 3/10)
						            	static constexpr double G = 1.9952623149688796013524553967395; 
                                    
						            	//Reference frequency
						            	static constexpr double fr = 1000.0;
                                    
										const double x   = static_cast<double>(index);
										const double b   = static_cast<double>(fractionalOctave);
										const double bbr = 1.0 / (2.0 * b);

						            	//Center for odd fractional octave
						            	freq = std::pow(G, x / b) * fr;
                                    
						            	if(pLowerFreq)
						            	{
						            		*pLowerFreq = std::pow(G, -bbr) * freq;
						            	}
                                    
						            	if(pUpperFreq)
						            	{
						            		*pUpperFreq = std::pow(G,  bbr) * freq;
						            	}
						            }
                                    
						            return freq;
						        }

                                //Get nominal center freq for given actual center freq
	    static double           getFreqNominal(double freq, unsigned fractionalOctave)
								{
                                    assert(freq > 0.0 && fractionalOctave > 0);

									if(freq > 0.0 && fractionalOctave > 0)
									{
									    //Calc shift for ease of rounding
									    const int iShift = static_cast<int>(math::SafeLog10(freq) - 1);

									    //Scale
									    freq /= std::pow(10.0, iShift);

									    //Odd or even fractional octave ?
									    if(fractionalOctave % 2 != 0.0)
									    {
										    //Odd fractional octave

										    freq *= 2.0;
									
										    freq = std::round(freq);

										    freq *= 0.5;

                                            //Only freq that doesn't behave out of entire 1-48 set as it rounds to 79Hz
										    if(freq == 79.5)
										    {
											    freq = 80.0;
										    }
									    }
									    else
									    {
										    //Even fractional octave

										    //Round to hundredths if less than 50, else tenths
										    freq = freq < 50.0 ? math::RoundToHundreths(freq) : math::RoundToTenths(freq);
									    }

									    freq *= std::pow(10.0, iShift);
									}

									return freq;
                                }

                                //Format freq as string, suffix = true will append Hz | kHz accordingly
        static std::string      formatFreq(double freq, bool suffix = true)
                                {
                                    std::stringstream fmt;
                                    fmt.setf(std::stringstream::fixed);

                                    assert(freq > 0.0);

                                    if(freq > 0.0)
                                    {
                                        const bool Hz = freq < 1000.0;

                                        if(!Hz)
							        	{
							        		freq *= 0.001;
							        	}
                                    
                                        //Get exponent so we can determine precision {0, 1, 2}
                                        const double exp = math::RealPartExponent(freq);

                                        if(exp == 0.0)
                                        {
                                            fmt.precision(0);
                                        }
                                        else
                                        {
                                            //Precision is 1 or 2 based on valid data. Example {1.25 kHz, 3.15 kHz, 6.3 kHz}
                                            if(math::RealPartExponent(math::RoundToHundreths(exp * 10.0)) == 0.0)
                                            {
                                                fmt.precision(1);
                                            }
                                            else
                                            {
                                                fmt.precision(2);
                                            }
                                        }

                                        fmt << freq;

							        	if(suffix)
							        	{
							        		fmt << (Hz ? " Hz" : " kHz");
							        	}
                                    }

                                    return fmt.str();
                                }
    };
}//bosepro

#endif //OCTAVEBANDFREQUENCIES_H