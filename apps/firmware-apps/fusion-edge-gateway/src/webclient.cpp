#include "webclient.h"

using std::string;
using std::ifstream;
using std::stringstream;

static const long CURL_TIMEOUT_IN_SECONDS = 10L;

// curl_cb: Callback function for curl
static size_t curl_cb(void *data, size_t size, size_t nmemb, void *clientp)
{
    size_t realsize = size * nmemb;
    if (clientp) {
        static_cast<string*>(clientp)->append(static_cast<char*>(data), realsize);
    }
    return realsize;
}

// HTTP codes 200-299 indicate success.
static inline bool isHttpSuccess(long httpCode)
{
    return (httpCode >= 200 && httpCode < 300);
}

WebClient::WebClient() : caCheckTime(0), curl(nullptr), headers(nullptr)
{
    SPDLOG_DEBUG("Starting Web Client...");

    curl_version_info_data *curl_ver = curl_version_info(CURLVERSION_NOW);
    SPDLOG_INFO("libcurl version: {}", curl_ver->version);

    curl_global_init(CURL_GLOBAL_ALL);

    curl = curl_easy_init();

    if(curl) {
        // curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); // Uncomment to get debug output from libCurl.
        
        #if LIBCURL_VERSION_MAJOR > 7 || LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR >= 85
            curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS_STR, "https"); // redirect to https only.
        #elif LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR < 85
            curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS, CURLPROTO_HTTPS); // redirect to https only.
        #endif
        SPDLOG_DEBUG("Ready");
    }
    else{
        SPDLOG_CRITICAL("Error creating CURL easy handle.");
    }
}

WebClient::~WebClient(){
    if (headers) {
        curl_slist_free_all(headers);
        headers = nullptr;
    }
    if (curl) {
        curl_easy_cleanup(curl);
        curl = nullptr;
    }
    curl_global_cleanup();
}

int WebClient::initRequest(const string &url, const string &accessKey, const string &contentType, const string &contentEncoding, string *getsResponse){
    if(!curl){
        curl = curl_easy_init();
        if(curl) {
            //curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); // Uncomment to get debug output from libCurl.
            #if LIBCURL_VERSION_MAJOR > 7 || LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR >= 85
                curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS_STR, "https"); // redirect to https only.
            #elif LIBCURL_VERSION_MAJOR == 7 && LIBCURL_VERSION_MINOR < 85
                curl_easy_setopt(curl, CURLOPT_REDIR_PROTOCOLS, CURLPROTO_HTTPS); // redirect to https only.
            #endif
        }
        else{
            SPDLOG_CRITICAL("initRequest: Error creating CURL easy handle.");
        }
    }

    if (headers){
        curl_slist_free_all(headers);
        headers = nullptr;
    }

    if(!accessKey.empty()){
        string authKey = "authorization: " + accessKey;
        headers = curl_slist_append(headers, authKey.c_str());
    }
    headers = curl_slist_append(headers, contentType.c_str());
    headers = curl_slist_append(headers, "Connection: close");

    if (!contentEncoding.empty()){
        headers = curl_slist_append(headers, contentEncoding.c_str());
    }

    if(!headers){
        curl_slist_free_all(headers);
        headers = nullptr;
        SPDLOG_ERROR("curl_slist_append() failed: invalid header?");
        return WEB_CLIENT_ERROR_SEND;
    }

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    CURLcode code = curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    if (code != CURLE_OK) {
        SPDLOG_ERROR("Failed to set CURLOPT_URL: {}", curl_easy_strerror(code));
        return WEB_CLIENT_ERROR_SEND;
    }
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, getsResponse);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, CURL_TIMEOUT_IN_SECONDS);

    return WEB_CLIENT_OK;
}

int WebClient::SetCertificateChain(const string &path)
{
    int rv = WEB_CLIENT_OK;
    SPDLOG_DEBUG("SetCertificateChain: path: {}", path);

    CURLcode response = curl_easy_setopt(curl, CURLOPT_CAINFO, path.c_str());
    if(response != CURLE_OK){
        SPDLOG_ERROR("Failed to set CA info: {}", curl_easy_strerror(response));
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
        SPDLOG_ERROR("check_url failed: (HTTP:{}) {}", http_code, curl_easy_strerror(response));
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

bool WebClient::performRequest(long &httpCode, std::string *response, const std::string &method)
{
    if (response) response->clear();
    CURLcode result = curl_easy_perform(curl);
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

    if (result == CURLE_OK && isHttpSuccess(httpCode)) {
        SPDLOG_DEBUG("{} request successful: (HTTP:{})", method.c_str(), httpCode);
        return true;
    }
    else {
        SPDLOG_ERROR("{} request failed: (HTTP:{}) {}", method.c_str(), httpCode, curl_easy_strerror(result));
        if (response && !response->empty()) {
            SPDLOG_ERROR("\tServer response: {}", *response);
        }
        return false;
    }
}

int WebClient::SendRequest(const string &url, const string &accessKey, const string &data, string *getsResponse, const string &method)
{
    long httpCode = 0;
    string contentType = "content-type: application/json";

    if (initRequest(url, accessKey, contentType, "", getsResponse) != WEB_CLIENT_OK) {
        return WEB_CLIENT_ERROR_SEND;
    }

    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, nullptr); // Reset any previous custom request

    if (method == "POST") {
        curl_easy_setopt(curl, CURLOPT_POST, 1L); // Use POST
    }
    else if (method == "PUT") {
        curl_easy_setopt(curl, CURLOPT_POST, 0L);
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT"); // Use PUT
    }
    else {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, method.c_str()); // Use custom method
    }

    CURLcode code = curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
    if (code != CURLE_OK) {
        SPDLOG_ERROR("Failed to set CURLOPT_POSTFIELDS: {}", curl_easy_strerror(code));
        return WEB_CLIENT_ERROR_SEND;
    }
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)data.size());

    // Don't have the library fail on error, we want to get the reponse body
    // which may contain a message like: {"error": "Device already registered"}
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 0L);

    if (getsResponse) {
        getsResponse->clear(); // Clear before appending in curl_cb
    }

    SPDLOG_INFO("Sending data to Server...");

    if (!performRequest(httpCode, getsResponse, method)) {
        return WEB_CLIENT_ERROR_SEND;
    }
    SPDLOG_DEBUG("Received data: {}", *getsResponse);
    return WEB_CLIENT_OK;
}

int WebClient::GetRequest(const string &url, const string &accessKey, string *getsResponse)
{
    long httpCode = 0;
    string contentType = "content-type: application/json";

    if (initRequest(url, accessKey, contentType, "", getsResponse) != WEB_CLIENT_OK) {
        return WEB_CLIENT_ERROR_SEND;
    }
    curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);

    // Don't have the library fail on error, we want to get the reponse body
    // which may contain a message like: {"error": "Device already registered"}
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, 0L);

    if (getsResponse) {
        getsResponse->clear(); // Clear before appending in curl_cb
    }

    SPDLOG_DEBUG("Getting data from Server...");

    if (!performRequest(httpCode, getsResponse, "GET")) {
        return WEB_CLIENT_ERROR_SEND;
    }
    SPDLOG_DEBUG("Received data: {}", *getsResponse);
    return WEB_CLIENT_OK;
}
