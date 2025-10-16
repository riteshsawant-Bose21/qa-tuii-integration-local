/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : OcaLite GeneralProxy implementation.
 *
 */

// ---- Include system wide include files ----
#include <OCC/ControlClasses/Managers/OcaLiteDeviceManager.h>
#include <OCC/ControlClasses/Managers/OcaLiteNetworkManager.h>
#include <OCC/ControlClasses/Managers/OcaLiteSubscriptionManager.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteGain.h>
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteMute.h>
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteSwitch.h>
#include <OCC/ControlDataTypes/OcaLiteBlockMember.h>
#include <OCC/ControlDataTypes/OcaLiteEvent.h>
#include <OCC/ControlDataTypes/OcaLiteManagerDescriptor.h>
#include <OCC/ControlDataTypes/OcaLiteMethod.h>
#include <OCC/ControlDataTypes/OcaLiteNetworkAddress.h>
#include <OCF/OcaLiteCommandHandlerController.h>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "FusionProxy.h"
#include "workers/FusionBlock.h"

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Local data ----

// ---- Class Implementation ----
FusionProxy::FusionProxy(::OcaSessionID sessionId, ::OcaONo networkObjectNumber) :
                             m_sessionId(sessionId),
                             m_networkObjectNumber(networkObjectNumber)
    //: GeneralProxy(sessionId, networkObjectNumber)
{
    memset(m_buffer, 0, sizeof(m_buffer));
}

::OcaLiteStatus FusionProxy::FusionBlock_GetMembersRecursive(
                                   ::OcaONo remoteObjectNumber,
                                   ::OcaLiteList< ::OcaLiteBlockMember>& members)
{
    members.Clear();

    ::OcaUint8 noParams(0);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;
    ::OcaLiteStatus rc(
        ::OcaLiteCommandHandlerController::GetInstance().SendCommandWithResponse(
                           m_sessionId,
                           m_networkObjectNumber,
                           remoteObjectNumber,
                           ::OcaLiteMethodID(::OcaLiteBlock::CLASS_ID.GetFieldCount(),
                                             FusionBlock::GET_FUSION_MEMBERS_RECURSIVE),
                           1,
                           &noParams,
                           responseSize,
                           &pResponse));

    if ((OCASTATUS_OK == rc) &&
        (responseSize > 0))
    {
        const ::IOcaLiteReader& reader(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetReader());
        ::OcaUint8 nrParameters(0);
        const ::OcaUint8* source(pResponse);
        reader.Read(responseSize, &source, nrParameters);
        if (nrParameters == 1)
        {
            if (!members.Unmarshal(responseSize, &source, reader))
            {
                rc = OCASTATUS_PARAMETER_ERROR;
            }
        }
        else
        {
            rc = OCASTATUS_PARAMETER_ERROR;
        }
    }

    return rc;
}

