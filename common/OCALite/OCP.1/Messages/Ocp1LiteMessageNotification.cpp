/*  By downloading or using this file, the user agrees to be bound by the terms of the license 
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

/*
 *  Description         : Ocp1LiteMessageNotification
 *
 */

// ---- Include system wide include files ----

// ---- FileInfo Macro ----

// ---- Include local include files ----
#include <OCC/ControlClasses/OcaLiteRoot.h>
#include <OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.h>
#include <OCC/ControlClasses/Managers/OcaLiteDeviceManager.h>
#include <OCC/ControlDataTypes/OcaLiteWorkerDataTypes.h>
#include <OCC/ControlDataTypes/OcaLitePropertyChangedEventData.h>
#include "Ocp1LiteMessageNotification.h"
#include <OCC/ControlClasses/Workers/Actuators/OcaLiteGain.h>  //DEBUG

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Local data ----

// ---- Class Implementation ----

Ocp1LiteMessageNotification::Ocp1LiteMessageNotification()
    : ::OcaLiteMessageNotification()
{
}

Ocp1LiteMessageNotification::~Ocp1LiteMessageNotification()
{
}

void Ocp1LiteMessageNotification::Marshal(::OcaUint8** destination, const ::IOcaLiteWriter& writer) const
{
    writer.Write(GetSize(writer), destination);
    MarshalValue< ::OcaONo>(GetTargetONo(), destination, writer);

    const ::OcaLiteMethodID& methodId(GetMethodID());
    methodId.Marshal(destination, writer);

    if (NULL != GetParameters())
    {
        writer.Write(GetParameters(), GetParametersSize(), destination);
    }
    else
    {
        writer.Write(static_cast< ::OcaUint8>(0), destination);
    }
}

bool Ocp1LiteMessageNotification::Unmarshal(::OcaUint32& bytesLeft, const ::OcaUint8** source, const ::IOcaLiteReader& reader)
{
#ifdef OCA_LITE_CONTROLLER
    bool success(GetMessageType() == OcaLiteHeader::OCA_MSG_NTF);

    ::OcaUint32 originalBytesLeft(bytesLeft);

    //Read NotificationSize
    ::OcaUint32 notificationSize(static_cast< ::OcaUint32>(0));
    success = success && reader.Read(bytesLeft, source, notificationSize);

    //Read TargetONo
    ::OcaONo targetONo(static_cast< ::OcaUint32>(0));
    success = success && reader.Read(bytesLeft, source, targetONo);

    if (OCASTATUS_OK != UpdateEventData(bytesLeft, source, targetONo, reader))
    {
        success = false;
    }

    return success;
#else
    return false; // Don't need to unmarshal events
#endif
}

::OcaUint32 Ocp1LiteMessageNotification::GetSize(const ::IOcaLiteWriter& writer) const
{
    const ::OcaLiteMethodID& methodId(GetMethodID());
    return writer.GetSize(static_cast< ::OcaUint32>(0)) +       // Message size
           writer.GetSize(GetTargetONo()) +
           methodId.GetSize(writer) +
           ((GetParametersSize() > 0) ? GetParametersSize() : 1);
}

#ifdef OCA_LITE_CONTROLLER
::OcaLiteStatus Ocp1LiteMessageNotification::UpdateEventData(::OcaUint32& bytesLeft, const ::OcaUint8** source, ::OcaONo ocaONo, const ::IOcaLiteReader& reader)
{
    ::OcaLiteStatus rc(OCASTATUS_PROCESSING_FAILED);
    ::OcaLiteRoot* pOcaLiteRoot(NULL);

    //Read MethodID
    OcaLiteMethodID methodId;
    UnmarshalValue< ::OcaLiteMethodID>(methodId, bytesLeft, source, reader);

    //Read Parameters
    ::OcaUint8 parameterCount(static_cast< ::OcaUint8>(0));
    reader.Read(bytesLeft, source, parameterCount);

    ::OcaLiteBlob context;
    context.Unmarshal(bytesLeft, source, reader);

    pOcaLiteRoot = OcaLiteBlock::GetRootBlock().GetObject(ocaONo);

    ::OcaLiteClassIdentification destClassIdf;
    pOcaLiteRoot->GetClassIdentification(destClassIdf);

   if (destClassIdf.GetClassID()== ::OcaLiteGain::CLASS_ID)
   {
       ::OcaLitePropertyID propertyID(::OcaLiteGain::CLASS_ID.GetFieldCount(),
                                      OCAPROPERTYCHANGETYPE_CURRENT_CHANGED);

       // Initalized with dummy values
       ::OcaLitePropertyChangedEventData<::OcaDB> eventData(
                        static_cast<::OcaONo>(1110),
                        static_cast<const ::OcaLitePropertyID>(propertyID),
                        static_cast<const ::OcaDB>(0.0),
                        OCAPROPERTYCHANGETYPE_CURRENT_CHANGED);

       eventData.Unmarshal(bytesLeft, source, reader);

       WriteParameters(ocaONo,
               static_cast<const ::OcaLiteMethodID>(methodId),
               static_cast<const ::OcaLiteBlob>(context),
               &eventData);

       ::OcaDB gainVal = eventData.GetPropertyValue();
       UpdateNotificationValue(gainVal);

       rc = OCASTATUS_OK;
   }
   else
   {
       rc = OCASTATUS_PROCESSING_FAILED;
   }

   return rc;
}
#endif

