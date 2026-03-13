#include <bosepro/module.h>

#include <dbus/dbus.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <cstring>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <sstream>

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
    bool ensure_signal_matches();
    bool register_agent();
    bool set_adapter_properties();
    bool set_adapter_class();
    void handle_message(DBusMessage *msg);
    void handle_signal(DBusMessage *msg);
    void handle_properties_changed(DBusMessage *msg);

    void track_pairing_attempt(const char *device_path);
    void clear_pairing_attempt();
    void track_connect_attempt(const char *device_path);
    void note_connect_activity(const char *path);
    void handle_connect_drop(const char *device_path);

    void reply_ok(DBusMessage *msg);
    void reply_string(DBusMessage *msg, const char *value);
    void reply_uint32(DBusMessage *msg, uint32_t value);

    void trust_device_and_store(const char *device_path);
    void set_device_trusted(const char *device_path);
    bool is_device_paired(const char *device_path);
    void remove_device(const char *device_path);
    std::string device_path_to_mac(const char *device_path) const;

    bool set_property_bool(const char *obj_path,
                           const char *iface,
                           const char *prop,
                           dbus_bool_t value);
    bool set_property_uint32(const char *obj_path,
                             const char *iface,
                             const char *prop,
                             uint32_t value);
    bool get_property_bool(const char *obj_path,
                           const char *iface,
                           const char *prop,
                           dbus_bool_t &out_value);

    DBusConnection *conn;
    std::string adapter_path;
    std::string last_mac;

    std::chrono::steady_clock::time_point last_adapter_refresh;
    std::chrono::steady_clock::time_point last_adapter_warn;
    bool agent_registered;
    bool class_set;
    bool signal_matches_installed;
    bool connect_attempt_was_paired;
    bool connect_attempt_had_followon_activity;
    std::string pending_device_path;
    std::string connect_attempt_device_path;
    std::chrono::steady_clock::time_point connect_attempt_started_at;

    static constexpr const char *kAgentPath = "/com/bosepro/FusionBtAgent";
    static constexpr const char *kBluezBus = "org.bluez";

    MODULE_DECLARE(BtControl);
};

MODULE_REGISTER(BtControl, "bt_control");

