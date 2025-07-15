#pragma once
#include <iostream>
#include <string>
#include <time.h>
#include <curl/curl.h>
#include <spdlog/spdlog.h>
#include <sstream>
#include <fstream>

using std::string;

#define WEB_CLIENT_OK 0
#define WEB_CLIENT_ERROR_SEND -1
#define WEB_CLIENT_ERROR_GET  -2

// WebClient is currently designed for single-threaded access. Do not make concurrent calls.
class WebClient{
  public:
    // The constructor of a WebClient implementation should take care of any library initialization.
    WebClient();

    // The destructor of a WebClient implementation should handle any library shutdown.
    virtual ~WebClient();

    /** CheckServer; check if server is reachable
     * Parameters:
     * - url - server url to check reachability
     * return int ErrorCode WEB_CLIENT_OK or WEB_CLIENT_ERROR_*
     */
    int CheckServer(const string &url);

    /** SetCertificateChain; set the CA certificate chain to use for HTTPS requests
     * Parameters:
     * - path - Path to the CA certificate bundle
     * return int ErrorCode WEB_CLIENT_OK or WEB_CLIENT_ERROR_*
     */
    int SetCertificateChain(const string &path);

    int curlCleanup();

    /**	SendRequest; send data to xyte and get response
      * Parameters:
      * - data - formatted JSON to send in a telemetry request to the server.
      * - url  - The URL to send the telemetry data to.
      * - getsResponse - String that gets the of response data from the server.
      * - method - POST/PUT method
      * return int ErrorCode WEB_CLIENT_OK or WEB_CLIENT_ERROR_*
      */
    int SendRequest(const string &url, const string &authKey, const string &data, string *getsResponse, const string &method);

    /**	GetRequest; get data from xyte
      * Parameters:
      * - url  - The URL to get the data.
      * - getsResponse - String that gets the of response data from the server.
      * return int ErrorCode WEB_CLIENT_OK or WEB_CLIENT_ERROR_*
      */
    int GetRequest(const string &url, const string &accessKey, string *getsResponse);

    int SendFile(const string &url, const string &accessKey, const string &filePath, string *getsResponse);

  private:
    /** 
     * initRequest; create header if needed while sending data to xyte
     * - url  - The URL to post/get the data.
     * - authKey - Authorization key
     * - contentType - Type of content to be sent
     * - contentEncoding - [optional] Type encoding to be sent.
     * - getsResponse - String that gets the of response data from the server.
     * return int ErrorCode WEB_CLIENT_OK or WEB_CLIENT_ERROR_*
    **/
    int initRequest(const string &url, const string &authKey, const string &contentType, const string &contentEncoding, string *getsResponse);

    bool performRequest(long &httpCode, std::string *response, const std::string &method);

    time_t caCheckTime;
    // CURL internal state
    void *curl;
    struct curl_slist *headers;
};
