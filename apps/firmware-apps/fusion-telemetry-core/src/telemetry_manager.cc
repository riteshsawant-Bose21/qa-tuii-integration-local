#include "telemetry_core.h"
#include <sys/stat.h>
#include "telemetry_msg_handler.h"

uint64_t get_realtime_ns();

int bosepro::telemetryManager::send_data(const std::string destination_name,
                                         std::ostringstream& message)
{
    enum etelemetryEndpointTypes end_type;
    int ret_val = 0;
    telmVariantSockAddr sock_addr;

    find_type(destination_name, end_type);

    if (end_type == TELM_REQUESTER_SUBSCRIBER_TYPE)
    {
        int sock_type;

        // Get address
        subscribers[destination_name]->get_address(sock_addr, sock_type);
    }
    else if (end_type == TELM_REQUESTER_PUBLISHER_TYPE)
    {
        // Get address
        publishers[destination_name]->get_address(sock_addr);
    }
    else
    {
        // Not Found
        SPDLOG_ERROR("Endpoint '{}' not found!", destination_name);
        ret_val = -1;
    }

    if (ret_val == 0)
    {
        if ( (socket_fd[TELM_CONN_TYPE_UNIX_SOCK] == 0) ||
                (socket_fd[TELM_CONN_TYPE_INTERNET_SOCK] == 0))
        {
            SPDLOG_ERROR("Sockets not initialized!");
        }
        else
        {
            ret_val = std::visit(tx_data(socket_fd, message.str()), sock_addr);

            if (ret_val == -1)
            {
                if (end_type == TELM_REQUESTER_SUBSCRIBER_TYPE)
                {
                    subscribers[destination_name]->increment_fail_comm();
                }
                else if (end_type == TELM_REQUESTER_PUBLISHER_TYPE)
                {
                    publishers[destination_name]->increment_fail_comm();
                }

                // TX Fail
                SPDLOG_ERROR("Send message fail!");
            }
            else
            {
                if (end_type == TELM_REQUESTER_SUBSCRIBER_TYPE)
                {
                    subscribers[destination_name]->reset_fail_comm();
                }
                else if (end_type == TELM_REQUESTER_PUBLISHER_TYPE)
                {
                    publishers[destination_name]->reset_fail_comm();
                }
            }
        }
    }

    return ret_val;
}

uint64_t meter_tstamp_ns;
int bosepro::telemetryManager::process_rx_packet(std::string& packet)
{
    std::string msg_name;
    std::string req_name;
    uint64_t pkt_id;
    int ret_val = 0;
    char argmt_val[REQ_RESP_ARG_SIZE];  // Used to pass args between req
                                        // and resp handlers

    std::stringstream pkt_strm(packet);
    bosepro::Telemetry_configuration packet_navi(pkt_strm);

    if ( packet_navi.get_value("message_name", msg_name) &&
         packet_navi.get_value("packet_id", pkt_id) )
    {
        SPDLOG_DEBUG(" Processing Message: {}, Id: {}",msg_name, pkt_id);

        // Call message handler
        if (message_handler.find(msg_name) != message_handler.end())
        {
            ret_val = message_handler[msg_name].first(*this,
                    packet_navi.get_parameters(),
                    pkt_id, req_name, static_cast<void *>(argmt_val));

            // Call response handler if registered
            if (message_handler[msg_name].second != NULL)
            {
                std::ostringstream message;

                ret_val =
                  message_handler[msg_name].second(*this, req_name,
                                                   pkt_id, (ret_val == 0),
                                                   message,
                                                   static_cast<void *>(argmt_val));

                if (ret_val == 0)
                {
                    // This is a meters_data message
                    if (msg_name.compare("update_meters_rsp") == 0)
                    {
                        uint64_t temp_tstamp_ns = get_realtime_ns();

                        meter_tstamp_ns = temp_tstamp_ns;

                        // The 'message' string was built in
                        // process_meter_data()
                        ret_val = send_meter_data(message);

                    }
                    else
                    {
                        ret_val = send_data(req_name, message);

                        // If Event, relay to all subs.
                        if (msg_name.compare("event") == 0)
                        {
                            std::ostringstream evt_message;

                            process_event_relay(packet_navi, evt_message);
                            ret_val |= send_meter_data(evt_message);
                        }

                        // If message was de-register,
                        // the deleteion is performed here.
                        post_deregister_cleanup();
                    }

                    if (ret_val < 0)
                    {
                        // TX failed
                        SPDLOG_ERROR("Send Fail = {}", ret_val);
                    }
                }

            }
        }
        else
        {
            SPDLOG_ERROR("{} message has no registered handler",msg_name);
        }
    }
    else
    {
        ret_val = -1;
    }

    return ret_val;
}

