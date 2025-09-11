#pragma once

#include <stdlib.h>
#include <unistd.h>

#define REQ_RESP_ARG_SIZE 256

int process_pub_register_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             void *argval);
int process_pub_register_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             void *argval);

int process_pub_deregister_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             void *unused);
int process_pub_deregister_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             void *unused);

int process_update_meters_req(const std::string& req_type,
                              uint64_t& pkt_id,
                              std::ostringstream& message,
                             void *unused);

int process_update_meters_rsp(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             void *type);
int process_meter_data(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       void *type);

int process_send_meter_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             void *type);
int process_send_meter_rsp(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       void *type);

int process_event(bosepro::telemetryManager& telm_mgr,
                  const bosepro::Telemetry_configuration& proc_pkt,
                  uint64_t& pkt_id, std::string& req_name,
                  void *value_str);
int process_event_rsp(bosepro::telemetryManager& telm_mgr,
                      std::string& req_name,
                      uint64_t pkt_id, bool ok_nok,
                      std::ostringstream& message,
                      void *not_used);
void process_event_relay(const bosepro::Telemetry_configuration& proc_pkt,
                         std::ostringstream& message);

int process_update_report_period_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             void *unused);
int process_update_report_period_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             void *unused);
