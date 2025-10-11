#pragma once
#ifndef WEIGHTING_H
#define WEIGHTING_H

#include <cassert>
#include <memory>
#include <vector>
#include "Lock/Lock.h"
#include "Memory/MemoryBlock.h"


namespace bosepro::measurement
{
    class Weighting;
    using WeightingPtr = std::unique_ptr<Weighting>;

    /**
	 * \class		Weighting
	 *
	 * \brief		Weighting interface
	 * \details		Weighting curves, in simple terms, are merely curves that are applied to other curves.
     *              In acoustics they are applied to frequency domain level values in an effort to account for 
     *              the relative loudness perceived by the human ear.
     *              Weighting is typically only applied to dB or power values.
	 *				NOTE: KA 3/24/2020 currently the weight() function only works with dB see curve
     *              However trying to use MagnitudeToPower didn't really work for the curve.  
     *              The weighting curve is really intended to be applied as dB.  
     *              Weighting in the frequency domain is the same as filtering in the time domain.
     *
     *              Thread safe
	 */
    class Weighting 
    {
    public:
        using Freqs                 = MemoryBlock<double>;
        using Data                  = MemoryBlock<double>;

        virtual                     ~Weighting()                          noexcept  = default;
                                    Weighting(std::string name)                     : m_name(std::move(name)){}
                                    Weighting(Weighting&&)                          = delete;
        Weighting&                  operator=(Weighting&&)                          = delete;

        virtual WeightingPtr        clone()                         const           = 0;

        std::string                 name()                          const noexcept  {return m_name;}

                                    //Freqs for weighting curve
        inline Freqs                getFreqs()                      const           {ScopedLock sl(getLock()); return m_Hz;}
        bool                        setFreqs(Freqs Hz);

                                    //Weighting function
        bool                        weight(Data& dB)                const;

    protected:
                                    //Force use of clone() for abstract base
                                    Weighting(const Weighting& other)               {ScopedLock sl(other.getLock()); m_name = other.m_name; m_Hz = other.m_Hz; m_curve = other.m_curve;}
        Weighting&                  operator=(const Weighting& other)               {if(this != &other){ScopedLockPair sl(getLock(), other.getLock()); m_name = other.m_name; m_Hz = other.m_Hz; m_curve = other.m_curve;} return *this;}

        inline const Lock&          getLock()                       const noexcept  {return m_lock;}

                                    //Create curve in dB for specified Hz
        virtual Data                curve(const Freqs& Hz)          const           = 0;

    private:
        Lock                        m_lock;
        std::string                 m_name;
        Freqs                       m_Hz;
        Data                        m_curve;
    };

    /**
	 * \class		WeightingA
	 *
	 * \brief		A-weighting as per IEC 61672-1:2003
	 *				Thread safe
	 */
    class WeightingA final : public Weighting 
    {
    public:
                                    ~WeightingA()          noexcept = default;
                                    WeightingA()           noexcept : Weighting(Type){}
                                    WeightingA(const WeightingA&)   = default;
                                    WeightingA(WeightingA&&)        = delete;
        WeightingA&                 operator=(const WeightingA&)    = default;
        WeightingA&                 operator=(WeightingA&&)         = delete;

        WeightingPtr                clone() const override {return std::make_unique<WeightingA>(*this);}

        static constexpr auto       Type = "A";

        Data                        curve(const Freqs& Hz)  const override;
    };

    /**
	 * \class		WeightingC
	 *
	 * \brief		C-weighting as per IEC 61672-1:2003
	 *				Thread safe
	 */
    class WeightingC final : public Weighting 
    {
    public:
                                    ~WeightingC()          noexcept = default;
                                    WeightingC()           noexcept : Weighting(Type){}      
                                    WeightingC(const WeightingC&)   = default;
                                    WeightingC(WeightingC&&)        = delete;
        WeightingC&                 operator=(const WeightingC&)    = default;
        WeightingC&                 operator=(WeightingC&&)         = delete;

        WeightingPtr                clone() const override {return std::make_unique<WeightingC>(*this);}

        static constexpr auto       Type = "C";

    protected:
        Data                        curve(const Freqs& Hz)  const override;
    };

    /**
	 * \class		WeightingZ
	 *
	 * \brief		Z-weighting as per IEC 61672-1:2003
	 *				Thread safe
	 */
    class WeightingZ final : public Weighting 
    {
    public:
                                    ~WeightingZ()          noexcept = default;
                                    WeightingZ()           noexcept : Weighting(Type){}      
                                    WeightingZ(const WeightingZ&)   = default;
                                    WeightingZ(WeightingZ&&)        = delete;
        WeightingZ&                 operator=(const WeightingZ&)    = default;
        WeightingZ&                 operator=(WeightingZ&&)         = delete;

        WeightingPtr                clone() const override {return std::make_unique<WeightingZ>(*this);}

        static constexpr auto       Type = "Z";

    protected:
        Data                        curve(const Freqs& Hz)  const override;
    };

    /**
	 * \class		WeightingFactory
	 *
	 * \brief		static object to maintain names of supported weighting types as well as creation thereof
	 *				See also Weighting, WeightingA, WeightingC, WeightingZ
	 */
    class WeightingFactory
    {
    public:
                                    ~WeightingFactory()                         = delete;
                                    WeightingFactory(const WeightingFactory&)   = delete;
                                    WeightingFactory(WeightingFactory&&)        = delete;
        WeightingFactory&           operator=(const WeightingFactory&)          = delete;
        WeightingFactory&           operator=(WeightingFactory&&)               = delete;

                                    //Create weighting object by name
        static WeightingPtr         getWeighting(const std::string& name) 
                                    {
                                        WeightingPtr ptr;

                                        if(name == WeightingA::Type)
                                        {
                                            ptr = std::make_unique<WeightingA>();
                                        }
                                        else if(name == WeightingC::Type)
                                        {
                                            ptr = std::make_unique<WeightingC>();
                                        }
                                        else if(name == WeightingZ::Type)
                                        {
                                            ptr = std::make_unique<WeightingZ>();
                                        }
                                        else
                                        {
                                            assert(0 && "Unknown weighting name");
                                        }

                                        return ptr;
                                    }

        using                       Names = std::vector<std::string>;

                                    //Weighting object names
        static Names                getNames() 
                                    {
                                        return {WeightingA::Type, WeightingC::Type, WeightingZ::Type};
                                    }
    };
}//bosepro::measurement

#endif //WEIGHTING_H