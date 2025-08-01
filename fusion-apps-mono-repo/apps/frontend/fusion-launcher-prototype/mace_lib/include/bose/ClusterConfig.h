#pragma once
#ifndef CLUSTERCONFIG_H
#define CLUSTERCONFIG_H

#include <bitset>
#include <string_view>
#include <memory>
#include <optional>
#include "LoudspeakerCluster.h"
#include "Math/Vector.h"
#include "Lock/Lock.h"

namespace bosepro::model
{
    class LoudspeakerCluster;
}

namespace bosepro::mechanical
{
	class ClusterConfig;
	using ClusterConfigPtr = std::unique_ptr<ClusterConfig>;

	/**
	 * \brief ClusterConfigs are owned by LoudspeakerCluster objects. ClusterConfigs exist to answer the question: Is the cluster SAFE?
	 *		  The LSC delegates all mechanical safety math, logic, and tests to the ClusterConfig
	 *		  ClusterConfig is a virtual class. Each cluster confguration type has its own class and must override the IsItSafe() function and define what it means to be safe
	 */
	class ClusterConfig
	{
	public:
		/**
		 * \brief mask values for use when accessing connection or corner information
		 */
		enum class ConnectionFlags : std::size_t
		{
			Upper	= 0u,
			Lower	= 1u,
			Front	= 2u,
			Rear	    = 3u,
			Left	    = 4u,
			Right	= 5u,
			Center	= 6u
		};

		/**
		 * \brief A subclass of bitset<8> to make it easier to use with the ConnectionFlags enum
		 */
		class PointBitmask : public std::bitset<8>
		{
		public:
			/**
			 * \brief Wraps the std::bitset<>::set() function for easier usage
			 * \param flag	:	connection flag to modify
			 * \param value :	the value to set the connection flag to
			 * \return  the resultant bitset
			 */
			bitset& setFlag(ConnectionFlags flag, const bool value = true)
			{
				return set(static_cast<std::size_t>(flag), value);
			}

			/**
			 * \brief Wraps the std::bitset::test() function for easier usage
			 * \param flag	:	the connection flag to test
			 * \return returns true if the bit for the given flag is true
			 */
			bool testFlag(ConnectionFlags flag) const
			{
				return test(static_cast<std::size_t>(flag));
			}
		};

		/**
		 * \brief List of possibly results of a safety test. Less ambiguous than using a simple true/false boolean.
		 */
		enum class SafetyTestResult : unsigned int
		{
			Pass = 0,               // test passed
			ApproachingFailure = 1, // test passed, but is approaching failure. typically this is a result of certain tests, or if a force is >90% of any WLL. see ApproachingFailureFactor()
			Fail = 2                // test failed in simulation of final cluster
		};

		/**
		 * \brief List of possible warnings that a configuration can flag after running a safety test.
		 */
		enum class ConfigWarnings : unsigned int
		{
			None = 0,
			DefaultConfigInUse = 1,
			// general warnings
			FailureInSetup = 10,        //*< cluster will fail during setup
			RiskDuringSetup = 11,       //*< risk that cluster will fail during setup
			TotalBoxLimitExceeded = 12, //*< too many boxes in array
			UniqueBoxLimitExceeded = 13,//*< too many of one type of box
			CoverageAngleExceeded = 14, //*< coverage angle exceeds limit
			PitchLimitsExceeded = 15,   //*< system pitch exceeds limits
			InvalidHardware = 16,       //*< e.g. no grid
            CogOutOfRange = 17,         //*< center of gravity
			// flown warnings
			PitchTooFarUp = 100,
			PitchTooFarDown = 101,
			ConnectionPointOverloaded = 102,
            CompressionStrapOverloaded = 103,
            // 103 available
			InvalidPickpoints = 104,    //*< e.g. no pickpoints selected
			// ground warnings
			GroundStackTipping = 200,
            TipForward = 201,
            TipBackward = 202,
            TipLeft = 203,
            TipRight = 204
		};

		virtual								~ClusterConfig()												    = default;
		explicit							ClusterConfig(bosepro::model::LoudspeakerCluster* pLsc)					    :_pLsc{ pLsc } 
                                            {
                                                if (!_pLsc)
                                                {
                                                    throw std::bad_alloc();
                                                }
                                            }
                                            ClusterConfig(const ClusterConfig& other)                           
                                            {
                                                ScopedLock sl(other.getLock()); 
                                                _warnings = other._warnings;
                                                _pLsc = other._pLsc;
                                                _type = other._type;
                                            }
                                            ClusterConfig(ClusterConfig&& other)                                noexcept 
                                            {
                                                swap(*this, other); 
                                            }
        auto								operator=(const ClusterConfig&)                                     = delete;
        auto								operator=(ClusterConfig&&)										    = delete;

