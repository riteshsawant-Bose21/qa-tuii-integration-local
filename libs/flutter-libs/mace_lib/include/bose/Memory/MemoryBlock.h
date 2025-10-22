#pragma once
#ifndef MEMORYBLOCK_H
#define MEMORYBLOCK_H

#include <cmath>
#include <functional>
#include <vector>
#include <algorithm>
#include <type_traits>
#include <cassert>
#include <initializer_list>
#include <sstream>
#include <iterator>
#include <limits>
#include <optional>
#include "Math/MathUtils.h"

//TODO //ADB add expression templates

namespace bosepro
{
    /**
     * \class       MemoryBlock
     *
     * \brief       Helper object for managing heap allocated contiguous memory blocks of arithmetic types
     *               and easily performing various arithmetic operations upon them in an optimized manner.
     *
     * \details     The impetus for, and benefit of, this class is threefold:
     *                  1. Error reduction and leak prevention when dealing with heap memory
     *                  2. Facilitates easy alteration of memory management methods
     *                  3. Facilitation of performance related efforts such as aligned blocks or similar
     *
     *               Many methods are optimized to leverage auto vectorization. See compiler flags.
     *
     *               There are aliases for common primitives at the bottom of this file
     *
     *               See also MemoryBlockMatrix
     */
    template <typename Type>
    class MemoryBlock final
    {
    public:
                                ~MemoryBlock()                                                          {free();}

                                MemoryBlock()                                               noexcept    : m_Size(0), m_Block(nullptr) {}
        explicit                MemoryBlock(const Type* const other, std::size_t size)                  : MemoryBlock() {if(resize(size)){std::copy_n(other, size, m_Block);}}
                                MemoryBlock(std::initializer_list<Type> init)                           : MemoryBlock() {if(resize(init.size())){std::copy(init.begin(), init.end(), m_Block);}} 
        explicit                MemoryBlock(std::size_t size, Type init = 0)                            : MemoryBlock() {resize(size, init);}
        explicit                MemoryBlock(std::size_t size, Type init, Type step)                     : MemoryBlock() {resize(size); set(init, step);}
        explicit                MemoryBlock(const std::vector<Type>& other)                             : MemoryBlock(other.data(), other.size()){}
                                MemoryBlock(const MemoryBlock& other)                                   : MemoryBlock() {if(resize(other.m_Size)){std::copy_n(other.m_Block, other.m_Size, m_Block);}}
                                MemoryBlock(MemoryBlock&& other)                            noexcept    : m_Size(other.m_Size), m_Block(other.m_Block){other.m_Size = 0; other.m_Block = nullptr;}

        MemoryBlock&            operator=(MemoryBlock&& other)                              noexcept    {free(); swap(*this, other); return *this;}
        MemoryBlock&            operator=(const MemoryBlock& other)                                     {auto tmp(other); swap(*this, tmp); return *this;}

                                //NaN aware equality operators (exact, see also fuzzyEqual)
        friend bool             operator!=(const MemoryBlock& lhs, const MemoryBlock& rhs)              {return !(lhs == rhs);}
        friend bool             operator==(const MemoryBlock& lhs, const MemoryBlock& rhs)
                                {
                                    bool equal = false;

                                    if(lhs.size() == rhs.size())
                                    {
                                        equal = true;

                                        //not auto vectorizable
                                        for(std::size_t i = 0; i < lhs.size(); ++i)
                                        {
                                            //NaN's are never equal, so ensure we aren't 
                                            //comparing nan's before declaring inequality
                                            if(lhs[i] != rhs[i] && 
                                              (!std::isnan(static_cast<double>(lhs[i])) && 
                                               !std::isnan(static_cast<double>(rhs[i]))))
                                            {
                                                equal = false;
                                                break;
                                            }
                                        }
                                    }

                                    return equal;
                                }

                                //NaN aware equality for all elements having same value
        inline bool             operator!=(Type val)                                const   noexcept    {return !(operator==(val));}
        inline bool             operator==(Type val)                                const   noexcept
                                {
                                    //VS 16.4.6 errors w/C2668 without the cast
                                    const std::function<bool(Type v)> fnEqual = [val](Type v)->bool{return v == val || (std::isnan(static_cast<double>(val)) && std::isnan(static_cast<double>(v)));};

                                    return isValid() ? std::find_if_not(cbegin(), cend(), fnEqual) == cend() : false;
                                }


                                //Subscript operators (without bounds checking)
        Type&                   operator[](std::size_t index)                               noexcept    {assert(index < m_Size); return m_Block[index];}
        const Type&             operator[](std::size_t index)                       const   noexcept    {assert(index < m_Size); return m_Block[index];}

