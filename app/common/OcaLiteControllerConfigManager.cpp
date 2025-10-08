/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description         : OcaLiteControllerConfigManager
 *
 */

// ---- Include system wide include files ----

// ---- Include local include files ----
#include "OcaLiteControllerConfigManager.h"
#include "models/WallControllerConfigParser.h" // for Controller and Zone structs
#include "FusionOCAConstants.h"                // for custom ONO constants
#include "../../common/OCALite/OCF/OcaLiteCommandHandler.h"
#include "../../common/OCALite/OCC/ControlDataTypes/OcaLiteTemplateHelpers.h"
#include "../../common/OCALite/OCC/ControlDataTypes/OcaLiteClassIdentification.h"

// ---- Helper types and constants ----

static const ::OcaUint16 classID[] = {OCA_MANAGER_CLASSID, CONTROLLER_CONFIG_MANAGER_CLASS_ID};
const ::OcaLiteClassID OcaLiteControllerConfigManager::CLASS_ID(static_cast<::OcaUint16>(sizeof(classID) / sizeof(classID[0])), classID);

/** Defines the version increment of this class compared to its base class. */
#define CLASS_VERSION_INCREMENT 0

// ---- Helper functions ----

// ---- Local data ----

::OcaLiteControllerConfigManager *OcaLiteControllerConfigManager::m_pSingleton(NULL);
const ::OcaONo OcaLiteControllerConfigManager::MANAGER_ONO(CONTROLLER_CONFIG_MANAGER_ONO);

// ---- Class Implementation ----

OcaLiteControllerConfigManager::OcaLiteControllerConfigManager()
    : ::OcaLiteManager(MANAGER_ONO, ::OcaLiteString("ControllerConfigManager"), ::OcaLiteString("ControllerConfigManager"))
{
}

OcaLiteControllerConfigManager::~OcaLiteControllerConfigManager()
{
    m_pSingleton = NULL;
}

::OcaLiteControllerConfigManager &OcaLiteControllerConfigManager::GetInstance()
{
    if (NULL == m_pSingleton)
    {
        m_pSingleton = new ::OcaLiteControllerConfigManager;
    }

    return *m_pSingleton;
}

void OcaLiteControllerConfigManager::FreeInstance()
{
    if (m_pSingleton != NULL)
    {
        delete m_pSingleton;
        m_pSingleton = NULL;
    }
}

bool OcaLiteControllerConfigManager::Initialize()
{
    return ::OcaLiteManager::Initialize();
}

::OcaClassVersionNumber OcaLiteControllerConfigManager::GetClassVersion() const
{
    return static_cast<::OcaClassVersionNumber>(static_cast<int>(OcaLiteManager::GetClassVersion()) + CLASS_VERSION_INCREMENT);
}

::OcaLiteStatus OcaLiteControllerConfigManager::GetConfigDetails(const ::OcaLiteString &controllerId,
                                                                 ::OcaLiteString &configData) const
{
    OCA_LOG_INFO_PARAMS("Controller '%s' is requesting configuration.", controllerId.GetString().c_str());

    std::string controllerIdStr = controllerId.GetString();

    // Find the controller with matching ID
    std::shared_ptr<const Controller> foundController = nullptr;
    for (const auto &controller : m_controllers)
    {
        if (controller->id == controllerIdStr)
        {
            foundController = controller;
            break;
        }
    }

    if (!foundController)
    {
        OCA_LOG_WARNING_PARAMS("Controller '%s' not found in configuration.", controllerIdStr.c_str());
        return OCASTATUS_PARAMETER_ERROR;
    }

    // Serialize the controller to JSON using WallControllerConfigParser function
    std::string json = WallControllerToJsonString(*foundController);
    configData = ::OcaLiteString(json);

    OCA_LOG_INFO_PARAMS("✓ Config data for controller '%s' returned successfully (%zu zones)",
                        controllerIdStr.c_str(), foundController->zones.size());
    return OCASTATUS_OK;
}

void OcaLiteControllerConfigManager::SetConfigData(const std::vector<std::shared_ptr<Controller>> &controllers)
{
    m_controllers = controllers;
    OCA_LOG_INFO_PARAMS("✓ Controller configuration set with %zu controllers", controllers.size());
}

void OcaLiteControllerConfigManager::ClearConfigData()
{
    m_controllers.clear();
    OCA_LOG_INFO("✓ Controller configuration data cleared");
}