        static double						ApproachingFailureFactor();

        virtual ClusterConfig*				clone()															    const = 0;

        inline const Lock&                  getLock()                                                           const noexcept { return _lock; }
        auto *                              getCluster()                                                        const 
                                            { 
                                                ScopedLock sl(getLock());
                                                return _pLsc; 
                                            }

        inline friend void                  swap(ClusterConfig& lhs, ClusterConfig& rhs)                        noexcept
                                            {
                                                ScopedLockPair sl(lhs.getLock(), rhs.getLock());
                                                std::swap(lhs._warnings, rhs._warnings);
                                                std::swap(lhs._pLsc, rhs._pLsc);
                                                std::swap(lhs._type, rhs._type);
                                            }


		// User-friendly display name
		virtual std::string_view			name()															    const = 0;

		/**
		 * \brief the function that is called to determine if cluster is safe. safety tests are defined by subclasses
		 * \return returns cumulative safety test result
		 */
		virtual SafetyTestResult			isItSafe()														    const = 0;

		// Use ConnectionFlags enum for mask
		virtual math::Vec3					getConnectionPoint(std::size_t index, PointBitmask mask)		    const;
		virtual bool						isValidConnectionPoint(PointBitmask mask)						    const;
		virtual math::Vec3					getCornerPoint(std::size_t index, PointBitmask mask)			    const;
		virtual bool						isValidCornerPoint(PointBitmask mask)							    const;

		// ** Same for all configurations
		virtual math::Vec3					getClusterCenterOfGravity()											    const;
		virtual math::Vec3					getModuleCenterOfGravity(std::size_t index)						        const;
		virtual math::Vec3					getRunningCenterOfGravity(std::size_t index)					    const;

		virtual math::Vec3					getMinorConnectionPoint(std::size_t index, PointBitmask mask)	    const;
		virtual math::Vec3					getMinorCornerPoint(std::size_t index, PointBitmask mask)		    const;

		// ** Unique to array configuration type. Must be overridden
		virtual Connection::Position        getBuildDirection()												    const = 0;
		virtual math::Vec3					getModuleOrigin(std::size_t index)								    const = 0;
		virtual math::Angle					getModuleCenterAngle(std::size_t index)							    const = 0;
		virtual math::Angle					getModuleRearLinkAngle(std::size_t index)						    const;

		virtual math::Vec3					getMajorConnectionPoint(std::size_t index, PointBitmask mask)	    const = 0;
		virtual math::Vec3					getMajorCornerPoint(std::size_t index, PointBitmask mask)		    const = 0;


		virtual std::optional<math::Vec3>   getMajorConnectionPoint(std::size_t index, std::string_view ptName)	const;

		virtual double						getTotalDepth()													    const;
        virtual double						getTotalWidth()													    const;
		virtual double						getTotalHeight()												    const;

		/**
		 * \brief Gets the list of warnings generated+cached by the most recent IsItSafe() call
		 * \return List of configuration warnings
		 */
		std::vector<ConfigWarnings>			getWarnings()													    const 
                                            { 
                                                ScopedLock sl(getLock());
                                                return _warnings; 
                                            }

