#pragma once
#ifndef COLOR_H
#define COLOR_H

#include <cassert>
#include <utility>
#include <algorithm>
#include "Math/MathUtils.h"


namespace bosepro::color
{
    /**
     * \class       Color
     *
     * \brief       Simple object to handle a RGBA quad
     *
     * \details     Has support for 32bit value conversions in RGBA and ARGB order
     *               Data is stored internally in OpenGL 4fv format, see also get4fv() 
     */
    class Color
    {
    public:
        using UInt8                     = uint_fast8_t;

	    enum class						Format{RGB, RGBA, ARGB};

									    Color()																	: _values{1.0f, 1.0f, 1.0f, 1.0f}{}
									
									    Color(float fRed, float fGreen, float fBlue, float fAlpha = 1.0f)		: Color() {set(fRed, fGreen, fBlue, fAlpha);}
									    Color(int iRed, int iGreen, int iBlue, int iAlpha = 0xff)				: Color() {set(iRed, iGreen, iBlue, iAlpha);}
									    Color(Color::Format eFormat, unsigned int rgb, float fAlpha = 1.0f)		: Color() {set(eFormat, rgb, fAlpha);}

									    Color(const Color& other)												: Color() {std::copy(other._values, other._values + _numValues, _values);}
									    Color(Color&& other)				                noexcept			: Color() {swap(*this, other);}

	    Color& 							operator=(const Color& other)									        {Color tmp(other); swap(*this, tmp); return *this; }
	    Color& 							operator=(Color&& other)	                        noexcept            {swap(*this, other); return *this;}

	    friend inline bool				operator==(const Color& lhs, const Color& rhs)                          {return lhs.toUInt(Color::Format::RGBA) == rhs.toUInt(Color::Format::RGBA);}
	    friend inline bool				operator!=(const Color& lhs, const Color& rhs)                          {return !(lhs == rhs);}

	    friend inline bool 				operator< (const Color& lhs, const Color& rhs)                          {return lhs.toUInt(Color::Format::RGBA) < rhs.toUInt(Color::Format::RGBA);}
	    friend inline bool 				operator> (const Color& lhs, const Color& rhs)                          {return rhs < lhs;}
	    friend inline bool 				operator<=(const Color& lhs, const Color& rhs)                          {return !(lhs > rhs);}
	    friend inline bool 				operator>=(const Color& lhs, const Color& rhs)                          {return !(lhs < rhs);}

	    friend void 					swap(Color& lhs, Color& rhs)                    noexcept
									    {
										    std::swap(lhs._values, rhs._values);
									    }

	    //Accessors
        inline const float* const		get4fv() const noexcept                                                 {return _values;} //RGBA

	    inline float					red()	 const noexcept                                                 {return get(Color::Channel::red);}
	    inline float					green()  const noexcept                                                 {return get(Color::Channel::green);}
	    inline float					blue()	 const noexcept                                                 {return get(Color::Channel::blue);}
	    inline float					alpha()  const noexcept                                                 {return get(Color::Channel::alpha);}

	    inline void						red(float   v) noexcept                                                 {set(Color::Channel::red,	v);}
	    inline void						green(float v) noexcept                                                 {set(Color::Channel::green,	v);}
	    inline void						blue(float  v) noexcept                                                 {set(Color::Channel::blue,	v);}
	    inline void						alpha(float v) noexcept                                                 {set(Color::Channel::alpha,	v);}

	    inline void						get(float& fRed, float& fGreen, float& fBlue, float& fAlpha)            const noexcept
									    {
										    fRed	= get(Channel::red);
										    fGreen	= get(Channel::green);
										    fBlue	= get(Channel::blue);
										    fAlpha	= get(Channel::alpha);
									    }

	    inline void						set(float fRed, float fGreen, float fBlue, float fAlpha = 1.0f)         noexcept
									    {
										    set(Channel::red,	fRed);
										    set(Channel::green,	fGreen);
										    set(Channel::blue,	fBlue);
										    set(Channel::alpha,	fAlpha);
									    }

