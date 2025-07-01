#include "webclient.h"

#include <time.h>
#include "curl/curl.h"
#include "spdlog/spdlog.h"

CURL *curl;
using std::ifstream;
using std::stringstream;

struct curl_slist *headers = NULL;

static const int ONE_DAY_IN_SECONDS = 24 * 60 * 60;
static const long CURL_TIMEOUT_IN_SECONDS = 10L;

// curl_cb; callback function for curl commands
size_t curl_cb(void *data, size_t size, size_t nmemb, void *clientp){
    size_t realsize = size * nmemb; 
    ((string*)clientp)->append((char*)data, realsize);
    return realsize;
}

// HTTP codes 200-299 indicate success. (Device Registration returns 201.)
static inline bool isHttpSuccess(long httpCode)
{
    return (httpCode >= 200 && httpCode < 300);
}

WebClient::WebClient()
: caCheckTime(0)
{
    spdlog::debug("Starting Web Client...");

    curl_version_info_data *curl_ver = curl_version_info(CURLVERSION_NOW);
    spdlog::info("libcurl version: {}", curl_ver->version);

    curl_global_init(CURL_GLOBAL_ALL);

    curl = curl_easy_init();

    if(curl) {
        // curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); // Uncomment to get debug output from libCurl.
        
        #if LIBCURL_VERSION_MAJOR > 7 || LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR >= 85
            curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS_STR, "https"); // redirect to https only.
        #elif LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR < 85
            curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS, CURLPROTO_HTTPS); // redirect to https only.
        #endif
        spdlog::debug("Ready");
    }
    else{
        spdlog::critical("Error creating CURL easy handle.");
    }
}

WebClient::~WebClient(){
    curl_easy_cleanup(curl);
    curl_global_cleanup();
}

int WebClient::initRequest(const string &url, const string &accessKey, const string &contentType, const string &contentEncoding, string *getsResponse){
    if(!curl){
        curl = curl_easy_init();
        if(curl) {
            //curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); // Uncomment to get debug output from libCurl.
            curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS_STR, "https"); // redirect to https only.
            CURLcode response = curl_easy_setopt(curl, CURLOPT_CAINFO, "/mnt/cfg/cert/cacert.pem");
            if(response != CURLE_OK){
                spdlog::error("initRequest: Failed to set CA info: {}", curl_easy_strerror(response));
            }
        }
        else{
            spdlog::critical("initRequest: Error creating CURL easy handle.");
        }
    }

    if (headers){
        curl_slist_free_all(headers);
        headers = NULL;
    }
    string authKey = "authorization: " + accessKey;
    headers = curl_slist_append(headers, "accept: application/json");
    headers = curl_slist_append(headers, contentType.c_str());
    headers = curl_slist_append(headers, authKey.c_str());
    headers = curl_slist_append(headers, "Connection: close");
    if (!contentEncoding.empty()){
        headers = curl_slist_append(headers, contentEncoding.c_str());
    }

    if(!headers){
        curl_slist_free_all(headers);
        headers = NULL;
        spdlog::error("curl_slist_append() failed: invalid header?");
        return WEB_CLIENT_ERROR_SEND;
    }

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, getsResponse);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, CURL_TIMEOUT_IN_SECONDS);

    return WEB_CLIENT_OK;
}

int WebClient::SetCertificateChain(const string &path)
{
    int rv = WEB_CLIENT_OK;
    spdlog::debug("SetCertificateChain: path: {}", path);
            
    CURLcode response = curl_easy_setopt(curl, CURLOPT_CAINFO, path.c_str());
    if(response != CURLE_OK){
        spdlog::error("Failed to set CA info: {}", curl_easy_strerror(response));
        rv = WEB_CLIENT_ERROR_SEND;
    }

    return rv;
}

// Internal "check_url" function used by CheckServer and validateCaBundle.
static int check_url(const string &url, CURL *pCurl)
{
    CURLcode response;
    long http_code = 0;

    curl_easy_setopt(pCurl, CURLOPT_HTTPHEADER, nullptr);
    curl_easy_setopt(pCurl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(pCurl, CURLOPT_NOBODY, 1L);
    curl_easy_setopt(pCurl, CURLOPT_FAILONERROR, 1L);

    response = curl_easy_perform(pCurl);

    curl_easy_getinfo (pCurl, CURLINFO_RESPONSE_CODE, &http_code);

    if (isHttpSuccess(http_code)) {
        return WEB_CLIENT_OK;
    }
    else{
        spdlog::error("check_url failed: (HTTP:{}) {}", http_code, curl_easy_strerror(response));
        return WEB_CLIENT_ERROR_SEND;
    }
}

int WebClient::CheckServer(const string &url){
    return check_url(url, curl);
}

int WebClient::curlCleanup(){
    curl_easy_cleanup(curl);
    curl = nullptr;
    return 0;
}

int WebClient::SendRequest(const string &url, const string &accessKey, const string &data, string *getsResponse, const string &method)
{
    CURLcode result;
    int rv = WEB_CLIENT_OK;
    long httpCode = 0;
    string contentType = "content-type: application/json";

    initRequest(url, accessKey, contentType, "", getsResponse);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, nullptr);
    if (method == "POST") {
        curl_easy_setopt(curl, CURLOPT_POST, 1L); // Use POST
    }
    else if (method == "PUT") {
        curl_easy_setopt(curl, CURLOPT_POST, 0L);
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT"); // Use PUT
    }

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)data.size());

    // Don't have the library fail on error, we want to get the reponse body
    // which may contain a message like: {"error": "Device already registered"}
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 0L);

    if (getsResponse) {
        getsResponse->clear(); // Clear before appending in curl_cb
    }

    spdlog::debug("Sending data to Xyte...");

    result = curl_easy_perform(curl);
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

    if (result == CURLE_OK && isHttpSuccess(httpCode)) {
        rv = WEB_CLIENT_OK;
    }
    else {
        spdlog::error("SendRequest failed: (HTTP:{}) {}", httpCode, curl_easy_strerror(result));
        if (getsResponse) {
            spdlog::error("\tSendRequest, server response: {}", *getsResponse);
        }
        rv = WEB_CLIENT_ERROR_SEND;
    }
    return rv;
}

int WebClient::GetRequest(const string &url, const string &accessKey, string *getsResponse)
{
    CURLcode result;
    long httpCode = 0;

    string contentType = "content-type: application/json";
    initRequest(url, accessKey, contentType, "", getsResponse);
    curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);

    // Don't have the library fail on error, we want to get the reponse body
    // which may contain a message like: {"error": "Device already registered"}
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 0L);

    if (getsResponse) {
        getsResponse->clear(); // Clear before appending in curl_cb
    }

    spdlog::debug("Getting data from Xyte...");

    result = curl_easy_perform(curl);
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

    if (result == CURLE_OK && isHttpSuccess(httpCode)) {
        return WEB_CLIENT_OK;
    }
    else {
        spdlog::error("GetRequest failed: (HTTP:{}) {}", httpCode, curl_easy_strerror(result));
        if (getsResponse) {
            spdlog::error("GetRequest, server response: {}", *getsResponse);
        }
        return WEB_CLIENT_ERROR_SEND;
    }
}