::OcaLiteStatus FusionProxy::FusionBlock_GetMembers(::OcaONo remoteObjectNumber,
                                                    ::OcaLiteList< ::OcaLiteObjectIdentification>& members)
{
     members.Clear();

    ::OcaUint8 noParams(0);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;
    ::OcaLiteStatus rc(
        ::OcaLiteCommandHandlerController::GetInstance().SendCommandWithResponse(
            m_sessionId,
            m_networkObjectNumber,
            remoteObjectNumber,
            ::OcaLiteMethodID(::OcaLiteBlock::CLASS_ID.GetFieldCount(),
                              FusionBlock::GET_FUSION_MEMBERS),
            1,
            &noParams,
            responseSize,
            &pResponse));

    if ((OCASTATUS_OK == rc) &&
        (responseSize > 0))
    {
        const ::IOcaLiteReader& reader(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetReader());
        ::OcaUint8 nrParameters(0);
        const ::OcaUint8* source(pResponse);
        reader.Read(responseSize, &source, nrParameters);
        if (nrParameters == 1)
        {
            if (!members.Unmarshal(responseSize, &source, reader))
            {
                rc = OCASTATUS_PARAMETER_ERROR;
            }
        }
        else
        {
            rc = OCASTATUS_PARAMETER_ERROR;
        }
    }

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteGainActuator_SetGain(::OcaONo remoteObjectNumber, ::OcaDB gainVal)
{
    const ::IOcaLiteWriter& writer(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetWriter());
    ::OcaUint8* pParams(m_buffer);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;

    writer.Write(static_cast<UINT8>(1), &pParams); // Nr params
    writer.Write(static_cast<FLOAT>(gainVal), &pParams); // Nr params

    ::OcaLiteStatus rc(
            ::OcaLiteCommandHandlerController::GetInstance().SendCommand(
                m_sessionId,
                m_networkObjectNumber,
                remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteGain::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteGain::SET_GAIN),
                static_cast< ::OcaUint32>(pParams - m_buffer),
                m_buffer));

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteGainActuator_GetGain(::OcaONo remoteObjectNumber, ::OcaDB& gainVal)
{
    ::OcaUint8 noParams(0);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;
    ::OcaDB min_val;
    ::OcaDB max_val;

    gainVal = 0;
    ::OcaLiteStatus rc(
        ::OcaLiteCommandHandlerController::GetInstance().SendCommandWithResponse(
            m_sessionId,
            m_networkObjectNumber,
            remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteGain::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteGain::GET_GAIN),
            1,
            &noParams,
            responseSize,
            &pResponse));

    if ((OCASTATUS_OK == rc) &&
        (responseSize > 0))
    {
        const ::IOcaLiteReader& reader(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetReader());
        ::OcaUint8 nrParameters(0);
        const ::OcaUint8* source(pResponse);
        reader.Read(responseSize, &source, nrParameters);

        if (nrParameters == 3)
        {
            reader.Read(responseSize, &source, gainVal);
            reader.Read(responseSize, &source, min_val);
            reader.Read(responseSize, &source, max_val);
        }
        else
        {
            rc = OCASTATUS_PARAMETER_ERROR;
        }
    }

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteMuteActuator_SetMute(::OcaONo remoteObjectNumber, ::OcaLiteMuteState state)
{
    const ::IOcaLiteWriter& writer(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetWriter());
    ::OcaUint8* pParams(m_buffer);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;

    writer.Write(static_cast<UINT8>(1), &pParams); // Nr params
    writer.Write(static_cast<UINT8>(state), &pParams);

    ::OcaLiteStatus rc(
            ::OcaLiteCommandHandlerController::GetInstance().SendCommand(
                m_sessionId,
                m_networkObjectNumber,
                remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteMute::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteMute::SET_STATE),
                static_cast< ::OcaUint32>(pParams - m_buffer),
                m_buffer));

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteMuteActuator_GetMute(::OcaONo remoteObjectNumber, ::OcaLiteMuteState& state)
{
    ::OcaUint8 noParams(0);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;

    ::OcaLiteStatus rc(
        ::OcaLiteCommandHandlerController::GetInstance().SendCommandWithResponse(
            m_sessionId,
            m_networkObjectNumber,
            remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteMute::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteMute::GET_STATE),
            1,
            &noParams,
            responseSize,
            &pResponse));

    if ((OCASTATUS_OK == rc) &&
        (responseSize > 0))
    {
        const ::IOcaLiteReader& reader(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetReader());
        ::OcaUint8 nrParameters(0);
        const ::OcaUint8* source(pResponse);
        reader.Read(responseSize, &source, nrParameters);

        ::OcaUint8 readState;
        if (nrParameters == 3)
        {
            reader.Read(responseSize, &source, readState);
            state = static_cast<::OcaLiteMuteState>(readState);
        }
        else
        {
            rc = OCASTATUS_PARAMETER_ERROR;
        }
    }

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteSwitchActuator_SetSwitch(::OcaONo remoteObjectNumber, ::OcaUint16 position)
{
    const ::IOcaLiteWriter& writer(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetWriter());
    ::OcaUint8* pParams(m_buffer);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;

    writer.Write(static_cast<UINT8>(1), &pParams); // Nr params
    writer.Write(static_cast<UINT16>(position), &pParams);

    ::OcaLiteStatus rc(
            ::OcaLiteCommandHandlerController::GetInstance().SendCommand(
                m_sessionId,
                m_networkObjectNumber,
                remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteSwitch::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteSwitch::SET_POSITION),
                static_cast< ::OcaUint32>(pParams - m_buffer),
                m_buffer));

    return rc;
}

::OcaLiteStatus FusionProxy::ConcreteSwitchActuator_GetSwitch(::OcaONo remoteObjectNumber, ::OcaUint16& position)
{
    ::OcaUint8 noParams(0);
    ::OcaUint32 responseSize;
    ::OcaUint8* pResponse;
    ::OcaDB min_pos;
    ::OcaDB max_pos;

    ::OcaLiteStatus rc(
        ::OcaLiteCommandHandlerController::GetInstance().SendCommandWithResponse(
            m_sessionId,
            m_networkObjectNumber,
            remoteObjectNumber,
                ::OcaLiteMethodID(::OcaLiteSwitch::CLASS_ID.GetFieldCount(),
                                  ::OcaLiteSwitch::GET_POSITION),
            1,
            &noParams,
            responseSize,
            &pResponse));

    if ((OCASTATUS_OK == rc) &&
        (responseSize > 0))
    {
        const ::IOcaLiteReader& reader(::OcaLiteNetworkManager::GetInstance().GetNetwork(m_networkObjectNumber)->GetReader());
        ::OcaUint8 nrParameters(0);
        const ::OcaUint8* source(pResponse);
        reader.Read(responseSize, &source, nrParameters);

        if (nrParameters == 3)
        {
            reader.Read(responseSize, &source, position);
            reader.Read(responseSize, &source, min_pos);
            reader.Read(responseSize, &source, max_pos);
        }
        else
        {
            rc = OCASTATUS_PARAMETER_ERROR;
        }
    }

    return rc;
}

