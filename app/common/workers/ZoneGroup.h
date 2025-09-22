/*
 *  ZoneGroup.h - Simple hierarchical container using OcaLiteBlock to model Zones.
 *
 *  This is an interim replacement for AES70-2024 OcaGroup semantics, providing
 *  only structural containment (no aggregation logic or group events yet).
 */
#ifndef ZONEGROUP_H
#define ZONEGROUP_H

#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>

class ZoneGroup : public ::OcaLiteBlock
{
public:
    ZoneGroup(::OcaONo objectNumber,
              ::OcaBoolean lockable,
              const ::OcaLiteString &role,
              ::OcaONo blockType = static_cast<::OcaONo>(0))
        : ::OcaLiteBlock(objectNumber,
                         lockable,
                         role,
                         s_emptyPorts,
                         blockType)
    {
    }

    virtual ~ZoneGroup() {}

private:
    static ::OcaLiteList<::OcaLitePort> s_emptyPorts; // no ports for grouping block
    ZoneGroup(const ZoneGroup &);
    ZoneGroup &operator=(const ZoneGroup &);
};

#endif // ZONEGROUP_H
