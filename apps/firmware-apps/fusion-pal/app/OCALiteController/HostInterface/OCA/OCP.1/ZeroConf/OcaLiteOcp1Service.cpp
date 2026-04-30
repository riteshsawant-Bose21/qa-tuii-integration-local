/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

/*
 *  Description         : OcaLite Ocp1Service implementation.
 *
 */


// ---- Include system wide include files ----
#include <arpa/inet.h>
#include <HostInterfaceLite/OCA/OCP.1/ZeroConf/IOcp1LiteService.h>
#include <HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h>

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)

// Platform-specific DNS-SD includes
#if defined(__APPLE__) || defined(FUSION)
#include <dns_sd.h>
#else
#include <avahi-compat-libdns_sd/dns_sd.h>
#endif

#endif

// ---- FileInfo Macro ----

// ---- Include local include files ----

// ---- Helper types and constants ----

// ---- Helper functions ----

// ---- Local data ----
/** The maximum length of a TXT record. */
#define MAXIMUM_TXT_RECORD_LENGTH 255
// ---- Class Implementation ----



#ifdef __cplusplus
extern "C" {
#endif

#if !defined(STM32H7S7xx) && !defined(STM32N657xx)

static DNSServiceRef m_dnsService = NULL;

/**
 * Registration reply callback. Dummy implementation.
 */
static void DNSSD_API DNSServiceRegisterReply2(DNSServiceRef sdRef, DNSServiceFlags flags, DNSServiceErrorType errorCode, const char *name, const char *regtype, const char *domain, void *context)
{
}
#endif

#if defined(STM32H7S7xx) || defined(STM32N657xx)
bool Ocp1LiteServiceRegister(const std::string &name, const std::string &registrationType,
                             UINT16 port, const std::vector<std::string> &txtRecordList, const std::string &domain)
{
	return true;
}

#else

bool Ocp1LiteServiceRegister(const std::string &name, const std::string &registrationType,
                             UINT16 port, const std::vector<std::string> &txtRecordList, const std::string &domain)
{
    OCA_LOG_TRACE_PARAMS("Register(name = %s, registrationType = %s, port = %u, txtRecordList.size() = %u, domain = %s)",
                         name.c_str(), registrationType.c_str(), port, txtRecordList.size(), domain.c_str());

    DNSServiceErrorType error((NULL != m_dnsService) ? kDNSServiceErr_Invalid : kDNSServiceErr_NoError);

    if (kDNSServiceErr_NoError == error)
    {
        UINT8 txtRecord[MAXIMUM_TXT_RECORD_LENGTH] = {0};
        UINT32 recordLength(0);

        if (!txtRecordList.empty())
        {
            // Calculate the TXT record total length
            std::vector<std::string>::const_iterator txtRecordIter(txtRecordList.begin());
            while (txtRecordList.end() != txtRecordIter)
            {
                recordLength += static_cast<UINT32>(txtRecordIter->length() + 1 /* Length byte */);
                ++txtRecordIter;
            }

            if (recordLength < MAXIMUM_TXT_RECORD_LENGTH)
            {
                UINT16 currentPos(0);
                txtRecordIter = txtRecordList.begin();
                while (txtRecordList.end() != txtRecordIter)
                {
                    // Write the length byte
                    txtRecord[currentPos] = static_cast<UINT8>(txtRecordIter->length());
                    currentPos++;
                    ::memcpy(&txtRecord[currentPos], txtRecordIter->c_str(), txtRecordIter->length());
                    currentPos += static_cast<UINT8>(txtRecordIter->length());
                    ++txtRecordIter;
                }
            }
            else
            {
                OCA_LOG_ERROR("TXT Record is too large");
                error = kDNSServiceErr_BadParam;
            }
        }

        if (kDNSServiceErr_NoError == error)
        {
            error = ::DNSServiceRegister(&m_dnsService, 0, 0, name.c_str(),
                                         registrationType.c_str(), domain.c_str(), NULL, htons(port), static_cast<UINT16>(recordLength),
                                         txtRecord, &DNSServiceRegisterReply2, NULL);
        }
    }
    return (kDNSServiceErr_NoError == error) ? true : false;
}
#endif


void Ocp1LiteServiceDispose(void)
{
#if !defined(STM32H7S7xx) && !defined(STM32N657xx)
    if (NULL != m_dnsService)
    {
        DNSServiceRefDeallocate(m_dnsService);
        m_dnsService = NULL;
    }
#endif
}

#ifdef __cplusplus
}
#endif
