#ifndef BEAMSTEER_H
#define BEAMSTEER_H

#include <vector>
#include <memory>
#include "BeamConstraints.h"

namespace bosepro::acoustics
{
    class BeamSteer;
    using BeamSteerPtr = std::shared_ptr<BeamSteer>;

    struct BeamTransducerInfo;
    using BeamTransducerInfoList = std::vector<BeamTransducerInfo>;

    /**
     * \brief Structure for storing results of beam calculations (delays, gains)
     */
    struct BeamTransducerInfo
    {
        // z position (height)
        double                      z{ 0.0 };

        // delays for steer/spread, in seconds
        double                      steerDelay{ 0.0 };
        double                      spreadDelay{ 0.0 };
        double                      combinedFinalDelay{ 0.0 };

        // gain, in magnitude
        double                      gainShade{ 1.0 };

        // Indices for internal use
        std::size_t                 indexTransducer{ std::numeric_limits<std::size_t>::max() };
        std::size_t                 indexLoudspeaker{ std::numeric_limits<std::size_t>::max() };
    };

    /**
     * \brief Parent class representing a steerable beam
     */
    class BeamSteer
    {
    public:
        enum class BeamAlgorithm
        {
            Unknown,
            Symmetric,          // AKA Steer/Spread
            AsymmetricSteer,    // AKA Flat Floor
            Spiral              // AKA Raked Floor
        };

                                            BeamSteer() = default;
                                            BeamSteer(const BeamSteer&) = delete;
        BeamSteer&                          operator=(const BeamSteer&) = delete;
                                            BeamSteer(BeamSteer&&) = delete;
        BeamSteer&                          operator=(BeamSteer&&) = delete;
        virtual								~BeamSteer() = default;

        virtual std::size_t                getMinModuleCount() const { return 1; }
        virtual std::size_t                getMaxModuleCount() const { return 3; }

        // Get BeamConstraints as type T - needed to get constraints as BeamConstraintsSpiral to access unique members of spiral
        template <class T = BeamConstraints>
        std::shared_ptr<T>                  getBeamConstraints() const
        {
            return std::dynamic_pointer_cast<T>(getBeamConstraints());
        }

        virtual BeamConstraintsPtr          getBeamConstraints() const = 0;

        virtual BeamTransducerInfoList		getTransducerInfo() const = 0;

        virtual std::size_t					getTransducerCount() const = 0;
        virtual std::size_t					getModuleCount() const = 0;
        virtual BeamAlgorithm               getAlgorithmType() const = 0;

        virtual void                        calculateBeam() = 0;

        virtual double                      getBeamGain() const = 0;
        virtual void                        setBeamGain(double value) = 0;
        virtual double                      getMinBeamGain() const = 0;
        virtual double                      getMaxBeamGain() const = 0;

        virtual double                      getArrayEqGain() const = 0;
        virtual double                      getArrayEqFreq() const = 0;
        virtual double                      getArrayEqTilt() const = 0;

    protected:
        enum class OffsetType { bottom = 0, center = 1, top = 2 };

    private:
        virtual void                        setModuleCount(std::size_t value) = 0;
    };

    using BeamAlgorithms = std::vector<BeamSteer::BeamAlgorithm>;
}

#endif //BEAMSTEER_H
