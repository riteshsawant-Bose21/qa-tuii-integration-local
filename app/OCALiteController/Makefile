# OCALiteController Makefile
BUILD_DIR := build

# Detect platform for DNS-SD support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CXX=g++
    # macOS: Use native DNS-SD framework
    PKG_CFLAGS :=
    PKG_LIBS := -framework CoreServices
    LDFLAGS :=
else ifeq ($(ARCH),arm64)
    PKG_LIBS   := -L ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/lib
    PKG_CFLAGS := -I ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include
    PKG_CDEFS  := -DFUSION
    LDFLAGS    := -ldns_sd
else
    CXX=g++
    PKG_CFLAGS :=
    PKG_LIBS :=
    PKG_CDEFS  :=
    LDFLAGS := -ldns_sd
endif

# ================================
# Cross-platform jsoncpp support
# ================================
ifeq ($(UNAME_S),Darwin)
    # macOS: Prefer pkg-config, fallback to Homebrew paths
    PKGCONF := pkg-config
    JSONCPP_LIBS := $(shell $(PKGCONF) --libs jsoncpp 2>/dev/null || echo "-L/opt/homebrew/lib -ljsoncpp")
    JSONCPP_CFLAGS := $(shell $(PKGCONF) --cflags jsoncpp 2>/dev/null || echo "-I/opt/homebrew/include")
