#include <bosepro/module.h>

#include <dbus/dbus.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>

namespace {

class BtControl : public bosepro::Module
{
public:
    BtControl(const bosepro::BlockConfiguration &configuration);
    virtual ~BtControl();

    virtual void process();

private:
    bool ensure_dbus();
    bool ensure_adapter();
    bool register_agent();
    bool set_adapter_properties();
    void handle_message(DBusMessage *msg);

    void reply_ok(DBusMessage *msg);
    void reply_string(DBusMessage *msg, const char *value);
    void reply_uint32(DBusMessage *msg, uint32_t value);

    void trust_device_and_store(const char *device_path);
    void set_device_trusted(const char *device_path);
    std::string device_path_to_mac(const char *device_path) const;

    bool set_property_bool(const char *obj_path,
                           const char *iface,
                           const char *prop,
                           dbus_bool_t value);
    bool set_property_uint32(const char *obj_path,
                             const char *iface,
                             const char *prop,
                             uint32_t value);

    DBusConnection *conn;
    std::string adapter_path;
    std::string last_mac;

    std::chrono::steady_clock::time_point last_adapter_refresh;
    bool agent_registered;

    static constexpr const char *kAgentPath = "/com/bosepro/FusionBtAgent";
    static constexpr const char *kBluezBus = "org.bluez";

    MODULE_DECLARE(BtControl);
};

MODULE_REGISTER(BtControl, "bt_control");

BtControl::BtControl(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      conn(nullptr),
      agent_registered(false)
{
    last_adapter_refresh = std::chrono::steady_clock::time_point::min();
}

BtControl::~BtControl()
{
    if (conn != nullptr) {
        dbus_connection_unref(conn);
        conn = nullptr;
    }
}

void BtControl::process()
{
    if (!ensure_dbus()) {
        return;
    }

    if (adapter_path.empty() && !ensure_adapter()) {
        return;
    }

    if (!agent_registered) {
        if (!register_agent()) {
            return;
        }
        agent_registered = true;
    }

    auto now = std::chrono::steady_clock::now();
    if (last_adapter_refresh == std::chrono::steady_clock::time_point::min() ||
        now - last_adapter_refresh > std::chrono::seconds(10)) {
        set_adapter_properties();
        last_adapter_refresh = now;
    }

    dbus_connection_read_write(conn, 0);
    for (int i = 0; i < 32; ++i) {
        DBusMessage *msg = dbus_connection_pop_message(conn);
        if (msg == nullptr) {
            break;
        }
        handle_message(msg);
        dbus_message_unref(msg);
    }

    if (!dbus_connection_get_is_connected(conn)) {
        SPDLOG_WARN("Bluetooth DBus disconnected, retrying...");
        dbus_connection_unref(conn);
        conn = nullptr;
        adapter_path.clear();
        agent_registered = false;
    }
}

bool BtControl::ensure_dbus()
{
    if (conn != nullptr) {
        return true;
    }

    DBusError err;
    dbus_error_init(&err);

    conn = dbus_bus_get(DBUS_BUS_SYSTEM, &err);
    if (dbus_error_is_set(&err)) {
        SPDLOG_ERROR("DBus connection failed: {}", err.message);
        dbus_error_free(&err);
        conn = nullptr;
        return false;
    }

    if (conn == nullptr) {
        return false;
    }

    dbus_connection_set_exit_on_disconnect(conn, false);
    return true;
}

bool BtControl::ensure_adapter()
{
    if (conn == nullptr) {
        return false;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, "/org/bluez",
        "org.freedesktop.DBus.ObjectManager", "GetManagedObjects");
    if (msg == nullptr) {
        return false;
    }

    DBusError err;
    dbus_error_init(&err);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        SPDLOG_WARN("GetManagedObjects failed: {}", err.message);
        dbus_error_free(&err);
        return false;
    }

    if (reply == nullptr) {
        return false;
    }

    DBusMessageIter iter;
    if (!dbus_message_iter_init(reply, &iter) ||
        dbus_message_iter_get_arg_type(&iter) != DBUS_TYPE_ARRAY) {
        dbus_message_unref(reply);
        return false;
    }

    DBusMessageIter array_iter;
    dbus_message_iter_recurse(&iter, &array_iter);

    while (dbus_message_iter_get_arg_type(&array_iter) == DBUS_TYPE_DICT_ENTRY) {
        DBusMessageIter dict_iter;
        dbus_message_iter_recurse(&array_iter, &dict_iter);

        const char *object_path = nullptr;
        if (dbus_message_iter_get_arg_type(&dict_iter) == DBUS_TYPE_OBJECT_PATH) {
            dbus_message_iter_get_basic(&dict_iter, &object_path);
        }

        if (!dbus_message_iter_next(&dict_iter)) {
            dbus_message_iter_next(&array_iter);
            continue;
        }

        if (dbus_message_iter_get_arg_type(&dict_iter) == DBUS_TYPE_ARRAY) {
            DBusMessageIter iface_array;
            dbus_message_iter_recurse(&dict_iter, &iface_array);
            while (dbus_message_iter_get_arg_type(&iface_array) == DBUS_TYPE_DICT_ENTRY) {
                DBusMessageIter iface_entry;
                dbus_message_iter_recurse(&iface_array, &iface_entry);

                const char *iface_name = nullptr;
                if (dbus_message_iter_get_arg_type(&iface_entry) == DBUS_TYPE_STRING) {
                    dbus_message_iter_get_basic(&iface_entry, &iface_name);
                }

                if (iface_name != nullptr &&
                    std::strcmp(iface_name, "org.bluez.Adapter1") == 0 &&
                    object_path != nullptr) {
                    adapter_path = object_path;
                    dbus_message_unref(reply);
                    SPDLOG_INFO("Found Bluetooth adapter: {}", adapter_path);
                    return true;
                }

                dbus_message_iter_next(&iface_array);
            }
        }

        dbus_message_iter_next(&array_iter);
    }

    dbus_message_unref(reply);
    return false;
}

bool BtControl::register_agent()
{
    if (conn == nullptr) {
        return false;
    }

    DBusError err;
    dbus_error_init(&err);

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, "/org/bluez",
        "org.bluez.AgentManager1", "RegisterAgent");
    if (msg == nullptr) {
        return false;
    }

