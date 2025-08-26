#pragma once
#ifndef HARDWARECOMPONENTFACTORY_H
#define HARDWARECOMPONENTFACTORY_H

#include <string>
#include <vector>
#include <unordered_map>
#include "Loudspeaker.h"
#include "HardwareComponent.h"
#include "Loudspeaker/UniversalFilterFwd.h"

namespace bosepro::acoustics
{
	class ElectroAcousticData;
	using ElectroAcousticDataMap					= std::unordered_map<std::string, std::weak_ptr<acoustics::ElectroAcousticData>>;
}

namespace bosepro::hardware
{	
	class LoudspeakerImpl;
	class HardwareComponentImpl;
    class HWCFactoryTest; // forwards

    using LoudspeakerImplPtr						= std::shared_ptr<LoudspeakerImpl>;
        
    using HardwareComponentImplPtr					= std::shared_ptr<HardwareComponentImpl>;	

    using HardwareComponentImplPtrVector			= std::vector<HardwareComponentImplPtr>;
    using LoudspeakerImplPtrVector					= std::vector<LoudspeakerImplPtr>;        

	
    /**
        * \brief Singleton factory for all hardware components (including Loudspeakers). Keeps two maps: one for loudspeakers, and one for all other HWCs
        *        before any other calls, call initialize() with the absolute path to loudspeaker files 
        */
    class HardwareComponentFactory
    {
    public:
        friend class HWCFactoryTest;
        using String								= std::string;
        using StringArray							= std::vector<String>;

													~HardwareComponentFactory()                                 = default;
													HardwareComponentFactory(const HardwareComponentFactory&)   = delete;
													HardwareComponentFactory(HardwareComponentFactory&&)        = delete;
        HardwareComponentFactory&					operator=(const HardwareComponentFactory&)                  = delete;
        HardwareComponentFactory&					operator=(HardwareComponentFactory&&)                       = delete;

													//Singleton
        static HardwareComponentFactory&			instance();

													//Absolute path to loudspeaker files location, call prior to any other calls
        bool										initialize(const String& path);
        inline bool									isInitialized()                                             const noexcept { return _isInitialized; }

        static void									crossRefConnections(const HardwareComponentImplPtrVector& hwcs);     //TODO This should be private

													// HWC accessors
        StringArray									getHardwareComponentNames()                                             const;
        StringArray									getHardwareComponentFamilyNames()                                       const;
        StringArray									getHardwareComponentNamesByFamily(const String& family)                 const;
        StringArray									getHardwareCompomentNamesByType(const ComponentType& type)              const;
        HardwareComponentPtr						getHardwareComponent(const String& name, bool shouldFullyLoad = true);          //This will load the full data

													// Loudspeaker accessors
        StringArray									getLoudspeakerNames()                                                   const;
        StringArray									getLoudspeakerFamilyNames()                                             const;
        StringArray									getLoudspeakerNamesByFamily(const String& family)                       const;
        StringArray                                 getLoudspeakerNamesByFamilyStartsWith(const String startsWith )                 const;
        LoudspeakerPtr								getLoudspeaker(const String& name, bool shouldFullyLoad = true);                //This will load the full data

        inline const String&						getPath()                                                   const noexcept { return _path; }

        acoustics::UniversalFilters                       getEQPreset(const String& name,  acoustics::FilterScope s, const String& type, const String& preset); // helper to retrieve named preset from collection
        acoustics::UniversalFilters                       getEQPresets(const String& name, acoustics::FilterScope s, const String typeFilter = ""); // helper to retrieve all preset names from collection
        bool                                        hasEQPresets(const String& name, acoustics::FilterScope s, const String typeFilter = "")       const; // does it have any?

    private:
        void										load();

        explicit									HardwareComponentFactory()                                  = default;

        using BSFMap								= std::unordered_map<std::string, std::string>;

        // combined list of HWC + LS from maps
        HardwareComponentImplPtrVector				getAllComponents() const;

        template <class T>
        StringArray									getNames(const std::vector<T>& container)                               const
													{
													    StringArray names;

													    for (const T& element : container)
													    {
													        std::vector<std::string>::iterator it = std::find(names.begin(), names.end(), element->getName());
													        if (it == names.end())
													            names.emplace_back(element->getName());
													    }

													    return names;
													}

        template <class T>
        StringArray									getFamilyNames(const std::vector<T>& container)                         const
													{
													    StringArray names;

													    for (const T& element : container)
													    {
													        std::vector<std::string>::iterator it = std::find(names.begin(), names.end(), element->getFamily());
													        if (it == names.end())
													            names.emplace_back(element->getFamily());
													    }

													    return names;
													}

        template <class T>
        StringArray									getByFamilyName(const std::vector<T>& container, const String& family)  const
													{
													    StringArray names;

													    for (const T& element : container)
													    {
													        if (element->getFamily() == family)
													            names.emplace_back(element->getName());
													    }

													    return names;
													}
            
        BSFMap										_hardwareComponentPaths;
        HardwareComponentImplPtrVector				_hardwareComponents;
        LoudspeakerImplPtrVector					_loudspeakers;
        acoustics::ElectroAcousticDataMap			_electroAcousticData;

        bool										_isInitialized{ false };
        String										_path{ "" };
    };
}//bosepro::hardware

#endif //HARDWARECOMPONENTFACTORY_H