	    inline void						set(int iRed, int iGreen, int iBlue, int iAlpha = 0xff)                 noexcept
									    {
										    float r = toFloat(toUInt8(iRed));
										    float g = toFloat(toUInt8(iGreen));
										    float b = toFloat(toUInt8(iBlue));
										    float a = toFloat(toUInt8(iAlpha));

										    set(r, g, b, a);
									    }

	    inline void						set(Color::Format eFormat, unsigned int rgb, float fAlpha = 1.0f)       noexcept
									    {
										    float r, g, b = 1.0f;
										    fromUint(eFormat, rgb, r, g, b, fAlpha);
										    set(r, g, b, fAlpha);
									    }

        // Mercilessly stolen from http://en.wikipedia.org/wiki/HSL_color_space
        // Gets the values of hue, saturation, lightness, and opacity from this RGB color 
        inline void						getHsla(float& hue, float& saturation, float& lightness, float& a)            const noexcept
                                        {
                                            const auto r = red(), b = blue(), g = green();
                                            const auto max = std::max({ r, g , b });
                                            const auto min = std::min({ r, g , b });

                                            float h, s;
                                            lightness = (max + min) / 2;

                                            if (max == min)
                                            {
                                                h = s = 0.0f; // achromatic
                                            }
                                            else
                                            {
                                                const auto rng = max - min;
                                                s = lightness > 0.5 ? rng / (2 - max - min) : rng / max + min;

                                                if(max == r)
                                                {
                                                    h = (g - b) / rng + (g < b ? 6.0f : 0.0f);
                                                }
                                                else if(max == g)
                                                {
                                                    h = (b - r) / rng + 2.0f;
                                                }
                                                else
                                                {
                                                    h = (r - g) / rng + 4.0f;
                                                }

                                                h /= 6.0f;
                                            }

                                            hue = h;
                                            saturation = s;
                                            a = alpha();
                                        }

	    //Conversions
	    inline unsigned int				toUInt(Color::Format eFormat) const noexcept 
                                        {
                                            return Color::toUInt(eFormat, *this);
                                        }

	    static unsigned int				toUInt(Color::Format eFormat, const Color& clr) noexcept
									    {
										    return Color::toUInt(eFormat, clr.red(), clr.green(), clr.blue(), clr.alpha());
									    }

	    static unsigned int				toUInt(Color::Format eFormat, float fRed, float fGreen, float fBlue, float fAlpha = 1.0f) noexcept
									    {
										    UInt8 r = toUInt8(fRed);
										    UInt8 g = toUInt8(fGreen);
										    UInt8 b = toUInt8(fBlue);
										    UInt8 a = toUInt8(fAlpha);

										    unsigned int color = 0;

										    switch(eFormat)
										    {
											    case Color::Format::RGB:
												    color = (r | (g << 8)) | (b << 16);
												    break;

											    case Color::Format::RGBA:
												    color = (r | (g << 8)) | (b << 16) | (a << 24);
												    break;

											    case Color::Format::ARGB:
												    color = b | (g << 8) | (r << 16) | (a << 24);
												    break;

											    default:
												    assert(false);
												    break;
										    }

										    return color;
									    }