    const char *capability = "NoInputNoOutput";
    dbus_message_append_args(msg,
                             DBUS_TYPE_OBJECT_PATH, &kAgentPath,
                             DBUS_TYPE_STRING, &capability,
                             DBUS_TYPE_INVALID);

    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        if (std::strcmp(err.name, "org.bluez.Error.AlreadyExists") != 0) {
            SPDLOG_WARN("RegisterAgent failed: {}", err.message);
            dbus_error_free(&err);
            return false;
        }
        dbus_error_free(&err);
    }

    if (reply != nullptr) {
        dbus_message_unref(reply);
    }

    dbus_error_init(&err);
    msg = dbus_message_new_method_call(
        kBluezBus, "/org/bluez",
        "org.bluez.AgentManager1", "RequestDefaultAgent");
    if (msg == nullptr) {
        return false;
    }

    dbus_message_append_args(msg,
                             DBUS_TYPE_OBJECT_PATH, &kAgentPath,
                             DBUS_TYPE_INVALID);

    reply = dbus_connection_send_with_reply_and_block(conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        if (std::strcmp(err.name, "org.bluez.Error.AlreadyExists") != 0) {
            SPDLOG_WARN("RequestDefaultAgent failed: {}", err.message);
            dbus_error_free(&err);
            return false;
        }
        dbus_error_free(&err);
    }

    if (reply != nullptr) {
        dbus_message_unref(reply);
    }

    return true;
}

bool BtControl::set_adapter_properties()
{
    if (adapter_path.empty()) {
        return false;
    }

    bool ok = true;
    ok &= set_property_bool(adapter_path.c_str(), "org.bluez.Adapter1", "Powered", true);
    ok &= set_property_bool(adapter_path.c_str(), "org.bluez.Adapter1", "Pairable", true);
    ok &= set_property_bool(adapter_path.c_str(), "org.bluez.Adapter1", "Discoverable", true);
    ok &= set_property_uint32(adapter_path.c_str(), "org.bluez.Adapter1", "PairableTimeout", 0);
    ok &= set_property_uint32(adapter_path.c_str(), "org.bluez.Adapter1", "DiscoverableTimeout", 0);

    return ok;
}

void BtControl::handle_message(DBusMessage *msg)
{
    const char *iface = dbus_message_get_interface(msg);
    const char *path = dbus_message_get_path(msg);
    if (path == nullptr || std::strcmp(path, kAgentPath) != 0) {
        return;
    }

    if (iface == nullptr || std::strcmp(iface, "org.bluez.Agent1") != 0) {
        return;
    }

    const char *member = dbus_message_get_member(msg);
    if (member == nullptr) {
        return;
    }

    if (std::strcmp(member, "Release") == 0 ||
        std::strcmp(member, "Cancel") == 0 ||
        std::strcmp(member, "DisplayPasskey") == 0 ||
        std::strcmp(member, "DisplayPinCode") == 0) {
        reply_ok(msg);
        return;
    }

    if (std::strcmp(member, "RequestPinCode") == 0) {
        reply_string(msg, "0000");
        return;
    }

    if (std::strcmp(member, "RequestPasskey") == 0) {
        reply_uint32(msg, 0);
        return;
    }

    if (std::strcmp(member, "RequestConfirmation") == 0 ||
        std::strcmp(member, "RequestAuthorization") == 0 ||
        std::strcmp(member, "AuthorizeService") == 0) {
        DBusMessageIter iter;
        const char *device_path = nullptr;
        if (dbus_message_iter_init(msg, &iter) &&
            dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_OBJECT_PATH) {
            dbus_message_iter_get_basic(&iter, &device_path);
        }
        trust_device_and_store(device_path);
        reply_ok(msg);
        return;
    }

    reply_ok(msg);
}

