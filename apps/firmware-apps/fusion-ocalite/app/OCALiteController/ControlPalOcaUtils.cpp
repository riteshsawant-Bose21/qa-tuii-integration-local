/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 */

// OCALiteController.cpp : Defines the entry point for the OCA Controller application.
//

#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>
#include <OCC/ControlDataTypes/OcaLiteClassIdentification.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <StandardLib/StandardLib.h>
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <unistd.h>
#include <iostream>

::OcaLiteRoot* FindObject(::OcaONo blockOno, OcaLiteClassID classId)
{
    OcaLiteRoot   *target(NULL);

    ::OcaLiteBlock *zoneBlock(dynamic_cast<::OcaLiteBlock*>(::OcaLiteBlock::GetRootBlock().GetObject(blockOno)));

    if (zoneBlock)
    {
        ::OcaLiteList< ::OcaLiteObjectIdentification> zoneMembers;
        zoneBlock->GetMembers(zoneMembers);

        for (::OcaUint16 i = 0; i < zoneMembers.GetCount(); i++)
        {
            ::OcaLiteObjectIdentification memberObjId = zoneMembers.GetItem(i);
            if (memberObjId.GetClassIdentification().GetClassID() == classId)
            {
                target = zoneBlock->GetObject(memberObjId.GetONo());
                break;
            }
        }
    }

    return target;
}

::OcaONo FindParentZoneBlock(::OcaONo objONo)
{
    ::OcaONo parentBlock(0);
    ::OcaLiteList< ::OcaLiteObjectIdentification> zoneMembers;
    ::OcaLiteBlock::GetRootBlock().GetMembers(zoneMembers);

    for (::OcaUint16 i = 0; i < zoneMembers.GetCount(); i++)
    {
        OcaLiteRoot   *target(NULL);
        ::OcaONo blockONo = zoneMembers.GetItem(i).GetONo();
        ::OcaLiteBlock *zoneBlock(dynamic_cast<::OcaLiteBlock*>(::OcaLiteBlock::GetRootBlock().GetObject(blockONo)));

        // If object is a block
        if(zoneBlock)
        {
           target = zoneBlock->GetObject(objONo);

           // Parent found
           if (target)
           {
               parentBlock = blockONo;
               break;
           }
        }
    }
    return parentBlock;
}