::OcaLiteStatus OcaLiteControllerConfigManager::Execute(const ::IOcaLiteReader &reader, const ::IOcaLiteWriter &writer, ::OcaSessionID sessionID, const ::OcaLiteMethodID &methodID,
                                                        ::OcaUint32 parametersSize, const ::OcaUint8 *parameters, ::OcaUint8 **response)
{
    OCA_LOG_INFO_PARAMS("OcaLiteControllerConfigManager::Execute called - Session: %u, MethodID: %u.%u, ParamsSize: %u",
                        sessionID, methodID.GetDefLevel(), methodID.GetMethodIndex(), parametersSize);

    ::OcaLiteStatus rc(OCASTATUS_PARAMETER_ERROR);

    if (!IsLocked(sessionID))
    {
        OCA_LOG_INFO("Manager is not locked, proceeding...");
        if (methodID.GetDefLevel() == CLASS_ID.GetFieldCount())
        {
            OCA_LOG_INFO_PARAMS("Method level matches class level (%u), processing method...", CLASS_ID.GetFieldCount());
            ::OcaUint8 *responseBuffer(NULL);
            ::OcaUint32 responseSize(0);
            ::OcaUint32 bytesLeft(parametersSize);
            const ::OcaUint8 *pCmdParameters(parameters);

            switch (methodID.GetMethodIndex())
            {
            case GET_CONFIG_DETAILS:
            {
                OCA_LOG_INFO("Processing GET_CONFIG_DETAILS method...");
                ::OcaUint8 numberOfParameters(0);
                ::OcaLiteString controllerId;
                if (reader.Read(bytesLeft, &pCmdParameters, numberOfParameters) &&
                    (1 == numberOfParameters) &&
                    controllerId.Unmarshal(bytesLeft, &pCmdParameters, reader))
                {
                    OCA_LOG_INFO_PARAMS("Successfully unmarshaled %u parameter(s), controller ID: '%s'", numberOfParameters, controllerId.GetString().c_str());
                    ::OcaLiteString configData;
                    rc = GetConfigDetails(controllerId, configData);
                    OCA_LOG_INFO_PARAMS("GetConfigDetails returned status: %u", rc);
                    if (OCASTATUS_OK == rc)
                    {
                        OCA_LOG_INFO_PARAMS("Config data retrieved, length: %zu chars", configData.GetString().length());
                        ::OcaUint32 responseBufferSize(::GetSizeValue<::OcaUint8>(static_cast<::OcaUint8>(1), writer) +
                                                       configData.GetSize(writer));
                        responseBuffer = ::OcaLiteCommandHandler::GetInstance().GetResponseBuffer(responseBufferSize);
                        if (NULL != responseBuffer)
                        {
                            OCA_LOG_INFO("Successfully allocated response buffer, marshaling response...");
                            ::OcaUint8 *pResponse(responseBuffer);
                            writer.Write(static_cast<::OcaUint8>(1), &pResponse);
                            configData.Marshal(&pResponse, writer);

                            responseSize = static_cast<::OcaUint32>(pResponse - responseBuffer);
                            OCA_LOG_INFO_PARAMS("Response marshaled successfully, size: %u bytes", responseSize);
                        }
                        else
                        {
                            OCA_LOG_ERROR("Failed to allocate response buffer!");
                            rc = OCASTATUS_BUFFER_OVERFLOW;
                        }
                    }
                }
                else
                {
                    OCA_LOG_ERROR("Failed to unmarshal controller ID parameter!");
                }
            }
            break;
            default:
                OCA_LOG_WARNING_PARAMS("Unknown method index: %u", methodID.GetMethodIndex());
                rc = OCASTATUS_BAD_METHOD;
                break;
            }

            if (OCASTATUS_OK == rc)
            {
                OCA_LOG_INFO("Setting response buffer for successful execution");
                *response = responseBuffer;
            }
        }
        else
        {
            OCA_LOG_INFO_PARAMS("Method level (%u) doesn't match class level (%u), delegating to parent...",
                                methodID.GetDefLevel(), CLASS_ID.GetFieldCount());
            // Should be executed on higher level
            rc = OcaLiteManager::Execute(reader, writer, sessionID, methodID, parametersSize, parameters, response);
        }
    }
    else
    {
        OCA_LOG_WARNING_PARAMS("Manager is locked for session %u", sessionID);
        rc = OCASTATUS_LOCKED;
    }

    OCA_LOG_INFO_PARAMS("OcaLiteControllerConfigManager::Execute returning status: %u", rc);
    return rc;
}

bool OcaLiteControllerConfigManager::GetClassIdentification(::OcaLiteClassIdentification &classIdentification) const
{
    classIdentification = ::OcaLiteClassIdentification(CLASS_ID, GetClassVersion());
    return true;
}