void BtControl::reply_ok(DBusMessage *msg)
{
    DBusMessage *reply = dbus_message_new_method_return(msg);
    if (reply == nullptr) {
        return;
    }
    dbus_connection_send(conn, reply, nullptr);
    dbus_message_unref(reply);
}

void BtControl::reply_string(DBusMessage *msg, const char *value)
{
    DBusMessage *reply = dbus_message_new_method_return(msg);
    if (reply == nullptr) {
        return;
    }
    dbus_message_append_args(reply, DBUS_TYPE_STRING, &value, DBUS_TYPE_INVALID);
    dbus_connection_send(conn, reply, nullptr);
    dbus_message_unref(reply);
}

void BtControl::reply_uint32(DBusMessage *msg, uint32_t value)
{
    DBusMessage *reply = dbus_message_new_method_return(msg);
    if (reply == nullptr) {
        return;
    }
    dbus_message_append_args(reply, DBUS_TYPE_UINT32, &value, DBUS_TYPE_INVALID);
    dbus_connection_send(conn, reply, nullptr);
    dbus_message_unref(reply);
}

void BtControl::trust_device_and_store(const char *device_path)
{
    if (device_path == nullptr) {
        return;
    }

    set_device_trusted(device_path);

    std::string mac = device_path_to_mac(device_path);
    if (mac.empty() || mac == last_mac) {
        return;
    }

    try {
        std::filesystem::create_directories("/etc/fusion");
        std::ofstream out("/etc/fusion/bt_last_device", std::ios::trunc);
        out << mac << "\n";
        out.close();
        last_mac = mac;
    } catch (...) {
        SPDLOG_WARN("Failed to write /etc/fusion/bt_last_device");
    }
}

void BtControl::set_device_trusted(const char *device_path)
{
    if (device_path == nullptr) {
        return;
    }
    set_property_bool(device_path, "org.bluez.Device1", "Trusted", true);
}

std::string BtControl::device_path_to_mac(const char *device_path) const
{
    std::string path(device_path);
    auto pos = path.find("dev_");
    if (pos == std::string::npos) {
        return "";
    }

    std::string mac = path.substr(pos + 4);
    for (auto &c : mac) {
        if (c == '_') {
            c = ':';
        }
    }
    return mac;
}

bool BtControl::set_property_bool(const char *obj_path,
                                  const char *iface,
                                  const char *prop,
                                  dbus_bool_t value)
{
    if (conn == nullptr) {
        return false;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, obj_path,
        "org.freedesktop.DBus.Properties", "Set");
    if (msg == nullptr) {
        return false;
    }

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &iface);
    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &prop);

    DBusMessageIter variant;
    dbus_message_iter_open_container(&iter, DBUS_TYPE_VARIANT, "b", &variant);
    dbus_message_iter_append_basic(&variant, DBUS_TYPE_BOOLEAN, &value);
    dbus_message_iter_close_container(&iter, &variant);

    DBusError err;
    dbus_error_init(&err);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        dbus_error_free(&err);
        return false;
    }

    if (reply != nullptr) {
        dbus_message_unref(reply);
    }
    return true;
}

bool BtControl::set_property_uint32(const char *obj_path,
                                    const char *iface,
                                    const char *prop,
                                    uint32_t value)
{
    if (conn == nullptr) {
        return false;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, obj_path,
        "org.freedesktop.DBus.Properties", "Set");
    if (msg == nullptr) {
        return false;
    }

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &iface);
    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &prop);

    DBusMessageIter variant;
    dbus_message_iter_open_container(&iter, DBUS_TYPE_VARIANT, "u", &variant);
    dbus_message_iter_append_basic(&variant, DBUS_TYPE_UINT32, &value);
    dbus_message_iter_close_container(&iter, &variant);

    DBusError err;
    dbus_error_init(&err);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        dbus_error_free(&err);
        return false;
    }

    if (reply != nullptr) {
        dbus_message_unref(reply);
    }
    return true;
}

} // namespace
