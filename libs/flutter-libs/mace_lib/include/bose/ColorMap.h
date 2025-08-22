#pragma once
#ifndef COLORMAP_H
#define COLORMAP_H
#include "Color.h"

namespace bosepro::color
{		
    /**
     * \class       ColorMap
     *
     * \brief       Singleton interface for getting color values based on number provided. Main use is to centralize the color map information.
     *
     * \details     These values are global 
     */
    class ColorMap
    {
    public:
                                        ColorMap(const ColorMap&)             = delete;
                                        ColorMap& operator=(const ColorMap&)  = delete;
                                        ColorMap(ColorMap&&)                  = delete;
                                        ColorMap& operator=(ColorMap&&)       = delete;

        static ColorMap&                instance();

        virtual void                    reset()                                         = 0;

        virtual void                    getSplRange(double& lower, double& upper)     const = 0;
        virtual double                  getUpperSpl()                                 const   = 0;
        virtual double                  getLowerSpl()                                 const   = 0;

        virtual void                    setSplRange(double lower, double upper)                                     = 0; //Apply air loss to calculations
        virtual void                    setUpperSpl(double upper) = 0;
        virtual void                    setLowerSpl(double lower) = 0;
        virtual Color                   getColor(double value)                      const = 0;

    protected:
                                        ColorMap()                                       = default;
        virtual                         ~ColorMap()                                      = default;
    };
}//bosepro::color

#endif //COLORMAP_H