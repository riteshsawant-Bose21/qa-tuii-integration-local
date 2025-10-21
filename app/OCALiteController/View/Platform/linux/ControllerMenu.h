// Simple menu class for console applications
#pragma once

#include <string>
#include <vector>
#include <functional>
#include <string>
#include <map>
#include "../../../HostInterface/CommandInterface/CommandInterface.h"
#include "../../../ControlPalMsgInterface.h"

typedef struct zProp 
{
    uint32_t            ONo;
    float               gain;
    uint32_t            mute;
    uint32_t            source;
    uint32_t            numSources;
    std::string         name;
    std::vector<std::string> sourceNames;
} zoneProperties;

class ControllerMenu : public ControlPalMsgInterface<ControllerCmdIntfc>
{
public:
    using Callback = std::function<void(ControllerCmdIntfc&)>;

    struct Item
    {
        std::string label;
        Callback cb;
    };

    ControllerMenu(std::string title = "ControllerMenu",
                   void *msgQueue = NULL);

    // Add an option with a label and a callback
    void addOption(const std::string& label, Callback cb);

    void addZone(uint32_t &ONo, std::string &name, float &gain,
                 uint32_t &mute, uint32_t &source,
                 uint32_t &numSources, std::vector<std::string> &sourceNames);

    // Starts the menu loop; returns when the user selects the "Exit" option
    void run();

    // Optional: set a custom exit label
    void setExitLabel(const std::string& label);

    void setGain(uint32_t ONo, float gain);
    void setMute(uint32_t ONo, uint32_t mute);
    void setSource(uint32_t ONo, uint32_t pos);

#if 0
    bool findObject(uint32_t ONo, zoneProperties *obj)
    {
        bool retVal(false);
        auto it = m_zoneMap.find(ONo);

        if (it != m_zoneMap.end())
        {
            obj = it->second.get();
            retVal = true;
        }
        return retVal;
    }
#endif
    
    std::unique_ptr<zoneProperties> &findObject(uint32_t ONo)
    {
        auto it = m_zoneMap.find(ONo);

        if (it != m_zoneMap.end())
        {
            return it->second;
        }
        else
        {
            std::cout << "NOT FOUND" << std::endl;
            std::unique_ptr<zoneProperties> dummy;
            return dummy;
        }
    }
    
    void SendValue();

private:
    std::string                         m_title;
    std::string                         m_exitLabel;
    std::vector<Item>                   m_items;

    std::map<uint32_t, std::unique_ptr<zoneProperties>> m_zoneMap;

    // Reference to active zone;
    zoneProperties *m_activeZone;

    ControllerCmdIntfc m_uiMsg; // Used to send nmessages

    void drawControllerMenu();
    int  getSelection();
    void cycleActiveZone();
};

