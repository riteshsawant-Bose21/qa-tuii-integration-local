/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

#ifndef OCALITECONTROLLERCONFIGMANAGER_H
#define OCALITECONTROLLERCONFIGMANAGER_H

#include "../../common/OCALite/OCC/ControlClasses/Managers/OcaLiteManager.h"
#include "../../common/OCALite/OCC/ControlDataTypes/OcaLiteString.h"
#include <string>
#include <vector>

// Forward declarations to avoid heavy includes in the header.
struct Controller;

class OcaLiteControllerConfigManager : public ::OcaLiteManager
{
public:
    /**
     * The object number of the controller config manager
     */
    static const ::OcaONo MANAGER_ONO;

    /**
     * Number that uniquely identifies the class. Note that this differs from the object number, which
     * identifies the instantiated object. This is a class property instead of an object property. This
     * property will be overridden by each descendant class, in order to specify that class's ClassID.
     */
    static const ::OcaLiteClassID CLASS_ID;

    static ::OcaLiteControllerConfigManager &GetInstance();
    static void FreeInstance();

    bool Initialize();

    virtual ::OcaClassVersionNumber GetClassVersion() const;

    ::OcaLiteStatus GetConfigDetails(const ::OcaLiteString &controllerId,
                                     ::OcaLiteString &configData) const;

    // Accept list of controllers and store them for filtering by controller ID
    void SetConfigData(const std::vector<Controller> &controllers);

    enum MethodIndex
    {
        GET_CONFIG_DETAILS = 1
    };

protected:
    OcaLiteControllerConfigManager();
    virtual ~OcaLiteControllerConfigManager();

    virtual bool GetClassIdentification(::OcaLiteClassIdentification &classIdentification) const;

    virtual ::OcaLiteStatus Execute(const ::IOcaLiteReader &reader,
                                    const ::IOcaLiteWriter &writer,
                                    ::OcaSessionID sessionID,
                                    const ::OcaLiteMethodID &methodID,
                                    ::OcaUint32 parametersSize,
                                    const ::OcaUint8 *parameters,
                                    ::OcaUint8 **response);

private:
    OcaLiteControllerConfigManager(const ::OcaLiteControllerConfigManager &);
    ::OcaLiteControllerConfigManager &operator=(const ::OcaLiteControllerConfigManager &);

    static ::OcaLiteControllerConfigManager *m_pSingleton;
    std::vector<Controller> m_controllers;

};

#endif // OCALITECONTROLLERCONFIGMANAGER_H
