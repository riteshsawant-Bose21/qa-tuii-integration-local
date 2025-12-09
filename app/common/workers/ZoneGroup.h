/*
 *  ZoneGroup.h - Simple hierarchical container using OcaLiteBlock to model Zones.
 *
 *  This is an interim replacement for AES70-2024 OcaGroup semantics, providing
 *  only structural containment (no aggregation logic or group events yet).
 */
#ifndef ZONEGROUP_H
#define ZONEGROUP_H

#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>

#ifdef OCA_LITE_CONTROLLER
#include "../../OCALiteController/HostInterface/CommandInterface/CommandInterface.h"
#include "../../OCALiteController/ControlPalMsgInterface.h"

class ZoneGroup : public ControlPalMsgInterface<ControllerCmdIntfc>,
                  public ::OcaLiteBlock
#else
class ZoneGroup : public ::OcaLiteBlock
#endif
{
public:
    ZoneGroup(::OcaONo objectNumber,
              ::OcaBoolean lockable,
              const ::OcaLiteString &role,
#ifdef OCA_LITE_CONTROLLER
              const ::OcaLiteString &name,
              void  *cmdQueue,
#endif
              ::OcaONo blockType = static_cast<::OcaONo>(0),
              ::OcaLiteList<::OcaLitePort> s_emptyPorts =
                   ::OcaLiteList<::OcaLitePort> (0,&dummy)
              ) :
#ifdef OCA_LITE_CONTROLLER
        ControlPalMsgInterface(cmdQueue),
#endif
        ::OcaLiteBlock(objectNumber,
                         lockable,
                         role,
                         s_emptyPorts,
                         blockType)
    {
#ifdef OCA_LITE_CONTROLLER
              m_name = name;
#endif
    }

    virtual ~ZoneGroup() {}

#ifdef OCA_LITE_CONTROLLER
    void SendValue();

    ::OcaLiteString m_name;  // Zone name
#endif
private:
    static ::OcaLitePort dummy;
    //static ::OcaLiteList<::OcaLitePort> s_emptyPorts; // no ports for grouping block
    ZoneGroup(const ZoneGroup &);
    ZoneGroup &operator=(const ZoneGroup &);
};

#endif // ZONEGROUP_H