	    static void						fromUint(Color::Format eFormat, unsigned int rgb, float& fRed, float& fGreen, float& fBlue, float& fAlpha) noexcept
									    {
										    switch(eFormat)
										    {
											    case Color::Format::RGB:
												    fRed	= toFloat((UInt8)rgb);
												    fGreen	= toFloat((UInt8)(rgb >> 8));
												    fBlue	= toFloat((UInt8)(rgb >> 16));
												    fAlpha	= 1.0f;
												    break;

											    case Color::Format::RGBA:
												    fRed	= toFloat((UInt8)rgb);
												    fGreen	= toFloat((UInt8)(rgb >> 8));
												    fBlue	= toFloat((UInt8)(rgb >> 16));
												    fAlpha	= toFloat((UInt8)(rgb >> 24));
												    break;
			
											    case Color::Format::ARGB:
												    fAlpha	= toFloat((UInt8)(rgb >> 24));
												    fRed	= toFloat((UInt8)(rgb >> 16));
												    fGreen	= toFloat((UInt8)(rgb >> 8));
												    fBlue	= toFloat((UInt8)rgb);
												    break;

											    default:
												    assert(false);
												    break;

										    }
									    }

        // hue saturation lightness to RGBA color
        // HSLA values in 0-1
        static Color                    fromHsla(float hue, float saturation, float lightness, float alpha = 1.0f)
                                        {
                                            float r, g, b;
                                            // make range behave nicely
                                            const auto h = math::PositiveMod(hue, 1.0f),
									                    s = math::Clamp(saturation, 0.0f, 1.0f),
									                    l = math::Clamp(lightness, 0.0f, 1.0f);

                                            if (s == 0)
                                            {
                                                r = g = b = l; // achromatic
                                            }
                                            else
                                            {
                                                const auto q = l < 0.5f ? l * (1 + s) : l + s - l * s;
                                                const auto p = 2 * l - q;
                                                r = hue2rgb(p, q, h + 1.0f / 3.0f);
                                                g = hue2rgb(p, q, h);
                                                b = hue2rgb(p, q, h - 1.0f / 3.0f);
                                            }

                                            return Color(r, g, b, alpha);
                                        }

    protected:
        enum class						Channel{red, green, blue, alpha};

	    static unsigned int             index(Color::Channel e)         noexcept    {return static_cast<unsigned int>(e);}
                                                                               
	    inline void						set(Color::Channel e, float n)	noexcept    {_values[index(e)] = limit(n);}
        inline float					get(Color::Channel e) const		noexcept    {return _values[index(e)];}

        static float                    limit(float n)                  noexcept    {return n < 0.0f ? 0.0f : (n > 1.0f ? 1.0f : n);}
                                                                   
	    static UInt8                    toUInt8(int n)                  noexcept    {return static_cast<UInt8>(n <= 0 ? 0 : (n >= 255 ? 255 : static_cast<UInt8>(n)));}
	    static UInt8                    toUInt8(float n)                noexcept    {return static_cast<UInt8>(n <= 0.0f ? 0.0f : (n >= 1.0f ? 255 : static_cast<UInt8>(n * 255.0f)));}
	    static float                    toFloat(UInt8 n)                noexcept    {constexpr float a = 1.0f / 255.0f; return (n & 0xff) * a;}

                                        //Sanity check to ensure get4fv() doesn't get broke
                                        static_assert(static_cast<unsigned int>(Channel::red)   == 0, "Invalid enum value for Color::Channel::red");
                                        static_assert(static_cast<unsigned int>(Channel::green) == 1, "Invalid enum value for Color::Channel::green");
                                        static_assert(static_cast<unsigned int>(Channel::blue)  == 2, "Invalid enum value for Color::Channel::blue");
                                        static_assert(static_cast<unsigned int>(Channel::alpha) == 3, "Invalid enum value for Color::Channel::alpha");

                                        static float hue2rgb(float p, float q, float t)
                                        {
                                            if (t < 0) t += 1;
                                            if (t > 1) t -= 1;
                                            if (t < 1.0f / 6.0f) return p + (q - p) * 6 * t;
                                            if (t < 1.0f / 2.0f) return q;
                                            if (t < 2.0f / 3.0f) return p + (q - p) * (2.0f / 3.0f - t) * 6;
                                            return p;
                                        }

    private:
	    static constexpr int            _numValues = 4;

	    float							_values[_numValues];//OpenGL 4fv format
    };
}//bosepro::color

#endif //COLOR_H