else ifeq ($(ARCH),arm64)
    # Cross-compile ARM64: Use SDK paths if available, otherwise standard Linux
    ifneq ($(SDK_DIR),)
        JSONCPP_LIBS := -ljsoncpp
        JSONCPP_CFLAGS := -I${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include/jsoncpp
    else
        JSONCPP_LIBS := -ljsoncpp
        JSONCPP_CFLAGS := -I/usr/include/jsoncpp
    endif
else
    # Linux: Standard system paths
    JSONCPP_LIBS := -ljsoncpp
    JSONCPP_CFLAGS := -I/usr/include/jsoncpp
endif

# Add jsoncpp flags to existing variables
PKG_CFLAGS += $(JSONCPP_CFLAGS)
PKG_LIBS += $(JSONCPP_LIBS)

CXXFLAGS := -Wall -Wextra -std=c++17 -g -O0 $(PKG_CFLAGS) \
	    $(PKG_CDEFS) \
	    -DOCA_LITE_CONTROLLER \
	    -DOCA_RUN \
	    -D_DEBUG \
	    -I../common \
	    -I../../common \
	    -I../../common/HostInterfaceLite \
	    -I../../common/OCALite \
	    -I../../common/OCALite/OCC \
	    -I../../common/OCALite/OCF \
	    -I../../common/OCALite/OCP.1 \
	    -I../../common/OCALite/Proxy

FRAMEWORK_COMMON_SOURCES := \
		../../common/OCALite/OCF/Messages/OcaLiteMessageKeepAlive.cpp \
		../../common/OCALite/OCF/Messages/OcaLiteMessageGeneral.cpp \
		../../common/OCALite/OCF/Messages/OcaLiteMessageResponse.cpp \
		../../common/OCALite/OCF/Messages/OcaLiteMessageCommand.cpp \
		../../common/OCALite/OCF/Messages/OcaLiteMessageNotification.cpp \
		../../common/OCALite/OCF/Messages/OcaLiteHeader.cpp \
		../../common/OCALite/OCF/OcaLiteCommandHandler.cpp \
		../../common/OCALite/OCF/OcaLiteCommandHandlerController.cpp \
		../../common/OCALite/OCC/ControlClasses/Agents/OcaLiteAgent.cpp \
		../../common/OCALite/OCC/ControlClasses/Agents/OcaLiteNetwork.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/OcaLiteWorker.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/BlocksAndMatrices/OcaLiteBlock.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteBooleanActuator.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteGain.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteActuator.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteMute.cpp  \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteSwitch.cpp \
		../../common/OCALite/OCC/ControlClasses/Workers/Actuators/OcaLiteBasicActuator.cpp \
		../../common/OCALite/OCC/ControlClasses/Managers/OcaLiteDeviceManager.cpp \
		../../common/OCALite/OCC/ControlClasses/Managers/OcaLiteNetworkManager.cpp \
		../../common/OCALite/OCC/ControlClasses/Managers/OcaLiteManager.cpp \
		../../common/OCALite/OCC/ControlClasses/Managers/OcaLiteSubscriptionManager.cpp \
		../../common/OCALite/OCC/ControlClasses/OcaLiteRoot.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteEventID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLitePropertyChangedEventData.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLitePortID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteFrameworkDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteMethodID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteStream.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteMultiMap.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteMap.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteBlockMember.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteNetworkAddress.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteObjectIdentification.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteEventSubscriptionDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteNetworkSystemInterfaceDescriptor.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteBlobDataType.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteBlob.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteClassIdentification.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteVersion.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteBlobFixedLen.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteModelDescription.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteEvent.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteNetworkDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteManagementDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLitePropertyID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteList.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteStringInABlob.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteMethod.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteConnectParameters.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteApplicationNetworkDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteNetworkSystemInterfaceID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteWorkerDataTypes.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteManagerDescriptor.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteModelGUID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteString.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteEventData.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLitePort.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteClassID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteStreamConnectorID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteStreamID.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteStreamParameters.cpp \
		../../common/OCALite/OCC/ControlDataTypes/OcaLiteTemplateHelpers.cpp  \
		../../common/OCALite/OCP.1/Ocp1LiteSocketConnection.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteConnectParameters.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteNetworkAddress.cpp \
		../../common/OCALite/OCP.1/Messages/Ocp1LiteMessageKeepAlive.cpp \
		../../common/OCALite/OCP.1/Messages/Ocp1LiteMessageCommand.cpp \
		../../common/OCALite/OCP.1/Messages/Ocp1LiteMessageHeader.cpp \
		../../common/OCALite/OCP.1/Messages/Ocp1LiteMessageResponse.cpp \
		../../common/OCALite/OCP.1/Messages/Ocp1LiteMessageNotification.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteNetwork.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteReader.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteNetworkSystemInterfaceID.cpp \
		../../common/OCALite/OCP.1/Ocp1LiteWriter.cpp \
		../../common/OCALite/Proxy/GeneralProxy.cpp \
		../../common/HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.cpp \
		../../common/HostInterfaceLite/OCA/OCP.1/Ocp1LiteHostInterface.cpp \

# Source files from the app-level common directory
APP_COMMON_SOURCES       := ../common/FusionProxy.cpp \
                            ../common/workers/ZoneGroup.cpp

# App-specific source files
APP_SOURCES := main.cpp \
	       OCALiteController.cpp \
               OcaServiceDiscovery.cpp \
               ControlPalSetupUtils.cpp \
               ControlPalOcaUtils.cpp \
               ControlPalCommandHandler.cpp \
               workers/ControlPalGainActuator.cpp \
               workers/ControlPalMuteActuator.cpp \
               workers/ControlPalSwitchActuator.cpp \
	       HostInterface/OCA/OCF/Configuration/OcaLiteOcfConfiguration.cpp \
	       HostInterface/OCA/OCF/Logging/OcaLiteOcfLogger.cpp \
	       HostInterface/OCA/OCF/Timer/OcaLiteOcfTimer.cpp \
	       HostInterface/OCA/OCP.1/ZeroConf/OcaLiteOcp1Service.cpp \
	       HostInterface/OCA/OCP.1/Network/OcaLiteOcp1Socket.cpp \
	       HostInterface/OCA/OCP.1/Network/OcaLiteOcp1Network.cpp \
	       HostInterface/OCA/OCP.1/Ocp1HostInterfaceOcaLite.cpp

VIEW_SOURCES := View/Platform/linux/View.cpp \
	    	View/Platform/linux/ControllerMenu.cpp

PLATFORM_SOURCES := PlatformInterface/linux/OcaLiteOcfThread.cpp

# Object files in build directory, preserving directory structure
FRAMEWORK_COMMON_OBJECTS   := $(patsubst ../../common/%.cpp,$(BUILD_DIR)/framework-common/%.o,$(FRAMEWORK_COMMON_SOURCES))
APP_COMMON_OBJECTS         := $(patsubst ../common/%.cpp,$(BUILD_DIR)/app-common/%.o,$(APP_COMMON_SOURCES))
APP_OBJECTS                := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(APP_SOURCES))
VIEW_OBJECTS               := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(VIEW_SOURCES))
PLATFORM_OBJECTS           := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(PLATFORM_SOURCES))
ALL_OBJECTS                := $(APP_OBJECTS) $(VIEW_OBJECTS) $(PLATFORM_OBJECTS) $(FRAMEWORK_COMMON_OBJECTS) $(APP_COMMON_OBJECTS)

# Output executable
TARGET := ocalitecontroller

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS)
	$(CXX) $^ $(PKG_LIBS) -o $@ -lpthread -lc $(LDFLAGS)

# Rule for app-specific sources
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Rule for app-common sources
$(BUILD_DIR)/app-common/%.o: ../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Rule for framework-common sources
$(BUILD_DIR)/framework-common/%.o: ../../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
