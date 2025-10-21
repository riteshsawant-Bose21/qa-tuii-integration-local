#include <iostream>
#include <limits>
#include <chrono>
#include <thread>
#include <mutex>
#include <sstream>
#include <memory>
#include <stdexcept>
#include <condition_variable>
#include "ControllerMenu.h"
#include "../../../ControlPalMsgInterface.h"

std::string global_input;
std::mutex mtx;
std::condition_variable cv_read;
bool input_received = false;

void read_input_thread();

ControllerMenu::ControllerMenu(std::string title, void *cmdQueue):
    ControlPalMsgInterface(cmdQueue),
    m_title(std::move(title)), m_exitLabel("Exit"),
    m_activeZone(NULL)
{
}

void ControllerMenu::addOption(const std::string& label, Callback cb)
{
    m_items.push_back(Item{label, std::move(cb)});
}

void ControllerMenu::setExitLabel(const std::string& label)
{
    m_exitLabel = label;
}

void read_input_thread(void *arg)
{
    (void) arg;
    std::string line;

    while(1)
    {
        std::getline(std::cin, line); // This will block
        {
            std::lock_guard<std::mutex> lock(mtx);
            global_input = line;
            input_received = true;
        }
        cv_read.notify_one(); // Signal that input is received
    }
}

void ControllerMenu::drawControllerMenu()
{
    static float prevGain    = 0.0;
    static uint32_t prevMute = 1;
    static uint32_t prevPos  = 0;

    if ( (prevPos != m_activeZone->source) || (prevGain != m_activeZone->gain) || (prevMute != m_activeZone->mute))
    {
        // Clear the console screen in a cross-platform friendly way by
        // printing several newlines. (Avoid system("cls") for portability/safety.)
        std::cout << std::string(50, '\n');
        std::cout << "=== " << m_title << " ===\n";
        // display global values
        std::cout << " ZONE:   " << m_activeZone->name << "\n";
        std::cout << " GAIN:   " << m_activeZone->gain << "\n";
        std::cout << " MUTE:   " << m_activeZone->mute << "\n";
        std::cout << " SOURCE: " << m_activeZone->sourceNames[m_activeZone->source] << "\n\n";

        for (size_t i = 0; i < m_items.size(); ++i) {
            std::cout << " " << (i + 1) << ") " << m_items[i].label << "\n";
        }
        std::cout << " 0) " << m_exitLabel << "\n" << "Enter SELECTION: " ;

        prevPos  = m_activeZone->source;
        prevGain = m_activeZone->gain;
        prevMute = m_activeZone->mute;
    }
}

int ControllerMenu::getSelection()
{
    // We'll prompt and then wait for a line of input. While waiting, the
    // menu will refresh every second to show updated global values.
    int sel;

    std::unique_lock<std::mutex> lock(mtx);
    if (cv_read.wait_for(lock, std::chrono::milliseconds(10),
                []{ return input_received; }))
    {
        input_received = false;
        // Trim leading/trailing whitespace
        std::stringstream ss(global_input);
        if (!(ss >> sel)) {
            std::cout << "Invalid input. Please enter a number.\n";
            sel = -1;
        }
        if (sel < 0 || sel > static_cast<int>(m_items.size())) {
            std::cout << "Selection out of range. Try again.\n";
            sel = -1;
        }
    }
    else
    {
        sel = -1;
    }
    return sel;
}

void ControllerMenu::addZone(uint32_t &ONo, std::string &name, float &gain,
                             uint32_t &mute, uint32_t &source,
                             uint32_t &numSources,
                             std::vector<std::string> &sourceNames)
{
    //std::unique_ptr<zoneProperties> zProperty =
    auto zProperty = std::make_unique<zoneProperties>();

    zProperty->name        = name;
    zProperty->ONo         = ONo;
    zProperty->gain        = gain;
    zProperty->mute        = mute;
    zProperty->source      = source;
    zProperty->numSources  = numSources;
    zProperty->sourceNames = sourceNames;

    // Add to map
    m_zoneMap.insert(std::make_pair(ONo, std::move(zProperty))); 

    // Make the first zone the current active zone
    if (m_zoneMap.size() == 1)
    {
        m_activeZone = m_zoneMap[ONo].get();
    }
}

void ControllerMenu::run()
{
    //while (true) 
    {
        int sel = 0;

        drawControllerMenu();

        sel = getSelection();
        if (sel ==-1)
        {
            return;
        }
        else if (sel == 0) {
            std::cout << "Exiting menu.\n";
            return;
        }
        // valid selection: invoke callback
        size_t idx = static_cast<size_t>(sel - 1);
        try {
            if (m_items[idx].cb) {

                switch (idx)
                {
                    case 0:
                        // Cycle Zone
                        cycleActiveZone();
                        break;

                    case 1:
                        // Increase Gain
                        m_uiMsg.ono = m_activeZone->ONo;
                        break;

                    case 2:
                        // Decrease Gain
                        m_uiMsg.ono = m_activeZone->ONo;
                        break;

                    case 3:
                        //Toggle Mute
                        m_uiMsg.ono = m_activeZone->ONo;
                        break;

                    case 4:
                        // Cycle Source
                        m_uiMsg.ono = m_activeZone->ONo;
                        break;

                    default:
                        throw std::runtime_error("Invalid Selection.");
                        return;
                }
                m_items[idx].cb(m_uiMsg);
                SendValue();

            }
        } catch (const std::exception& e) {
            std::cout << "Error in callback: " << e.what() << "\n";
        } catch (...) {
            std::cout << "Unknown error in callback.\n";
        }
        // After callback returns, loop continues and menu is shown again
    }
}

void ControllerMenu::SendValue()
{
#if 1
    std::cout << "Cmd:" << m_uiMsg.cmd << std::endl;
    std::cout << "ONo:" << m_uiMsg.ono << std::endl;
    std::cout << "VALFlt:" << m_uiMsg.val.flt_val << std::endl;
    std::cout << "VALInt:" << m_uiMsg.val.int_val << std::endl;
#endif
    PushToMsgQueue(m_uiMsg);
}

void ControllerMenu::cycleActiveZone()
{
    //std::map<uint32_t, std::unique_ptr<zoneProperties>>::size_type
    auto zoneCnt = m_zoneMap.size();

    if (zoneCnt > 1)
    {
        // Find current index
        auto it = m_zoneMap.find(m_activeZone->ONo);
        int currIndex = std::distance(m_zoneMap.begin(), it);
        currIndex = (currIndex + 1) % zoneCnt;  // next zone

        //it = m_zoneMap.begin();
        //std::advance(it, currIndex);
        m_activeZone = m_zoneMap[currIndex].get();
    }
}

void ControllerMenu::setGain(uint32_t ONo, float gain)
{
    std::unique_ptr<zoneProperties> &obj = findObject(ONo);

    if (obj)
    {
        obj->gain = gain;
    }
}

void ControllerMenu::setMute(uint32_t ONo, uint32_t mute)
{
    std::unique_ptr<zoneProperties> &obj = findObject(ONo);

    if (obj)
    {
        obj->mute = mute;
    }
}

void ControllerMenu::setSource(uint32_t ONo, uint32_t source)
{
    std::unique_ptr<zoneProperties> &obj = findObject(ONo);

    if (obj)
    {
        obj->source = source;
    }
}