        //Get warning enums as string
        static inline std::string   ConfigWarningToString(ConfigWarnings warn)
                                            {
                                                std::string str;

                                                switch (warn)
                                                {
                                                case ConfigWarnings::None                           : str = "None"                          ; break;
                                                case ConfigWarnings::DefaultConfigInUse             : str = "DefaultConfigInUse"            ; break;
                                                case ConfigWarnings::FailureInSetup                 : str = "FailureInSetup"                ; break;
                                                case ConfigWarnings::RiskDuringSetup                : str = "RiskDuringSetup"               ; break;
                                                case ConfigWarnings::TotalBoxLimitExceeded          : str = "TotalBoxLimitExceeded"         ; break;
                                                case ConfigWarnings::UniqueBoxLimitExceeded         : str = "UniqueBoxLimitExceeded"        ; break;
                                                case ConfigWarnings::CoverageAngleExceeded          : str = "CoverageAngleExceeded"         ; break;
                                                case ConfigWarnings::PitchLimitsExceeded            : str = "PitchLimitsExceeded"           ; break;
                                                case ConfigWarnings::InvalidHardware                : str = "InvalidHardware"               ; break;
                                                case ConfigWarnings::CogOutOfRange                  : str = "CogOutOfRange"                 ; break;
                                                case ConfigWarnings::PitchTooFarUp                  : str = "PitchTooFarUp"                 ; break;
                                                case ConfigWarnings::PitchTooFarDown                : str = "PitchTooFarDown"               ; break;
                                                case ConfigWarnings::ConnectionPointOverloaded      : str = "ConnectionPointOverloaded"     ; break;
                                                case ConfigWarnings::CompressionStrapOverloaded     : str = "CompressionStrapOverLoaded"    ; break;
                                                case ConfigWarnings::InvalidPickpoints              : str = "InvalidPickpoints"             ; break;
                                                case ConfigWarnings::GroundStackTipping             : str = "GroundStackTipping"            ; break;
                                                case ConfigWarnings::TipForward                     : str = "TipForward"                    ; break;
                                                case ConfigWarnings::TipBackward                    : str = "TipBackward"                   ; break;
                                                case ConfigWarnings::TipLeft                        : str = "TipLeft"                       ; break;
                                                case ConfigWarnings::TipRight                       : str = "TipRight"                      ; break;
                                                default: assert(0 && "invalid warning enum");
                                                }
                                                return str;
                                            }

        enum UpdateType
        {
            None,
            NameSingle,
            PitchSingle,
            NameDouble,
            PitchDouble,
        };

        auto                                getType()                                                           const
                                            {
                                                ScopedLock sl(getLock());
                                                return _type;
                                            }
        void                                setType(UpdateType ut)
                                            {
                                                ScopedLock sl(getLock());
                                                _type = ut;
                                            }


		// for initializing via pitch for single pp and double pp hangs
        // one method to rule them all
        enum class configAction : int64_t
        {
            setPitchDefaultDual               = 0, //<* sets the pitch provided and uses default front/rear pick points from top component (slider or bumper).  Resets cluster origin and makes it be the front pick point. 
            findGravityPointForPitch          = 1, //<* tries to find the single pick point that gets closest to the desired pitch. Resets cluster origin and makes pick point the origin of cluster.
            findGravityPointForPitchWPullback = 2, //<* first finds the closest pick point based on gravity, then sets pitch exactly (since the rear is from pullback).  Resets cluster origin and makes the found pickpoint the origin.
            setPitchDefaultSingleWPullback    = 3, //<* uses the default front pick point and sets the pitch exactly (since the rear is form pullback).  Resets cluster origin and makes front pick point the origin.
            setPickpoints                     = 4, //<* Makes the specified pick points for the top component active.  Pitch is optional and will be set matching requested.  Resets cluster origin and makes front pick point the origin.
            setPickpointWPullback             = 5, //<* sets front pick point to that provided, activates the pick point on the pullback and sets the optional pitch matching requested.  Resets cluster origin and makes pick point the origin.
            updatePitchPreservingActives      = 6, //<* used to change the pitch of the cluster without resetting anything else.
            ACTIONCOUNT // add new ones above this.  this enum value used to validate input
        };
        virtual bool                        updateConfig(configAction ca, std::optional<math::Angle> pitch = std::nullopt, std::vector<std::string> pickpoints = {}) = 0;
        virtual bool                        refreshConfig() = 0;

        void                                updateLSC(bosepro::model::LoudspeakerCluster* pLsc)
                                            {
                                                ScopedLock sl(getLock());
                                                _pLsc = pLsc;
                                            }

	protected:
		
		/**
		 * \brief Adds a warning to the warning list. Does not add duplicates
		 * \param warning : warning to add
		 */
		void								addWarning(ConfigWarnings warning) const
		                                    {
                                                ScopedLock sl(getLock());
			                                    if (!(std::find(_warnings.begin(), _warnings.end(), warning) != _warnings.end()))
				                                    _warnings.emplace_back(warning);
		                                    }
        void                                clearWarnings() const
                                            {
                                                ScopedLock sl(getLock());
                                                _warnings.clear();
                                            }
    private:

		mutable std::vector<ConfigWarnings> _warnings;
        bosepro::model::LoudspeakerCluster* _pLsc{nullptr}; // with lock we need to use a ptr rather than reference, raw because of client usage (passed during construction when it has this ptr)
        UpdateType                          _type{ None }; // cache update type so we can re-call it when necessary
        Lock                                _lock;
	};
}
#endif // !CLUSTERCONFIG_H