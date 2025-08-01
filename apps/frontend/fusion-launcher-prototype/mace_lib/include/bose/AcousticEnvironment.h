#pragma once
#ifndef ACOUSTICENVIRONMENT_H
#define ACOUSTICENVIRONMENT_H

namespace bosepro::acoustics
{
    /**
	 * \class		AcousticEnvironment
	 *
	 * \brief		Singleton interface for environmental factors that impact acoustic calculations
	 * \details		These values are global. Impl must be (is) thread safe
	 */
    class AcousticEnvironment
    {
    public:
                                        AcousticEnvironment(const AcousticEnvironment&)             = delete;
                                        AcousticEnvironment& operator=(const AcousticEnvironment&)  = delete;
                                        AcousticEnvironment(AcousticEnvironment&&)                  = delete;
                                        AcousticEnvironment& operator=(AcousticEnvironment&&)       = delete;

        static AcousticEnvironment&     instance();


        virtual bool                    getUseAirLoss()                                     const   = 0;
        virtual double                  getHumidity()                                       const   = 0;
        virtual double                  getTemperature()                                    const   = 0;

        virtual double                  getTemperatureMin()                                 const   = 0;
        virtual double                  getTemperatureMax()                                 const   = 0;

        virtual double                  getHumidityMin()                                    const   = 0;
        virtual double                  getHumidityMax()                                    const   = 0;

        virtual bool                    setUseAirLoss(bool use)                                     = 0; //Apply air loss to calculations
        virtual bool                    setHumidity(double humidity)                                = 0; //Relative humidity percentage [0.0, 100.0]
        virtual bool                    setTemperature(double celsius)                              = 0; //Temperature in degrees celsius

        virtual bool                    set(bool useAirLoss, double celsius, double humidity)       = 0;
        virtual void                    get(bool& useAirLoss, double& celsius, double& humidity) const noexcept = 0;

    protected:
                                        AcousticEnvironment()                                       = default;
        virtual                         ~AcousticEnvironment()                                      = default;                                 
    };

    /**
     * \class        ScopedAutoRestoreAcousticEnvironment
     *
     * \brief        Save off current state of air loss, temp, humidity, then restore those values when out of scope.
     */
    class ScopedAutoRestoreAcousticEnvironment
    {
    public:
        ScopedAutoRestoreAcousticEnvironment()
        {
            AcousticEnvironment::instance().get(_airLoss, _celsius, _humidity); // save into our members
        }
        ~ScopedAutoRestoreAcousticEnvironment()
        {
            AcousticEnvironment::instance().set(_airLoss, _celsius, _humidity); // restore from our members
        }

    protected:
        bool _airLoss;
        double _celsius;
        double _humidity;
    };

}//bosepro::environment

#endif //ACOUSTICENVIRONMENT_H