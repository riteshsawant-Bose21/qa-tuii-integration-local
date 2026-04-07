#pragma once

#include <bosepro/telemetry_version.h>

#include <stdlib.h>
#include <unistd.h>
#include <string>
#include <sstream>

namespace bosepro
{
class telemetryManager;
class Telemetry_configuration;
struct HandlerContext;
}

#define REQ_RESP_ARG_SIZE 256

void set_device_id(const std::string &device_id);

int process_pub_register_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& argval);
int process_pub_register_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& argval);

int process_pub_deregister_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& unused);
int process_pub_deregister_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& unused);

int process_update_meters_req(const std::string& req_type,
                              uint64_t& pkt_id,
                              std::ostringstream& message,
                             bosepro::HandlerContext& unused);

int process_update_meters_rsp(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& type);
int process_meter_data(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       bosepro::HandlerContext& type);

int process_send_meter_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& type);
int process_send_meter_rsp(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       bosepro::HandlerContext& type);

int process_event(bosepro::telemetryManager& telm_mgr,
                  const bosepro::Telemetry_configuration& proc_pkt,
                  uint64_t& pkt_id, std::string& req_name,
                  bosepro::HandlerContext& value_str);
int process_event_rsp(bosepro::telemetryManager& telm_mgr,
                      std::string& req_name,
                      uint64_t pkt_id, bool ok_nok,
                      std::ostringstream& message,
                      bosepro::HandlerContext& not_used);
void process_event_relay(const bosepro::Telemetry_configuration& proc_pkt,
                         std::ostringstream& message);

int process_update_report_period_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& unused);
int process_update_report_period_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& unused);