void bosepro::telemetryManager::send_update_request()
{
    bool lo_meter;
    bool med_meter;
    bool hi_meter;

    // Advance frame counter
    meter_update_frame_count++;

    lo_meter  = ((meter_update_frame_count % lo_update_period_frames) == 0);
    med_meter = ((meter_update_frame_count % med_update_period_frames) == 0);
    hi_meter  = ((meter_update_frame_count % hi_update_period_frames) == 0);

    // Flush tracker of all unresponded reequests (timeout)
    if (lo_meter)
    {
        meter_update_tracker.clear();
    }

    for (auto& pubs : publishers)
    {
        //Send request
        if ( (lo_meter) &&
             (pubs.second->get_shared_mem_size(TELM_METER_CTGRY_LO_PRIO) > 0))
        {
            std::ostringstream update_req;
            uint64_t pkt_id;

            process_update_meters_req("LO", pkt_id, update_req, NULL);

            if (bosepro::telemetryManager::send_data(pubs.first, update_req) > 0)
            {
                meter_update_req_add(pkt_id, pubs.first,
                                     TELM_METER_CTGRY_LO_PRIO);
            }
            else
            {
                continue;
            }

            //Reset frame count
            meter_update_frame_count = 0;
        }

        if ( (med_meter) &&
             (pubs.second->get_shared_mem_size(TELM_METER_CTGRY_MED_PRIO) > 0))
        {
            std::ostringstream update_req;
            uint64_t pkt_id;

            process_update_meters_req("MED", pkt_id, update_req, NULL);

            if (bosepro::telemetryManager::send_data(pubs.first, update_req) > 0)
            {
                meter_update_req_add(pkt_id, pubs.first,
                                     TELM_METER_CTGRY_MED_PRIO);
            }
            else
            {
                continue;
            }
        }

        if ( (hi_meter) &&
             (pubs.second->get_shared_mem_size(TELM_METER_CTGRY_HI_PRIO) > 0))
        {
            std::ostringstream update_req;
            uint64_t pkt_id;

            process_update_meters_req("HI", pkt_id, update_req, NULL);

            if (bosepro::telemetryManager::send_data(pubs.first, update_req) > 0)
            {
                meter_update_req_add(pkt_id, pubs.first,
                                     TELM_METER_CTGRY_HI_PRIO);
            }
            else
            {
                continue;
            }
        }

    }
}

int bosepro::telemetryManager::send_meter_data(std::ostringstream& meter_data)
{
    int ret_val = 0;

    for (auto& subs : subscribers)
    {
        ret_val |= send_data(subs.first, meter_data);
    }

    return ret_val;
}

int bosepro::telemetryManager::validate_update_meter_rsp(
                                    uint64_t& pkt_id, std::string& req_name,
                                    std::string ok_nok,
                                    enum eMeterCategory& meter_type)
{
    int ret_val = 0;
    std::string pub_name;

    if (ok_nok.compare("OK") == 0)
    {
        meter_update_req_find(pkt_id, pub_name, meter_type);

        if ( (meter_type != TELM_METER_CTGRY_MAX) &&
                (req_name.compare(pub_name) == 0) )
        {
            meter_update_req_remove(pkt_id);
        }
        else
        {
            SPDLOG_ERROR("update_meters_req/rsp packet mismatch ({}/{})",
                         req_name, pub_name);
            ret_val = -1;
        }
    }
    else
    {
        meter_update_req_remove(pkt_id);
        SPDLOG_ERROR("update_meters_req returned NOK");
        ret_val = -1;
    }

    return ret_val;
}

bool bosepro::telemetryManager::time_to_report_meter(
                                            std::string& pub_name,
                                            enum eMeterCategory& meter_type)
{
    bool ret_val = false;

    std::map<std::string,
             std::unique_ptr<telemetryPublisher>>::iterator pub_it;

    uint32_t tick_cnt;

    pub_it =  publishers.find(pub_name);
    if (pub_it != publishers.end())
    {
        tick_cnt = pub_it->second->advance_report_tick(meter_type);
        if (tick_cnt == report_period_factor[meter_type])
        {
            pub_it->second->reset_report_tick(meter_type);
            ret_val = true;
        }
    }

    return ret_val;
}

void bosepro::telemetryManager::cleanup_dead_endpoints()
{
    for (auto pubs = publishers.begin(); pubs != publishers.end();)
    {
        if (pubs->second->get_comm_fail_cnt() >= MAX_COMM_FAIL_COUNT)
        {
            SPDLOG_INFO("Timeout! De-registering Publisher: {}", pubs->first);
            deregister_publisher(pubs->first);
            pubs = publishers.erase(pubs);
        }
        else
        {
            ++pubs;
        }
    }

    for (auto subs = subscribers.begin(); subs != subscribers.end();)
    {
        if (subs->second->get_comm_fail_cnt() >= MAX_COMM_FAIL_COUNT)
        {
            SPDLOG_INFO("Timeout! De-registering Subscriber: {}", subs->first);
            deregister_subscriber(subs->first);
            subs = subscribers.erase(subs);
        }
        else
        {
            ++subs;
        }
    }

    deregister_endpoint_name.clear();
}
