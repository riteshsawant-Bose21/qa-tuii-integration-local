#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <iostream>
#include <variant>
#include <vector>
#include <list>
#include <algorithm>
#include <boost/program_options.hpp>
#include <boost/json/src.hpp>
#include <boost/property_tree/json_parser.hpp>
#include "telemetry_core.h"
#include "telemetry_utils.h"
#include "telemetry_msg_handler.h"

// Message Format:
//  "parameters": {
//     "name": <Name>,
//     "block_size": [<hi>, <med>, <lo>]
//  }
int process_pub_register_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& /*unused*/)
{
    std::vector<int_fast32_t> shm_size;
    int ret_val = 0;

    // Get Sub name
    if (proc_pkt.get_value("name", req_name))
    {
        // Get address
        proc_pkt.get_config_value_vector("block_size", shm_size);
        SPDLOG_DEBUG("Size: [ {}, {}, {}]",
                      shm_size[0], shm_size[1], shm_size[2]);

        std::vector<bosepro::shared_mem_config> shm_config = {
            {NULL, ("telm_"+req_name+"_hi"), static_cast<uint32_t>(shm_size[0])},
            {NULL, ("telm_"+req_name+"_med"), static_cast<uint32_t>(shm_size[1])},
            {NULL, ("telm_"+req_name+"_lo"), static_cast<uint32_t>(shm_size[2])}
        };

        // Register Publisher
        ret_val = telm_mgr.register_publisher(req_name, shm_config);
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:pub_register_rsp,
//      packet_id: pkt_id,
//      parameters:{
//      name:pub_name
//      block_name:[HI, MED, LO]
//      value:OK_NOK(0/1)
//   }
int process_pub_register_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& /*unused*/)
{
    message << "{";
    message << "\"message_name\":\"pub_register_rsp\",";
    message << "\"packet_id\":" << pkt_id << ",";
    message << "\"parameters\":{";
    message << "\"name\":\"" << req_name << "\",";
    message << "\"block_name\":[";

    if (ok_nok)
    {
        message << "\"" << telm_mgr.get_pub_shared_mem_name(req_name, TELM_METER_CTGRY_HI_PRIO) << "\"" << ",";
        message << "\"" << telm_mgr.get_pub_shared_mem_name(req_name, TELM_METER_CTGRY_MED_PRIO) << "\"" << ",";
        message << "\"" << telm_mgr.get_pub_shared_mem_name(req_name, TELM_METER_CTGRY_LO_PRIO) << "\"";
    }
    else
    {
        message << "\"0\",";
        message << "\"0\",";
        message << "\"0\"";
    }
    message << "],";

    message << "\"value\":\"" << (ok_nok ? "OK" : "NOK") << "\"";
    message << "}";
    message << "}\n";

    SPDLOG_DEBUG("Pub reg resp");

    return 0;
}

// Message Format:
//  "parameters": {
//     "name": <Name>
//  }
int process_pub_deregister_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& /*unused*/)
{
    int ret_val = 0;

    // Get Sub name
    if (proc_pkt.get_value("name", req_name))
    {
        SPDLOG_DEBUG("Pub. Name: {}", req_name);

        ret_val = telm_mgr.deregister_publisher(req_name);
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:pub_register_rsp,
//      packet_id: pkt_id,
//      parameters:{
//      name:pub_name
//      block_name:[HI, MED, LO]
//      value:OK_NOK(0/1)
//   }
int process_pub_deregister_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& /*unused*/)
{
    message << "{";
    message << "\"message_name\":\"pub_deregister_rsp\",";
    message << "\"packet_id\":" << pkt_id << ",";
    message << "\"parameters\":{";
    message << "\"name\":\"" << req_name << "\",";
    message << "\"value\":\"" << (ok_nok ? "OK" : "NOK") << "\"";
    message << "}";
    message << "}\n";

    return 0;
}

// Message Format:
//   message_name:update_meters_req,
//      packet_id: pkt_id,
//      parameters:{
//      type:[HI, MED, LO]
//   }
int process_update_meters_req(const std::string& req_type,
                              uint64_t& pkt_id,
                              std::ostringstream& message,
                             bosepro::HandlerContext& /*unused*/)
{

    pkt_id = get_realtime_ns();

    message << "{";
    message << "\"message_name\":\"update_meters_req\",";
    message << "\"packet_id\":" << pkt_id << ",";
    message << "\"parameters\":{";

    message << "\"period_type\":\"" << req_type << "\"";
    message << "}";
    message << "}\n";

    SPDLOG_DEBUG("Update meters req ({} - {}).", req_type, pkt_id);

    return 0;
}

// Message Format:
//   message_name:update_meters_rsp,
//      packet_id: pkt_id,
//      parameters:{
//      name:pub_name
//      value:OK_NOK(0/1)
//   }
int process_update_meters_rsp(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& ctx)
{
    int ret_val = 0;
    std::string ok_nok;
    enum eMeterCategory meter_type;

    // Get Sub name
    if ((proc_pkt.get_value("name", req_name)) &&
        (proc_pkt.get_value("value", ok_nok)))
    {
        // This validates if the response matches one of the
        // requests (process_update_meters_req()).
        ret_val = telm_mgr.validate_update_meter_rsp(pkt_id, req_name,
                                                     ok_nok, meter_type);

        // The meter type is used by process_meter_data() (response handler)
        ctx.meter_type = meter_type;
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:meter_data,
//      packet_id: pkt_id,
//      parameters:{
//      name:pub_name
//      type:[HI, MED, LO]
//      length:<length>
//      value:meter data string
//   }
int process_meter_data(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       bosepro::HandlerContext& ctx)
{
    std::string meter_data;
    std::string meter_type;
    std::size_t size;
    int ret_val = -1;

    // Check if it is time to report meter data
    if (ok_nok && telm_mgr.time_to_report_meter(req_name, ctx.meter_type))
    {
        int err_cnt = 0;
        while (1)
        {
                size = telm_mgr.get_meter_data(req_name,
                                           ctx.meter_type,
                                           meter_data);

            std::stringstream temp;
            temp << "[" << meter_data << "]";

            // Validate meter data format
            try {
                // Handle JSON parsing errors, e.g., invalid syntax,
                // file not found etc.
                bosepro::Telemetry_configuration verify_meter(temp);

                ret_val = 0;
                break;

            } catch (const boost::property_tree::json_parser::json_parser_error& e) {
                if (++err_cnt >= 5)
                {
                    SPDLOG_WARN("Corrupted meter Data!");
                    break;
                }
                else
                {
                    SPDLOG_DEBUG("JSON parser error: {} at line {}",
                                 e.what(), e.line());
                    continue;
                }
            } catch (const std::exception& e) {
                // Handle other standard exceptions that might occur
                SPDLOG_ERROR("Standard exception: {} ", e.what());
            } catch (...) {
                // Handle any other unexpected exceptions
                SPDLOG_ERROR("Unknown exception occurred ");
            }

        } //while(1)

        SPDLOG_DEBUG("Meter Data SIze: {}", size);
        if ((ret_val == 0) && (size > 0) )
        {
            uint64_t tx_pkt_id = get_realtime_ns();

            switch (ctx.meter_type)
            {
                case TELM_METER_CTGRY_HI_PRIO:
                    meter_type.assign("HI");
                    break;

                case TELM_METER_CTGRY_MED_PRIO:
                    meter_type.assign("MED");
                    break;

                case TELM_METER_CTGRY_LO_PRIO:
                    meter_type.assign("LO");
                    break;

                default:
                    ret_val = -1;
                    SPDLOG_ERROR("Invalid meter type");
            }

            if (ret_val == 0)
            {
                message << "{";
                message << "\"message_name\":\"meter_data\",";
                message << "\"packet_id\":" << tx_pkt_id << ",";
                message << "\"parameters\":{";

                message << "\"name\":\"" << req_name << "\",";
                message << "\"type\":\"" << meter_type << "\",";
                message << "\"length\":" << meter_data.size() << ",";
                message << "\"value\":[" << meter_data << "]";
                message << "}";
                message << "}\n";
            }
        }
    }

    return ret_val;
}

// Message Format:
//  parameters: {
//     name:<Sub. Name>,
//      type:[HI, MED, LO]
//  }
int process_send_meter_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& ctx)
{
    std::string meter_type;
    enum etelemetryEndpointTypes end_type;
    int ret_val = 0;

    // Get requester name
    if (proc_pkt.get_value("name", req_name))
    {
        SPDLOG_DEBUG("Sub. Name: {}", req_name);

        // Check if requester is a registerd subscriber
        telm_mgr.find_type(req_name, end_type);
        if (end_type != TELM_REQUESTER_SUBSCRIBER_TYPE)
        {
            ret_val = -1;
            SPDLOG_ERROR("Un-registered subscriber {}", req_name);
        }
        else
        {
            // Get meter type requested
            if (proc_pkt.get_value("type", meter_type))
            {
                SPDLOG_DEBUG("Type: {}", meter_type);

                if (meter_type.compare("HI") == 0)
                {
                    ctx.meter_type = TELM_METER_CTGRY_HI_PRIO;
                }
                else if (meter_type.compare("MED") == 0)
                {
                    ctx.meter_type = TELM_METER_CTGRY_MED_PRIO;
                }
                else // "LO"
                {
                    ctx.meter_type = TELM_METER_CTGRY_LO_PRIO;
                }
            }
            else
            {
                ret_val = -1;
            }
        }
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:meter_data,
//      packet_id: pkt_id,
//      parameters:{
//      name:pub_name
//      type:[HI, MED, LO]
//      length:<length>
//      value:meter data string
//   }
//
//   Returns message packet with meter data from all publishers
int process_send_meter_rsp(bosepro::telemetryManager& telm_mgr,
                       std::string& req_name,
                       uint64_t pkt_id, bool ok_nok,
                       std::ostringstream& message,
                       bosepro::HandlerContext& ctx)
{
    std::string meter_type;
    int ret_val = 0;
    uint32_t pub_cnt = telm_mgr.get_publisher_count();

    if (ok_nok)
    {
        switch (ctx.meter_type)
        {
            case TELM_METER_CTGRY_HI_PRIO:
                meter_type.assign("HI");
                break;

            case TELM_METER_CTGRY_MED_PRIO:
                meter_type.assign("MED");
                break;

            case TELM_METER_CTGRY_LO_PRIO:
                meter_type.assign("LO");
                break;

            default:
                SPDLOG_ERROR("Invalid meter type");
        }

        // FOR ALL PUBS
        for (uint32_t idx = 0; idx < pub_cnt; idx++)
        {
            std::string pub_name;

            telm_mgr.get_publisher_name_by_index(idx, pub_name);
            if (pub_name.size() > 0)
            {
                std::string meter_data;

                telm_mgr.get_meter_data(pub_name,
                        ctx.meter_type,
                        meter_data);

                uint64_t tx_pkt_id = get_realtime_ns();

                message << "{";
                message << "\"message_name\":\"meter_data\",";
                message << "\"packet_id\":" << tx_pkt_id << ",";
                message << "\"parameters\":{";

                message << "\"name\":\"" << pub_name << "\",";
                message << "\"type\":\"" << meter_type << "\",";
                message << "\"length\":" << meter_data.size() << ",";
                message << "\"value\":" << meter_data;
                message << "}";
                message << "}\n";
            }
            pub_name.clear();
        }
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//  "parameters": {
//     "name": <Name>,
//     "length": length,
//     "value": val_string
//  }
int process_event(bosepro::telemetryManager& telm_mgr,
                  const bosepro::Telemetry_configuration& proc_pkt,
                  uint64_t& pkt_id, std::string& req_name,
                  bosepro::HandlerContext& /*value_str*/)
{
    //char* value_ptr = static_cast<char *>(value_str);
    int ret_val = 0;

    // Get Sub name
    if (proc_pkt.get_value("name", req_name))
    {
        // Get Sub name
        SPDLOG_DEBUG("Pub. Name: {}", req_name);
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:event,
//      packet_id: pkt_id,
//      parameters:{
//      value:OK_NOK(0/1)
//   }
//
//   Returns message packet with meter data from all publishers
int process_event_rsp(bosepro::telemetryManager& telm_mgr,
                  std::string& req_name,
                  uint64_t pkt_id, bool ok_nok,
                  std::ostringstream& message,
                  bosepro::HandlerContext& /*not_used*/)
{
    message << "{";
    message << "\"message_name\":\"event_rsp\",";
    message << "\"packet_id\":" << pkt_id << ",";
    message << "\"parameters\":{";
    message << "\"value\":\"" << (ok_nok ? "OK" : "NOK") << "\"";
    message << "}";
    message << "}\n";

    return ok_nok ? 0 : -1;
}

// Message Format:
//   message_name:event,
//      packet_id: pkt_id,
//      parameters:{
//      name: <Name>,
//      length: length,
//      value:event data string
//   }
//
//   Returns message packet with meter data from all publishers
void process_event_relay(const bosepro::Telemetry_configuration& proc_pkt,
                         std::ostringstream& message)
{
    std::string event_value = proc_pkt.serialize_message();

    message << event_value;
}

// Message Format:
//  "parameters": {
//     "name": <Name>,
//     "period": [HI, MED, LO]
//  }
int process_update_report_period_req(bosepro::telemetryManager& telm_mgr,
                             const bosepro::Telemetry_configuration& proc_pkt,
                             uint64_t& pkt_id, std::string& req_name,
                             bosepro::HandlerContext& /*unused*/)
{
    std::vector<int_fast32_t> periods;
    int ret_val = 0;

    // Get Req name
    if (proc_pkt.get_value("name", req_name))
    {
        SPDLOG_DEBUG("Pub. Name: {}", req_name);

        if (proc_pkt.get_config_value_vector("period", periods))
        {

            if (telm_mgr.set_meter_report_periods(periods) != 0)
            {
                // Report error
                SPDLOG_ERROR("Invalid period values ");
                ret_val = -1;
            }
            else
            {
                SPDLOG_DEBUG("Periods: [ {}, {}, {}]",periods[0], periods[1], periods[2]);
            }
        }
        else
        {
            ret_val = -1;
        }
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

// Message Format:
//   message_name:update_report_period_rsp,
//      packet_id: pkt_id,
//      parameters:{
//      name:Sub Name
//      period:[HI, MED, LO]
//      value:OK_NOK(0/1)
//   }
int process_update_report_period_rsp(bosepro::telemetryManager& telm_mgr,
                             std::string& req_name,
                             uint64_t pkt_id, bool ok_nok,
                             std::ostringstream& message,
                             bosepro::HandlerContext& /*unused*/)
{
    std::vector<int> periods(3,0);

    telm_mgr.get_meter_report_periods(periods);

    message << "{";
    message << "\"message_name\":\"update_report_period_rsp\",";
    message << "\"packet_id\":" << pkt_id << ",";
    message << "\"parameters\":{";
    message << "\"name\":\"" << req_name << "\",";
    message << "\"period\":[";
    message << periods[0] << ",";
    message << periods[1] << ",";
    message << periods[2] << "],";
    message << "\"value\":\"" << (ok_nok ? "OK" : "NOK") << "\"";
    message << "}";
    message << "}\n";

    return 0;
}
