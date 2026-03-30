/*  By downloading or using this file, the user agrees to be bound by the terms of the license 
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

/*
 *  Description         : OcaLiteMessageNotification
 *
 */

// ---- Include system wide include files ----
#include <OCC/ControlDataTypes/OcaLiteBlob.h>
#include <OCC/ControlDataTypes/OcaLiteEventData.h>
#include <OCF/OcaLiteCommandHandler.h>
#include <OCP.1/Ocp1LiteWriter.h>

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include "OcaLiteMessageNotification.h"

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Local data ----

// ---- Class Implementation ----

OcaLiteMessageNotification::OcaLiteMessageNotification()
    : ::OcaLiteMessageGeneral(::OcaLiteHeader::OCA_MSG_NTF),
#ifdef OCA_LITE_CONTROLLER
      m_eventData(NULL),
      m_context(),
      m_pParameters(new UINT8[32]),
#else
      m_pParameters(NULL),
#endif
      m_parametersSize(0),
      m_targetONo(OCA_INVALID_ONO),
      m_methodID()
{
}

OcaLiteMessageNotification::~OcaLiteMessageNotification()
{
}

bool OcaLiteMessageNotification::WriteParameters(::OcaONo targetONo,
                                                 const ::OcaLiteMethodID& methodID,
                                                 const ::OcaLiteBlob& context,
                                                 const ::OcaLiteEventData& eventData,
                                                 const ::IOcaLiteWriter& writer)
{
    bool bResult(false);

    WriteParameters(targetONo, methodID);

    m_parametersSize = ::GetSizeValue< ::OcaUint8>(2, writer) + context.GetSize(writer) + eventData.GetSize(writer);

    if (OCA_BUFFER_SIZE >= m_parametersSize)
    {
        m_pParameters = ::OcaLiteCommandHandler::GetInstance().GetResponseBuffer(m_parametersSize);
        UINT8* pParameters(m_pParameters);
        writer.Write(static_cast< ::OcaUint8>(2), &pParameters);
        context.Marshal(&pParameters, writer);
        eventData.Marshal(&pParameters, writer);

        bResult = true;
    }

    return bResult;
}

void OcaLiteMessageNotification::WriteParameters(::OcaONo targetONo,
                                                 const ::OcaLiteMethodID& methodID)
{
    m_targetONo = targetONo;
    m_methodID = methodID;
}

#ifdef OCA_LITE_CONTROLLER
void OcaLiteMessageNotification::WriteParameters(::OcaONo                   targetONo,
                                                 const ::OcaLiteMethodID&   methodID,
                                                 const ::OcaLiteBlob&       context,
                                                 ::OcaLiteEventData*        eventData)
{
    m_targetONo  = targetONo;
    m_methodID   = methodID;
    m_context    = context;
    m_eventData  = eventData;
}

// For Gain Object
void OcaLiteMessageNotification::UpdateNotificationValue(::OcaFloat32& parameter)
{
    ::Ocp1LiteWriter ntfWriter;
    ::OcaUint8* bufPtr(m_pParameters);

    ntfWriter.Write(static_cast<::OcaInt8>(1), &bufPtr);
    ntfWriter.Write(parameter, &bufPtr);

    m_parametersSize = sizeof(parameter) + 1;
}

//For Mute object
void OcaLiteMessageNotification::UpdateNotificationValue(::OcaUint8& parameter)
{
    ::Ocp1LiteWriter ntfWriter;
    ::OcaUint8* bufPtr(m_pParameters);

    ntfWriter.Write(static_cast<::OcaInt8>(1), &bufPtr);
    ntfWriter.Write(parameter, &bufPtr);

    m_parametersSize = sizeof(parameter) + 1;
}

//For Switch object
void OcaLiteMessageNotification::UpdateNotificationValue(::OcaUint16& parameter)
{
    ::Ocp1LiteWriter ntfWriter;
    ::OcaUint8* bufPtr(m_pParameters);

    ntfWriter.Write(static_cast<::OcaInt8>(1), &bufPtr);
    ntfWriter.Write(parameter, &bufPtr);

    m_parametersSize = sizeof(parameter) + 1;
}
#endif
