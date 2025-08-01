#pragma once
#ifndef BANDWIDTH_H
#define BANDWIDTH_H

#include <string>


namespace bosepro
{
	namespace acoustics
	{
        //Min/max freq for all things
        namespace Frequency
        {
            static constexpr double min      = 31.5;
            static constexpr double max      = 16000.0;

            //Vocal range
            static constexpr double minVocal = 1000.0;  
            static constexpr double maxVocal = 4000.0;
        }

       /**
        * \param    Enum        : Bandwidth
        *
        * \brief       Enum for bandwidth designations
        *
        * \details     See also OctaveBandFrequencies 
        */
       enum class                  Bandwidth {Broadband      = 0,
                                              Octave         = 1, 
                                              Third          = 3, 
                                              Sixth          = 6, 
                                              Twelfth        = 12, 
                                              TwentyFourth   = 24, 
                                              FortyEighth    = 48,
                                              AllBands       = -1,
                                              VocalBands     = -2};

                                    //Test if fractional octave (not broadband or isBandSum())
       static constexpr bool        isFractionalOctave(Bandwidth bw){return static_cast<int>(bw) >= 1;}

                                    //Test if band sum like AllBands or VocalBands
       static constexpr bool        isBandSum(Bandwidth bw){return static_cast<int>(bw) < 0;}

                                    //Get bandwidth as string
        static inline std::string   bandwidthToString(Bandwidth bw)
                                    {
                                        std::string str;

                                        switch(bw)
                                        {
                                            case Bandwidth::Broadband      : str = "Broadband"     ; break;
                                            case Bandwidth::Octave         : str = "Octave"        ; break;  
                                            case Bandwidth::Third          : str = "1/3 Octave"    ; break;     
                                            case Bandwidth::Sixth          : str = "1/6 Octave"    ; break;
                                            case Bandwidth::Twelfth        : str = "1/12 Octave"   ; break;
                                            case Bandwidth::TwentyFourth   : str = "1/24 Octave"   ; break;
                                            case Bandwidth::FortyEighth    : str = "1/48 Octave"   ; break;
                                            case Bandwidth::AllBands       : str = "All Bands"     ; break;
                                            case Bandwidth::VocalBands     : str = "Vocal Bands"   ; break;
                                        }

                                        return str;
                                    }

                                    //Get bandwidth from string
        static inline Bandwidth     bandwidthFromString(const std::string& str)
                                    {
                                        Bandwidth bw = Bandwidth::Broadband;
     
                                             if(str == "Octave")         bw = Bandwidth::Octave       ;
                                        else if(str == "1/3 Octave")     bw = Bandwidth::Third        ;
                                        else if(str == "1/6 Octave")     bw = Bandwidth::Sixth        ;
                                        else if(str == "1/12 Octave")    bw = Bandwidth::Twelfth      ;
                                        else if(str == "1/24 Octave")    bw = Bandwidth::TwentyFourth ;
                                        else if(str == "1/48 Octave")    bw = Bandwidth::FortyEighth  ;
                                        else if(str == "All Bands")      bw = Bandwidth::AllBands     ;
                                        else if(str == "Vocal Bands")    bw = Bandwidth::VocalBands   ;

                                        return bw;
                                    }

	}//acoustics
}//bosepro

#endif //BANDWIDTH_H