                                //Subscript operator  (with bounds checking)
        Type                    operator()(std::size_t index)                       const   noexcept    {assert(index < m_Size); return index < m_Size ? m_Block[index] : Type(0);}

                                //Arithmetic operators
        friend MemoryBlock      operator+(MemoryBlock lhs, const MemoryBlock& rhs)                      {return lhs += rhs;}
        friend MemoryBlock      operator-(MemoryBlock lhs, const MemoryBlock& rhs)                      {return lhs -= rhs;}
        friend MemoryBlock      operator*(MemoryBlock lhs, const MemoryBlock& rhs)                      {return lhs *= rhs;}
        friend MemoryBlock      operator/(MemoryBlock lhs, const MemoryBlock& rhs)                      {return lhs /= rhs;}

        friend MemoryBlock      operator+(MemoryBlock lhs, Type rhs)                                    {return lhs += MemoryBlock(lhs.size(), rhs);}
        friend MemoryBlock      operator-(MemoryBlock lhs, Type rhs)                                    {return lhs -= MemoryBlock(lhs.size(), rhs);}
        friend MemoryBlock      operator*(MemoryBlock lhs, Type rhs)                                    {return lhs *= MemoryBlock(lhs.size(), rhs);}
        friend MemoryBlock      operator/(MemoryBlock lhs, Type rhs)                                    {return lhs /= MemoryBlock(lhs.size(), rhs);}

        friend MemoryBlock      operator-(Type lhs, MemoryBlock rhs)                                    {return MemoryBlock(rhs.size(), lhs) / rhs;}
        friend MemoryBlock      operator/(Type lhs, MemoryBlock rhs)                                    {return MemoryBlock(rhs.size(), lhs) / rhs;}

                                //Compound Arithmetic operators
        MemoryBlock&            operator+=(Type rhs)                                                    {return *this += MemoryBlock(size(), rhs);}
        MemoryBlock&            operator-=(Type rhs)                                                    {return *this -= MemoryBlock(size(), rhs);}
        MemoryBlock&            operator*=(Type rhs)                                                    {return *this *= MemoryBlock(size(), rhs);}
        MemoryBlock&            operator/=(Type rhs)                                                    {return *this /= MemoryBlock(size(), rhs);}

        MemoryBlock&            operator+=(const MemoryBlock& rhs)
                                {
                                    assert(size() == rhs.size());

                                    if(size() == rhs.size())
                                    {
                                        //Allow us to be auto vectorizable
                                        const std::size_t n = m_Size;

                                        //loop vectorized
                                        for(std::size_t i = 0; i < n; ++i)
                                        {
                                            m_Block[i] += rhs[i];
                                        }
                                    }

                                    return *this;
                                }

        MemoryBlock&            operator-=(const MemoryBlock& rhs)
                                {
                                    assert(size() == rhs.size());

                                    if(size() == rhs.size())
                                    {
                                        //Allow us to be auto vectorizable
                                        const std::size_t n = m_Size;

                                        //loop vectorized
                                        for(std::size_t i = 0; i < n; ++i)
                                        {
                                            m_Block[i] -= rhs[i];
                                        }
                                    }

                                    return *this;
                                }

        MemoryBlock&            operator*=(const MemoryBlock& rhs)
                                {
                                    assert(size() == rhs.size());

                                    if(size() == rhs.size())
                                    {
                                        //Allow us to be auto vectorizable
                                        const std::size_t n = m_Size;

                                        //loop vectorized
                                        for(std::size_t i = 0; i < n; ++i)
                                        {
                                            m_Block[i] *= rhs[i];
                                        }
                                    }

                                    return *this;
                                }

        MemoryBlock&            operator/=(const MemoryBlock& rhs)
                                {
                                    assert(size() == rhs.size());

                                    if(size() == rhs.size())
                                    {
                                        //loop not vectorized due to reason '501'
                                        for(std::size_t i = 0; i < m_Size; ++i)
                                        {
                                            m_Block[i] = math::SafeDivide(m_Block[i], rhs[i]);
                                        }
                                    }

                                    return *this;
                                }

                                //Unary negation
        friend MemoryBlock      operator-(MemoryBlock rhs)
                                {
                                    //Allow us to be auto vectorizable
                                    const std::size_t n = rhs.m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        rhs.m_Block[i] = -rhs.m_Block[i];
                                    }

                                    return rhs;
                                }

