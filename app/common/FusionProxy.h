/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : The General Proxy class.
 */
#ifndef FUSION_PROXY_H
#define FUSION_PROXY_H

// ---- Include system wide include files ----
#include <PlatformDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteFrameworkDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteEventSubscriptionDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteWorkerDataTypes.h>
#include <OCC/ControlDataTypes/OcaLiteList.h>
#include <OCC/ControlDataTypes/OcaLiteBlobFixedLen.h>
#include <OCC/ControlClasses/Managers/OcaLiteDeviceManager.h>

// ---- Include local include files ----

// ---- Referenced classes and types ----
class OcaLiteManagerDescriptor;
class OcaLiteBlockMember;
class OcaLiteEvent;
class OcaLiteMethod;
class OcaLiteNetworkAddress;
class OcaLiteDeviceManager;
class OcaLiteClassIdentification;
class OcaLiteObjectIdentification;

// ---- Helper types and constants ----


// ---- Helper functions ----

// ---- Class Definition ----

/**
 * This is a proxy exposing all functionality we need, no class structures etc.
 */
class FusionProxy
{
public:
    /**
     * Constructor
     *
     * @param[in] sessionId             The session ID for which to create the proxy.
     * @param[in] networkObjectNumber   The network object number of the session ID.
     */
    FusionProxy(::OcaSessionID sessionId, ::OcaONo networkObjectNumber);

    /**
     * GetMembersRecursive from an OcaBlock
     *
     * @param[in] remoteObjectNumber        The object number of the remote object.
     * @param[out] members                  The list with members of this block.
     *
     * @return The resulting status.
     */
    ::OcaLiteStatus FusionBlock_GetMembersRecursive(
                                ::OcaONo remoteObjectNumber,
                                ::OcaLiteList<::OcaLiteBlockMember>& members);
    
    /**
     * GetMembers from an OcaBlock
     *
     * @param[in] remoteObjectNumber        The object number of the remote object.
     * @param[out] members                  The list with members of this block.
     *
     * @return The resulting status.
     */
    ::OcaLiteStatus FusionBlock_GetMembers(
            ::OcaONo remoteObjectNumber,
            ::OcaLiteList< ::OcaLiteObjectIdentification>& members);

        /**
     * Get configuration details from the Controller Config Manager
     *
     * @param[in]  managerONo     The object number of the Config Manager (typically 8001)
     * @param[in]  controllerId   The controller ID to get configuration for
     * @param[out] configData     The configuration data as string
     *
     * @return The resulting status
     */
    ::OcaLiteStatus OcaControllerConfigManager_GetConfigDetails(
                                         ::OcaONo managerONo,
                                         const ::OcaLiteString &controllerId,
                                         ::OcaLiteString &configData);

    ::OcaLiteStatus ConcreteGainActuator_SetGain(::OcaONo remoteObjectNumber,
                                                 ::OcaDB gainVal);

    ::OcaLiteStatus ConcreteGainActuator_GetGain(::OcaONo remoteObjectNumber,
                                                 ::OcaDB& gainVal);

    ::OcaLiteStatus ConcreteMuteActuator_SetMute(::OcaONo remoteObjectNumber,
                                                 ::OcaLiteMuteState state);

    ::OcaLiteStatus ConcreteMuteActuator_GetMute(::OcaONo remoteObjectNumber,
                                                 ::OcaLiteMuteState& state);

    ::OcaLiteStatus ConcreteSwitchActuator_SetSwitch(::OcaONo remoteObjectNumber,
                                                     ::OcaUint16 position);

    ::OcaLiteStatus ConcreteSwitchActuator_GetSwitch(::OcaONo remoteObjectNumber,
                                                     ::OcaUint16& position);

private:
    /** The session ID */
    ::OcaSessionID  m_sessionId;
    /** The network object number */
    ::OcaONo        m_networkObjectNumber;
    /** Buffer */
    ::OcaUint8      m_buffer[1024];
};

#endif //GENERAL_PROXY_H
