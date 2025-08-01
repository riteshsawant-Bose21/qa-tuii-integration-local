#pragma once
#ifndef AMP_CHANNEL_H 
#define AMP_CHANNEL_H 

#include <memory>
#include <unordered_map>
#include <string>
#include "HardwareComponent.h"

#include "Math/Ray.h"
#include "Math/Vector.h"
#include "FilterInterface.h"

namespace bosepro::hardware
{

    class AmpChannel;
    using AmpChannelPtr = std::shared_ptr<AmpChannel>;

    class AmpChannel : public Node,
        public acoustics::FilterInterface
    {
    public:
        virtual         ~AmpChannel()                   = default;
                        AmpChannel()                    = default;
                        AmpChannel(const AmpChannel&)   = default;
                        AmpChannel(AmpChannel&&)      noexcept = default;
        AmpChannel&     operator=(AmpChannel&&)       noexcept = default;
        AmpChannel&     operator=(const AmpChannel&)           = default;

        virtual bool                    addFilter(acoustics::FilterDataSet) = 0;
        acoustics::FiltersData          listFilters() = 0;
        bool                            removeFilter(std::string type) = 0;

        virtual std::string             getConnectionName() const = 0;
        virtual std::string             getConnectionNameLC() const = 0;

        // bubble up to interface anything we need to call without getting an impl.
    };
} //bosepro::hardware

#endif //AMP_CHANNEL_H
