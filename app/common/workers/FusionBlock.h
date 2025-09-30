/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : ConcreteMuteActuator - Concrete implementation of OcaLiteMute
 *
 */

#ifndef FUSIONBLOCK_H
#define FUSIONBLOCK_H

// ---- Include system wide include files ----

// ---- Include local include files ----
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>

// ---- Referenced classes and types ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Class Definition ----

/**
 * Concrete implementation of OcaLiteMute actuator.
 * This class provides a real implementation of the mute functionality
 * by implementing the pure virtual SetStateValue method from OcaLiteMute.
 */
class FusionBlock : public ::OcaLiteBlock
{
    public:
        enum MethodIndex
        {
            GET_FUSION_MEMBERS              = 30,
            GET_FUSION_MEMBERS_RECURSIVE    = 31
        };

        FusionBlock(::OcaONo objectNumber, ::OcaBoolean lockable, const ::OcaLiteString& role,
                const ::OcaLiteList< ::OcaLitePort>& ports, ::OcaONo type) :
            ::OcaLiteBlock(objectNumber, lockable, role, ports, type) {}

#if 1
        ::OcaLiteStatus GetMembersRecursive(::OcaLiteList< ::OcaLiteBlockMember>& members) const;
        //::OcaLiteStatus GetFusionMembersRecursive(::OcaLiteList< ::OcaLiteBlockMember>& members) const;
#endif

        ~FusionBlock() {}

        ::OcaLiteStatus Execute(const ::IOcaLiteReader& reader, const ::IOcaLiteWriter& writer,
                ::OcaSessionID sessionID, const ::OcaLiteMethodID& methodID,
                ::OcaUint32 parametersSize, const ::OcaUint8* parameters,
                ::OcaUint8** response);
};

#endif