                                //Fuzzy equality with error tolerance (NaN aware)
        inline bool             fuzzyEqual(const MemoryBlock& rhs, double err = 1e-12)    const
                                {
                                    bool equal = false;

                                    if(size() == rhs.size())
                                    {
                                        if(isValid())
                                        {
                                            equal = true;

                                            const auto& lhs = *this;

                                            //not auto vectorizable
                                            for (std::size_t i = 0; i < lhs.size(); ++i)
                                            {
                                                //Check nan parity
                                                bool lnan = std::isnan(lhs[i]);
                                                bool rnan = std::isnan(rhs[i]);
                                                bool bnan = lnan & rnan;

                                                if (!bnan && (lnan != rnan || std::abs(lhs[i] - rhs[i]) > err))
                                                {
                                                    equal = false;
                                                    break;
                                                }
                                            }
                                        }
                                        else
                                        {
                                            //Both are empty, so that's equality too
                                            equal = true;
                                        }
                                    }

                                    return equal;

                                    static_assert(std::is_floating_point<Type>(), "Error: floating point type required");
                                }

                                //Absolute value
        MemoryBlock             abs()                                               const
                                {
                                    auto tmp(*this);

                                    //Allow us to be auto vectorizable
                                    const std::size_t n = tmp.m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        tmp.m_Block[i] = std::abs(tmp.m_Block[i]);
                                    }