BtControl::BtControl(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      conn(nullptr),
      agent_registered(false),
      class_set(false),
      signal_matches_installed(false),
      connect_attempt_was_paired(false),
      connect_attempt_had_followon_activity(false)
{
    last_adapter_refresh = std::chrono::steady_clock::time_point::min();
    last_adapter_warn = std::chrono::steady_clock::time_point::min();
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

    if (!signal_matches_installed && !ensure_signal_matches()) {
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
        signal_matches_installed = false;
        clear_pairing_attempt();
        connect_attempt_device_path.clear();
        connect_attempt_was_paired = false;
        connect_attempt_had_followon_activity = false;
        connect_attempt_started_at = std::chrono::steady_clock::time_point::min();
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

    // Sysfs-only: read adapter from /sys/class/bluetooth (e.g. hci0).
    try {
        for (const auto &entry : std::filesystem::directory_iterator("/sys/class/bluetooth")) {
            if (!entry.is_directory() && !entry.is_symlink()) {
                continue;
            }
            const std::string name = entry.path().filename().string();
            if (name.rfind("hci", 0) == 0) {
                adapter_path = std::string("/org/bluez/") + name;
                return true;
            }
        }
    } catch (...) {
        // ignore and fall through
    }

    auto now = std::chrono::steady_clock::now();
    if (last_adapter_warn == std::chrono::steady_clock::time_point::min() ||
        now - last_adapter_warn > std::chrono::seconds(10)) {
        SPDLOG_WARN("Bluetooth adapter not available yet (sysfs)");
        last_adapter_warn = now;
    }
    return false;
}


bool BtControl::ensure_signal_matches()
{
    if (conn == nullptr) {
        return false;
    }

    DBusError err;
    dbus_error_init(&err);

    dbus_bus_add_match(conn,
                       "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'",
                       &err);
    dbus_connection_flush(conn);

    if (dbus_error_is_set(&err)) {
        SPDLOG_WARN("Failed to install BlueZ signal match: {}", err.message);
        dbus_error_free(&err);
        return false;
    }

    signal_matches_installed = true;
    return true;
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
    ok &= set_adapter_class();

    return ok;
}

bool BtControl::set_adapter_class()
{
    if (class_set) {
        return true;
    }

    int rc = std::system("hciconfig hci0 class 0x240414");
    if (rc == 0) {
        class_set = true;
        SPDLOG_INFO("Bluetooth class set to 0x240414");
        return true;
    }

    SPDLOG_WARN("Failed to set Bluetooth class (hciconfig rc={})", rc);
    return false;
}

void BtControl::handle_message(DBusMessage *msg)
{
    if (dbus_message_get_type(msg) == DBUS_MESSAGE_TYPE_SIGNAL) {
        handle_signal(msg);
        return;
    }

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

    if (std::strcmp(member, "Release") == 0) {
        agent_registered = false;
        reply_ok(msg);
        return;
    }

    if (std::strcmp(member, "Cancel") == 0) {
        clear_pairing_attempt();
        reply_ok(msg);
        return;
    }

    if (std::strcmp(member, "DisplayPasskey") == 0 ||
        std::strcmp(member, "DisplayPinCode") == 0) {
        reply_ok(msg);
        return;
    }

    if (std::strcmp(member, "RequestPinCode") == 0) {
        DBusMessageIter iter;
        const char *device_path = nullptr;
        if (dbus_message_iter_init(msg, &iter) &&
            dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_OBJECT_PATH) {
            dbus_message_iter_get_basic(&iter, &device_path);
        }
        track_pairing_attempt(device_path);
        reply_string(msg, "0000");
        return;
    }

    if (std::strcmp(member, "RequestPasskey") == 0) {
        DBusMessageIter iter;
        const char *device_path = nullptr;
        if (dbus_message_iter_init(msg, &iter) &&
            dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_OBJECT_PATH) {
            dbus_message_iter_get_basic(&iter, &device_path);
        }
        track_pairing_attempt(device_path);
        reply_uint32(msg, 0);
        return;
    }

    if (std::strcmp(member, "RequestConfirmation") == 0) {
        DBusMessageIter iter;
        const char *device_path = nullptr;
        if (dbus_message_iter_init(msg, &iter) &&
            dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_OBJECT_PATH) {
            dbus_message_iter_get_basic(&iter, &device_path);
        }
        track_pairing_attempt(device_path);
        trust_device_and_store(device_path);
        reply_ok(msg);
        return;
    }

    if (std::strcmp(member, "RequestAuthorization") == 0 ||
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

void BtControl::handle_signal(DBusMessage *msg)
{
    const char *iface = dbus_message_get_interface(msg);
    const char *member = dbus_message_get_member(msg);
    const char *path = dbus_message_get_path(msg);

    if (path != nullptr) {
        note_connect_activity(path);
    }

    if (iface == nullptr || member == nullptr) {
        return;
    }

    if (std::strcmp(iface, "org.freedesktop.DBus.Properties") == 0 &&
        std::strcmp(member, "PropertiesChanged") == 0) {
        handle_properties_changed(msg);
    }
}

void BtControl::handle_properties_changed(DBusMessage *msg)
{
    const char *path = dbus_message_get_path(msg);
    if (path == nullptr) {
        return;
    }

    DBusMessageIter iter;
    if (!dbus_message_iter_init(msg, &iter) ||
        dbus_message_iter_get_arg_type(&iter) != DBUS_TYPE_STRING) {
        return;
    }

    const char *iface = nullptr;
    dbus_message_iter_get_basic(&iter, &iface);
    if (iface == nullptr) {
        return;
    }

    if (!dbus_message_iter_next(&iter) ||
        dbus_message_iter_get_arg_type(&iter) != DBUS_TYPE_ARRAY) {
        return;
    }

    const bool is_device = std::strcmp(iface, "org.bluez.Device1") == 0;
    const bool is_adapter = std::strcmp(iface, "org.bluez.Adapter1") == 0;
    if (!is_device && !is_adapter) {
        return;
    }

    DBusMessageIter dict;
    dbus_message_iter_recurse(&iter, &dict);
    while (dbus_message_iter_get_arg_type(&dict) == DBUS_TYPE_DICT_ENTRY) {
        DBusMessageIter entry;
        dbus_message_iter_recurse(&dict, &entry);

        if (dbus_message_iter_get_arg_type(&entry) == DBUS_TYPE_STRING) {
            const char *prop = nullptr;
            dbus_message_iter_get_basic(&entry, &prop);
            if (prop != nullptr && dbus_message_iter_next(&entry) &&
                dbus_message_iter_get_arg_type(&entry) == DBUS_TYPE_VARIANT) {
                DBusMessageIter variant;
                dbus_message_iter_recurse(&entry, &variant);
                const int type = dbus_message_iter_get_arg_type(&variant);

                if (is_device && type == DBUS_TYPE_BOOLEAN) {
                    dbus_bool_t value = false;
                    dbus_message_iter_get_basic(&variant, &value);

                    if (pending_device_path == path &&
                        (std::strcmp(prop, "Paired") == 0 ||
                         std::strcmp(prop, "ServicesResolved") == 0) && value) {
                        clear_pairing_attempt();
                    }

                    if (std::strcmp(prop, "Connected") == 0) {
                        if (value) {
                            track_connect_attempt(path);
                        } else {
                            handle_connect_drop(path);
                        }
                    } else if (std::strcmp(prop, "ServicesResolved") == 0 && value) {
                        note_connect_activity(path);
                    }
                }
            }
        }

        dbus_message_iter_next(&dict);
    }

}

void BtControl::track_pairing_attempt(const char *device_path)
{
    if (device_path == nullptr) {
        return;
    }

    const std::string path(device_path);
    if (pending_device_path == path) {
        return;
    }

    pending_device_path = path;
}

void BtControl::clear_pairing_attempt()
{
    pending_device_path.clear();
}

void BtControl::track_connect_attempt(const char *device_path)
{
    if (device_path == nullptr) {
        return;
    }

    connect_attempt_device_path = device_path;
    connect_attempt_started_at = std::chrono::steady_clock::now();
    connect_attempt_was_paired = is_device_paired(device_path);
    connect_attempt_had_followon_activity = false;

}

void BtControl::note_connect_activity(const char *path)
{
    if (path == nullptr || connect_attempt_device_path.empty()) {
        return;
    }

    const std::string signal_path(path);
    if (signal_path.rfind(connect_attempt_device_path + "/", 0) == 0) {
        connect_attempt_had_followon_activity = true;
    }
}

void BtControl::handle_connect_drop(const char *device_path)
{
    if (device_path == nullptr || connect_attempt_device_path.empty()) {
        return;
    }

    if (connect_attempt_device_path != device_path) {
        return;
    }

    const auto age = std::chrono::steady_clock::now() - connect_attempt_started_at;
    const bool should_remove =
        connect_attempt_was_paired &&
        !connect_attempt_had_followon_activity &&
        pending_device_path.empty() &&
        age <= std::chrono::seconds(10) &&
        is_device_paired(device_path);

    if (should_remove) {
        remove_device(device_path);
    }

    connect_attempt_device_path.clear();
    connect_attempt_was_paired = false;
    connect_attempt_had_followon_activity = false;
    connect_attempt_started_at = std::chrono::steady_clock::time_point::min();
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

bool BtControl::is_device_paired(const char *device_path)
{
    if (device_path == nullptr) {
        return false;
    }

    dbus_bool_t paired = false;
    if (!get_property_bool(device_path, "org.bluez.Device1", "Paired", paired)) {
        return false;
    }
    return paired != 0;
}

void BtControl::remove_device(const char *device_path)
{
    if (device_path == nullptr || adapter_path.empty() || conn == nullptr) {
        return;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, adapter_path.c_str(),
        "org.bluez.Adapter1", "RemoveDevice");
    if (msg == nullptr) {
        return;
    }

    dbus_message_append_args(msg,
                             DBUS_TYPE_OBJECT_PATH, &device_path,
                             DBUS_TYPE_INVALID);

    DBusError err;
    dbus_error_init(&err);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        SPDLOG_WARN("RemoveDevice failed: {}", err.message);
        dbus_error_free(&err);
    }

    if (reply != nullptr) {
        dbus_message_unref(reply);
    }
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

bool BtControl::get_property_bool(const char *obj_path,
                                  const char *iface,
                                  const char *prop,
                                  dbus_bool_t &out_value)
{
    if (conn == nullptr) {
        return false;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        kBluezBus, obj_path,
        "org.freedesktop.DBus.Properties", "Get");
    if (msg == nullptr) {
        return false;
    }

    dbus_message_append_args(msg,
                             DBUS_TYPE_STRING, &iface,
                             DBUS_TYPE_STRING, &prop,
                             DBUS_TYPE_INVALID);

    DBusError err;
    dbus_error_init(&err);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(
        conn, msg, 3000, &err);
    dbus_message_unref(msg);

    if (dbus_error_is_set(&err)) {
        dbus_error_free(&err);
        return false;
    }

    if (reply == nullptr) {
        return false;
    }

    DBusMessageIter iter;
    if (!dbus_message_iter_init(reply, &iter) ||
        dbus_message_iter_get_arg_type(&iter) != DBUS_TYPE_VARIANT) {
        dbus_message_unref(reply);
        return false;
    }

    DBusMessageIter variant;
    dbus_message_iter_recurse(&iter, &variant);
    if (dbus_message_iter_get_arg_type(&variant) != DBUS_TYPE_BOOLEAN) {
        dbus_message_unref(reply);
        return false;
    }

    dbus_message_iter_get_basic(&variant, &out_value);
    dbus_message_unref(reply);
    return true;
}

} // namespace
