/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : FusionBlock - Custom OOCA Block implementation.
 *
 */

// ---- Include system wide include files ----
#include <iostream>
#include <limits>
#include <OCC/ControlClasses/Agents/OcaLiteAgent.h>
#include <OCC/ControlClasses/Managers/OcaLiteDeviceManager.h>
#include <OCC/ControlClasses/Workers/OcaLiteWorker.h>
#include <OCC/ControlDataTypes/OcaLitePropertyChangedEventData.h>
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <OCF/OcaLiteCommandHandler.h>
#include <OCF/Messages/OcaLiteMessageResponse.h>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "FusionBlock.h"
#include <HostInterfaceLite/OCA/OCF/Logging/IOcfLiteLog.h>

// ---- Helper types and constants ----

// ---- Helper functions ----

::OcaLiteStatus FusionBlock::Execute(const ::IOcaLiteReader& reader,
                                     const ::IOcaLiteWriter& writer,
                                     ::OcaSessionID sessionID,
                                     const ::OcaLiteMethodID& methodID,
                                     ::OcaUint32 parametersSize,
                                     const ::OcaUint8* parameters,
                                     ::OcaUint8** response)
{
    ::OcaLiteStatus rc(OCASTATUS_PARAMETER_ERROR);

    if (!IsLocked(sessionID))
    {
        if (methodID.GetDefLevel() == CLASS_ID.GetFieldCount())
        {
            ::OcaUint8* responseBuffer(NULL);
            const ::OcaUint8* pCmdParameters(parameters);
            ::OcaUint32 bytesLeft(parametersSize);

            switch (methodID.GetMethodIndex())
            {
                case GET_FUSION_MEMBERS:
                case GET_FUSION_MEMBERS_RECURSIVE:
                    {
                        ::OcaUint8 numberOfParameters(0);

                        if (reader.Read(bytesLeft, &pCmdParameters, numberOfParameters) &&
                                (0 == numberOfParameters))
                        {
                            ::OcaLiteList< ::OcaLiteObjectIdentification> members;
                            rc = GetMembers(members);
                            if (OCASTATUS_OK == rc)
                            {
                                ::OcaUint32 responseSize(::GetSizeValue< ::OcaUint8>(static_cast< ::OcaUint8>(1), writer) + 
                                        members.GetSize(writer));
                                responseBuffer = ::OcaLiteCommandHandler::GetInstance().GetResponseBuffer(responseSize);
                                if (NULL != responseBuffer)
                                {
                                    ::OcaUint8* pResponse(responseBuffer);
                                    writer.Write(static_cast< ::OcaUint8>(1/*NrParameters*/), &pResponse);
                                    members.Marshal(&pResponse, writer);

                                    *response = responseBuffer;
                                }
                                else
                                {
                                    rc = OCASTATUS_BUFFER_OVERFLOW;
                                }
                            }
                        }
                    }
                    break;

                default:
                    rc = OCASTATUS_BAD_METHOD;
                    break;
            }
        }
    }
    return rc;
}

::OcaLiteStatus FusionBlock::GetMembersRecursive(::OcaLiteList< ::OcaLiteBlockMember>& members) const
{
    return OCASTATUS_OK;
}