                                    return tmp;
                                }

                                //Sum of elements
        Type                    sum()                                               const
                                {
                                    Type val = 0;

                                    //Allow us to be auto vectorizable
                                    const std::size_t n = m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        val += m_Block[i];
                                    }

                                    return val;
                                }

                                //Get min/max values (ignores Nan's)
        Type                    min()                                               const               {return isValid() ? (*this)[indexOfMin()] : Type(0);} 
        Type                    max()                                               const               {return isValid() ? (*this)[indexOfMax()] : Type(0);} 

                                //Get index of min/max value (ignores Nan's)
        std::size_t             indexOfMin(std::size_t start = 0)                        const   noexcept    { assert(start < m_Size); return math::indexOfMinElement(cbegin() + start, cend());}
        std::size_t             indexOfMax(std::size_t start = 0)                        const   noexcept    { assert(start < m_Size); return math::indexOfMaxElement(cbegin() + start, cend());}

                                //Clamp to range
        MemoryBlock             clamped(Type min, Type max)                         const   noexcept    {return MemoryBlock(*this).clamp(min, max);}
        MemoryBlock&            clamp(Type min, Type max)                                   noexcept
                                {
                                    //loop not vectorized due to reason '1200'
                                    for(std::size_t i = 0; i < m_Size; ++i)
                                    {
                                        m_Block[i] = math::Clamp(m_Block[i], min, max);
                                    }

                                    return *this;
                                }

                                //Compute cosine for each element
        MemoryBlock             cos()                                           const
                                {
                                    auto tmp(*this);

                                    //Allow us to be auto vectorizable
                                    const std::size_t n = tmp.m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        tmp.m_Block[i] = std::cos(tmp.m_Block[i]);
                                    }

                                    return tmp;
                                }

                                //Compute sine for each element
        MemoryBlock             sin()                                           const
                                {
                                    auto tmp(*this);

                                    //Allow us to be auto vectorizable
                                    const std::size_t n = tmp.m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        tmp.m_Block[i] = std::sin(tmp.m_Block[i]);
                                    }

                                    return tmp;
                                }

                                //Raises e to the power of each element
        MemoryBlock             exp()                                           const
                                {
                                    auto tmp(*this);

                                    //Allow us to be auto vectorizable
                                    const std::size_t n = tmp.m_Size;

                                    //loop vectorized
                                    for(std::size_t i = 0; i < n; ++i)
                                    {
                                        tmp.m_Block[i] = std::exp(tmp.m_Block[i]);
                                    }

                                    return tmp;
                                }

                                //Apply unary function to each value
        MemoryBlock             applied(std::function<Type(Type)> func)         const               {return MemoryBlock(*this).apply(func);}
        MemoryBlock&            apply(std::function<Type(Type)> func)
                                {
                                    assert(func);

                                    if(func != nullptr)
                                    {
                                        const std::size_t n = m_Size;

                                        //loop not vectorized due to reason '1200'
                                        for(std::size_t i = 0; i < n; ++i)
                                        {
                                            m_Block[i] = func(m_Block[i]);
                                        }
                                    }

                                    return *this;
                                }

                                //Round to # points of precision
        MemoryBlock             roundedTo(unsigned int pointsOfPrecision) const {return MemoryBlock(*this).roundTo(pointsOfPrecision);}
        MemoryBlock&            roundTo(unsigned int pointsOfPrecision)
                                {
                                    //Constrain to reasonable precision
                                    pointsOfPrecision = std::min(static_cast<int>(pointsOfPrecision), std::numeric_limits<Type>::digits10);

                                    const Type scale = std::pow(10.0, static_cast<Type>(pointsOfPrecision));

                                    if(scale > 0.0)
                                    {
                                        const std::function<Type(Type)> fnFloor = [scale](Type v)->Type{return std::floor(v * scale + Type(0.5));};

                                        apply(fnFloor);

                                        *this *= 1.0/scale;
                                    }

                                    return *this;

                                    static_assert(std::is_floating_point<Type>(), "Error: floating point type required");
                                }

        enum class              Category{NaN = 0x1, Inf = 0x2, Subnormal = 0x4, NegativeZero = 0x8, All = 0xf};

                                //Purge by Category, size() can change. See also replace
        MemoryBlock             purged(Category cat = Category::NaN)                   const noexcept {return MemoryBlock(*this).purge(cat);}
        MemoryBlock&            purge(Category cat = Category::NaN)                          noexcept
                                {
                                    if(isValid())
                                    {
                                        bool purge = false;

                                        std::vector<Type> tmp;
                                        
                                        //loop not vectorized
                                        for(std::size_t i = 0; i < m_Size; ++i)
                                        {
                                            purge = false;

                                            const auto& vi = m_Block[i];

                                            if((cat == Category::NaN || cat == Category::All) && std::isnan(vi))
                                            {
                                                purge = true;
                                            }
                                            else if((cat == Category::Inf || cat == Category::All) && std::isinf(vi))
                                            {
                                                purge = true;
                                            }
                                            else if((cat == Category::Subnormal || cat == Category::All) && std::fpclassify(vi) == FP_SUBNORMAL)
                                            {
                                                purge = true;
                                            }
                                            else if((cat == Category::NegativeZero || cat == Category::All) && vi == 0.0 && std::signbit(vi))
                                            {
                                                purge = true;
                                            }

                                            if(!purge)
                                            {
                                                tmp.emplace_back(vi);
                                            }
                                        }

                                        //Replace this with purged subset
                                        *this = MemoryBlock(tmp);
                                    }

                                    return *this;
                                }

                                //Replace by Category : size() does not change. Sign is ignored for Nan, Inf & Subnormal testing. See also replace(Type) and purge(Category)
        MemoryBlock             replaced(Category cat, Type with = 0)                  const noexcept {return MemoryBlock(*this).replace(cat, with);}
        MemoryBlock&            replace(Category cat, Type with = 0)                         noexcept
                                {
                                    //loop not vectorized
                                    for(std::size_t i = 0; i < m_Size; ++i)
                                    {
                                        auto& vi = m_Block[i];

                                        if((cat == Category::NaN || cat == Category::All) && std::isnan(vi))
                                        {
                                            vi = with;
                                        }
                                        else if((cat == Category::Inf || cat == Category::All) && std::isinf(vi))
                                        {
                                            vi = with;
                                        }
                                        else if((cat == Category::Subnormal || cat == Category::All) && std::fpclassify(vi) == FP_SUBNORMAL)
                                        {
                                            vi = with;
                                        }
                                        else if((cat == Category::NegativeZero || cat == Category::All) && vi == 0.0 && std::signbit(vi))
                                        {
                                            vi = with;
                                        }
                                    }

                                    return *this;
                                }

                                //Replace by value, with fuzzy equality and replace non-nornal support. ±0 is treated identically. See also replace(Category) and purge(Category)
        MemoryBlock             replaced(Type val, Type with, double fuzzyErr = 1e-12)   const noexcept {return MemoryBlock(*this).replace(val, with, fuzzyErr);}
        MemoryBlock&            replace(Type val, Type with, double fuzzyErr = 1e-12)          noexcept
                                {
                                    const auto c = std::fpclassify(val);

                                    //Handle normals and zeros with fuzzy equality check
                                    if(c == FP_NORMAL || c == FP_ZERO)
                                    {
                                        const std::function<bool(Type, Type)> fnEqual = [fuzzyErr](Type lhs, Type rhs)->bool{return std::abs(lhs-rhs) <= fuzzyErr;};

                                        //loop not vectorized
                                        for(std::size_t i = 0; i < m_Size; ++i)
                                        {
                                            if(fnEqual(val, m_Block[i]))
                                            {
                                                m_Block[i] = with;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        //Handle non-normals (sans zero) as replace by category
                                        switch(c)
                                        {
                                            case FP_INFINITE:  replace(Category::Inf, with);        break;
                                            case FP_NAN:       replace(Category::NaN, with);        break;
                                            case FP_SUBNORMAL: replace(Category::Subnormal, with);  break;
                                            default:                                                break;
                                        }
                                    }

                                    return *this;
                                }

                                //Iterator for range-base loops 
        inline auto             begin()                                                     noexcept    {return m_Block;}
        inline auto             end()                                                       noexcept    {return m_Block + m_Size;}

        inline decltype(auto)   cbegin()                                            const   noexcept    {return m_Block;}
        inline decltype(auto)   cend()                                              const   noexcept    {return m_Block + m_Size;}

        inline auto             rbegin()                                                    noexcept    {return std::reverse_iterator(end());}
        inline auto             rend()                                                      noexcept    {return std::reverse_iterator(begin());}

        inline decltype(auto)   crbegin()                                           const   noexcept    {return std::reverse_iterator(cend());}
        inline decltype(auto)   crend()                                             const   noexcept    {return std::reverse_iterator(cbegin());}//ADB deal with this shit

                                //Conversion operator accessor
        Type* const             get()                                                       noexcept    {return m_Block;}
        const Type* const       get()                                               const   noexcept    {return m_Block;}

                                //Swap contents
        inline friend void      swap(MemoryBlock& lhs, MemoryBlock& rhs)                    noexcept    {std::swap(lhs.m_Size,  rhs.m_Size); std::swap(lhs.m_Block, rhs.m_Block);}

                                //Num elements
        inline std::size_t      size()                                              const   noexcept    {return m_Size;}

                                //Validity test
        inline bool             isValid()                                           const   noexcept    {return m_Block != nullptr && m_Size > 0;}

                                //Set all elements to zero
        inline bool             zero()                                                                  {return set(Type(0));}

                                //Tests if all elements are zero 
        inline bool             isZero()                                            const               {return operator==(Type(0));}

                                //Tests if all elements are + or -
        inline bool             isPositive()                                        const               {return isValid() ? std::find_if_not(cbegin(), cend(), [&](auto const& v){return !std::signbit(v);}) == cend() : false;}
        inline bool             isNegative()                                        const               {return isValid() ? std::find_if_not(cbegin(), cend(), [&](auto const& v){return  std::signbit(v);}) == cend() : false;}

                                //Set all elements to specific value
        inline bool             set(Type val)                                                           {if(isValid()){std::fill_n(m_Block, m_Size, val);} return isValid();}//Nothing to vectorize

                                //Set elements sequentially, from start with step interval
        inline bool             set(Type start, Type step)                                              {if(isValid()){start-=step; std::generate(begin(), end(), [&start, step](){return start += step;});} return isValid();}

                                //Deallocate
        inline void             free()                                                      noexcept    {if(m_Block != nullptr){delete[] m_Block; m_Block = nullptr; m_Size  = 0;}}

                                //Resize : returns isValid()
        bool                    resize(std::size_t size, Type init = Type(0))
                                {
                                    //Deallocate on any size disparity
                                    if(m_Size != size && m_Size > 0)
                                    {
                                        free();
                                    }

                                    //Allocate if necessary
                                    if(size > 0 && !isValid())
                                    {
                                        if((m_Block = (new Type[size]())))
                                        {
                                            m_Size = size;

                                            if(init != Type(0))
                                            {
                                                set(init);
                                            }
                                        }
                                        else
                                        {
                                            throw std::bad_alloc();
                                        }
                                    }

                                    return isValid();
                                }

                                //Bilinear interpolation : Auto vectorizable
        static MemoryBlock      interpolationBilinear(const MemoryBlock& h1, const MemoryBlock& h2, const MemoryBlock& h3, const MemoryBlock h4, Type x, Type y)
                                {
                                    MemoryBlock blerp;

                                    if(h1.isValid() && h2.isValid() && h3.isValid() && h4.isValid())
                                    {
                                        if(h1.size() == h2.size() && h2.size() == h3.size() && h3.size() == h4.size())
                                        {
                                            const std::size_t size = h1.size();

                                            blerp.resize(size);

                                            Type i0	= Type(0);
                                            Type i1	= Type(0);

                                            //Raw ptr's allow us to be auto vectorizable
                                            auto p1 = h1.get();
                                            auto p2 = h2.get();
                                            auto p3 = h3.get();
                                            auto p4 = h4.get();
                                            auto pr = blerp.get();

                                            if(p1 != nullptr && p2 != nullptr && p3 != nullptr && p4 != nullptr && pr != nullptr)
                                            {
                                                //loop vectorized
                                                for(std::size_t i = 0; i < size; ++i)
                                                {
                                                    //Interpolate along x
	                                                i0	= ((p2[i] - p1[i]) * x) + p1[i];
	                                                i1	= ((p4[i] - p3[i]) * x) + p3[i];

	                                                //Interpolate along y
	                                                pr[i] = ((i1 - i0) * y) + i0;
                                                }
                                            }
                                            else
                                            {
                                                //Should never be! isValid() is a ptr test!
                                                assert(0);
                                            }
                                        }
                                    }

                                    return blerp;
                                }

                                //Spline interpolation : Not auto vectorizable (TODO: check auto vec)
        static MemoryBlock      interpolationSpline(const MemoryBlock& xSrc, const MemoryBlock& ySrc, const MemoryBlock& xQuery)
                                {                                    
                                    const auto numX = xQuery.size();
                                    MemoryBlock output(numX);
                                                                        
                                    auto coefs = splineCoeffs(xSrc, ySrc); // use MATLAB method of spline ported for use here.

                                    // consider if necessary given typical workload.
                                    //#pragma omp parallel for \
        	                        // num_threads(omp_get_max_threads()) \
        	                        // private(ip,v,xloc,ic)

                                    for (size_t ix = 1; ix <= numX; ix++)
                                    {
                                        double v;
                                        if (coefs[0].size() > 1 && std::isnan(xQuery[ix - 1]))
                                        {
                                            v = xQuery[ix - 1];
                                        }
                                        else
                                        {
                                            size_t ip = 0;
                                            if (xSrc.size() != 3)
                                            {
                                                ip = (std::lower_bound(xSrc.cbegin(), xSrc.cend(), xQuery[ix - 1]) - xSrc.cbegin());
                                                ip = std::min(ip, xSrc.size() - 1); // don't let be end (if past)
                                                if (ip > 0)
                                                {
                                                    ip--;
                                                }
                                            }

                                            auto xloc = xQuery[ix - 1] - xSrc[ip];
                                            v = coefs[ip].at(0);
                                            for (size_t ic = 1; ic < coefs[ip].size(); ic++) // do the rest
                                            {
                                                v = xloc * v + coefs[ip].at(ic);
                                            }
                                        }
                                        output[ix - 1] = v;
                                    }
                                    return output;
                                }


                                //Linear interpolation : Not auto vectorizable
        static MemoryBlock      interpolationLinear(const MemoryBlock& xSrc, const MemoryBlock& ySrc, const MemoryBlock& xDst)
                                {
                                    MemoryBlock lerp;

                                    if(xSrc.isValid() && ySrc.isValid() && xDst.isValid() && xSrc.size() == ySrc.size())
                                    {
                                        const std::size_t srcSize = xSrc.size();
                                        const std::size_t dstSize = xDst.size();

                                        lerp.resize(dstSize);

                                        //dst points
                                        Type x  = Type(0);

                                        //src points
                                        Type x0 = Type(0);
                                        Type x1 = Type(0);
                                        Type y0 = Type(0);
                                        Type y1 = Type(0);

                                        std::size_t d = 0;

                                        //Find index where xDst is >= xSrc
                                        for(std::size_t i = 0; i < dstSize; ++i)
                                        {
                                            if(xDst[i] >= xSrc[0])
                                            {
                                                d = i > 0 ? i - 1 : 0;
                                                break;
                                            }
                                        }

                                        //Note start point
                                        const auto c = d;

                                        for(std::size_t s = 0; s < srcSize - 1; ++s)
                                        {
                                            x0 = xSrc[s];
                                            x1 = xSrc[s + 1];

                                            y0 = ySrc[s];
                                            y1 = ySrc[s + 1];

                                            x  = xDst[d];

                                            while(x <= x1)
                                            {
                                                //linear interp of unknown y at known x from interval x0, x1
                                                lerp[d] = y0 + (x - x0) * math::SafeDivide((y1 - y0), (x1 - x0));

                                                if(++d >= dstSize)
                                                {
                                                    //Break outer loop
                                                    s = srcSize;
                                                    break;
                                                }

                                                x = xDst[d];
                                            }
                                        }

                                        //Fill leading zero's with first non-zero value
                                        if(c != 0)
                                        {
                                            std::fill_n(lerp.begin(), c, lerp[c]);
                                        }

                                        //Fill trailing zero's with last non-zero value
                                        if(d < dstSize)
                                        {
                                            std::fill_n(lerp.rbegin(), dstSize - d, lerp[d - 1]);
                                        }
                                    }

                                    return lerp;
                                }

                                //Create tokenized string
        std::string             tokenize(std::string delim = "\t", std::streamsize precision = 9, std::ios::fmtflags fmt = std::ios::fixed) const
                                {
                                    std::string str;

                                    //Must have a delimiter
                                    assert(!delim.empty());

                                    if(!delim.empty() && isValid())
                                    {
                                        std::stringstream strm;

                                        if(precision != 0)
                                        {
                                            strm.precision(precision);
                                        }

                                        if(fmt != 0)
                                        {
                                            strm.setf(fmt);
                                        }

                                        for(std::size_t i = 0; i < m_Size; ++i)
                                        {
                                            if(i > 0)
                                            {
                                                strm << delim;
                                            }

                                            strm << m_Block[i];
                                        }

                                        str = strm.str();
                                    }

                                    return str;
                                }

    private:

        static auto             splineCoeffs(const MemoryBlock<double>& x, const MemoryBlock<double>& y)
                                {
                                    // Method was splinepp in export.  Port of spline using Matlab Coder app to C then refined code to reduce down to essentials.
                                    // Tested exactly matching Matlab results.  So this is not a traditional Hermite Spline, nor a Cubic Spline.  A form of Hermite is used (divided differences approach) but
                                    // the special sauce is endpoint handling as well as slopes around neigboring values.  The result is a better correlation to real data.
                                    // Something that the prior attemps with Burden's Numerical Analysis, and Carl de Boor's Practical Guide to Splines approaches didn't do, nor the
                                    // academic piecewise Hermite Spline.  Unlike Matlab, this method employs safe divides to avoid NaNs 
                                    std::vector<std::vector<double>> pp_coefs;

                                    double dnnm2;
                                    int yoffset;
                                    double r;

                                    const auto nx = x.size();
                                    const auto numSeg = nx - 1;
                                    const bool has_endslopes = (y.size() == nx + 2);

                                    if (nx <= 2) // the interpolant is a straight line
                                    {
                                        pp_coefs.resize(1);
                                        if (has_endslopes)
                                        {   
                                            // inlined generated pwchcore for this case.
                                            auto dxj = x[1] - x[0];
                                            auto divdifij = math::SafeDivide((y[2] - y[1]) , dxj);
                                            auto dzzdx = math::SafeDivide((divdifij - y[y.size() - 1]), dxj);
                                            divdifij = math::SafeDivide((y[y.size() - 1] - divdifij), dxj);
                                            pp_coefs[0].push_back(math::SafeDivide((divdifij - dzzdx) , dxj));
                                            pp_coefs[0].push_back(2.0 * dzzdx - divdifij);
                                            pp_coefs[0].push_back(y[0]);
                                            pp_coefs[0].push_back(y[1]);
                                        }
                                        else
                                        {
                                            // we have two coeffcients for 1 segment
                                            pp_coefs[0].push_back(math::SafeDivide((y[1] - y[0]) , (x[1] - x[0])));
                                            pp_coefs[0].push_back(y[0]);
                                        }
                                    }
                                    else // 3 or more source points
                                    {
                                        MemoryBlock dx;
                                        MemoryBlock md;
                                        MemoryBlock dvdf;
                                        MemoryBlock s;

                                        if (nx == 3 && !has_endslopes) // the interpolant is a parabola
                                        {
                                            pp_coefs.resize(1);
                                            auto x1x0dif = x[1] - x[0];
                                            dnnm2 = math::SafeDivide((y[1] - y[0]), x1x0dif); // divided difference
                                            pp_coefs[0].push_back( math::SafeDivide((math::SafeDivide( (y[2] - y[1]) , (x[2] - x[1])) - dnnm2), (x[2] - x[0])) );
                                            pp_coefs[0].push_back(dnnm2 - pp_coefs[0].at(0) * x1x0dif);
                                            pp_coefs[0].push_back(y[0]);
                                            // 3 coefficients, 1 segment (ignoring middle)
                                        }
                                        else
                                        {
                                            double d31;
                                            if (has_endslopes)
                                            {
                                                dvdf.resize(y.size() - 3);
                                                s.resize(y.size() - 2); // account for two extra points provided, one on each end.
                                                yoffset = 1;
                                            }
                                            else // no endslopes, more than 3 points
                                            {
                                                dvdf.resize(y.size() - 1);
                                                s.resize(y.size());
                                                yoffset = 0;
                                            }

                                            dx.resize(nx);

                                            // do first one separately so we can combine loops where 2nd loop started with 1 and avoid branch in loop
                                            dx[0] = x[1] - x[0];
                                            d31 = y[yoffset + 1] - y[yoffset];
                                            dvdf[0] = math::SafeDivide(d31, dx[0]);

                                            for (size_t ix = 1; ix < numSeg; ix++)
                                            {
                                                dx[ix] = x[ix + 1] - x[ix];
                                                d31 = y[(yoffset + ix) + 1] - y[yoffset + ix];
                                                dvdf[ix] = math::SafeDivide(d31, dx[ix]);
                                                s[ix] = 3.0 * (dx[ix] * dvdf[ix - 1] + dx[ix - 1] * dvdf[ix]);
                                            }

                                            if (has_endslopes)
                                            {
                                                d31 = 0.0;
                                                dnnm2 = 0.0;
                                                s[0] = dx[1] * y[0];
                                                s[nx - 1] = dx[nx - 3] * y[nx + 1];
                                            }
                                            else
                                            {
                                                d31 = x[2] - x[0]; // d31 name most likely 3 minus 1.
                                                dnnm2 = x[nx - 1] - x[nx - 3]; // dnnm2 name most likely n minus 2
                                                s[0] = math::SafeDivide(((dx[0] + 2.0 * d31) * dx[1] * dvdf[0] +
                                                    dx[0] * dx[0] * dvdf[1]) , d31);
                                                s[nx - 1] = math::SafeDivide(((dx[nx - 2] + 2.0 * dnnm2) *
                                                    dx[nx - 3] * dvdf[nx - 2] + dx[nx - 2] * dx[nx - 2] * dvdf[nx - 3]) , dnnm2);
                                            }

                                            md.resize(nx);

                                            md[0] = dx[1];
                                            md[nx - 1] = dx[nx - 3];

                                            md[1] = 2.0 * (dx[1] + dx[0]); // do first separately to combine loops where 2nd starts at 2

                                            r = math::SafeDivide(dx[1], md[0]);
                                            md[1] -= r * d31;
                                            s[1] -= r * s[0];
                                            for (size_t ix = 2; ix < numSeg; ix++)
                                            {
                                                md[ix] = 2.0 * (dx[ix] + dx[ix - 1]);
                                                r = math::SafeDivide(dx[ix], md[ix - 1]);
                                                md[ix] -= r * dx[ix - 2];
                                                s[ix] -= r * s[ix - 1];
                                            }

                                            // update last one.
                                            r = math::SafeDivide(dnnm2 , md[nx - 2]);
                                            md[nx - 1] -= r * dx[nx - 3];
                                            s[nx - 1] -= r * s[nx - 2];
                                            s[nx - 1] = math::SafeDivide(s[nx - 1], md[nx - 1]);
                                            // reverse loop (why? my thought is that we want the last value to affect those before), this updates slopes for each point discounting the ends.
                                            for (size_t ix = nx - 2; ix > 0; ix--)
                                            {
                                                s[ix] = math::SafeDivide((s[ix] - dx[ix - 1] * s[ix + 1]) , md[ix]);
                                            }

                                            // and do first one
                                            s[0] = math::SafeDivide((s[0] - d31 * s[1]), md[0]);

                                            pp_coefs.resize(numSeg);
                                            for (size_t ix = 0; ix < numSeg; ix++)
                                            {
                                                d31 = dx[ix];
                                                dnnm2 = math::SafeDivide((dvdf[ix] - s[ix]), d31);
                                                r = math::SafeDivide((s[ix + 1] - dvdf[ix]), d31);
                                                pp_coefs[ix].push_back(math::SafeDivide((r - dnnm2), d31));
                                                pp_coefs[ix].push_back(2.0 * dnnm2 - r);
                                                pp_coefs[ix].push_back(s[ix]);
                                                pp_coefs[ix].push_back(y[yoffset + ix]);
                                            }
                                        }
                                    } // 3 or more points
                                    return pp_coefs;
                                }

        std::size_t             m_Size  {0};
        Type*                   m_Block {nullptr};

        static_assert(std::is_arithmetic<Type>::value, "Error: arithmetic type must be used");
    };

    //Index
    using MBidx = MemoryBlock<std::size_t>;

    //64 bit aliases
    using MB64u = MemoryBlock<uint64_t>;
    using MB64i = MemoryBlock<int64_t>;
    using MB64f = MemoryBlock<double>; 

    //32 bit aliases
    using MB32u = MemoryBlock<uint32_t>;
    using MB32i = MemoryBlock<int32_t>;
    using MB32f = MemoryBlock<float>;

}//bosepro

#endif //MEMORYBLOCK_H