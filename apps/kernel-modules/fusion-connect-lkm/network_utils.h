/*
 * Copyright (C) 2017 Merging Technologies
 * Copyright (C) 2025 Bose Professional
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#pragma pack(push, 1)

#define MTAL_SWAP16(x) ((((x) >> 8) & 0x00ff) | (((x) << 8) & 0xff00))
#define MTAL_SWAP32(x) ((((x) >> 24) & 0x000000ff) | (((x) >> 8 ) & 0x0000ff00) | (((x) << 8 ) & 0x00ff0000) | (((x) << 24) & 0xff000000))
#define MTAL_SWAP64(x)  (MTAL_SWAP32(x & 0xFFFFFFFF) << 32 | MTAL_SWAP32(x >> 32))

#define ETHERNET_STANDARD_FRAME_SIZE	(1500 + 14) // 1500 bytes  PAYLOAD + 14 bytes ethernet header, as defined in http://en.wikipedia.org/wiki/Ethernet_frame

// Ethernet protocol types
#define MTAL_ETH_PROTO_IPV4				0x0800    ///< The Ethernet type used by IPV4
#define MTAL_ETH_PROTO_ARP				0x0806    ///< The Ethernet type ued by ARP
#define MTAL_ETH_MAC_CONTROL			0x8808

// IP protocol type
#define MTAL_IP_PROTO_ICMP				1
#define MTAL_IP_PROTO_IGMP				2
#define MTAL_IP_PROTO_UDP				17

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/// Headers
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
typedef struct
{
	uint8_t		byDest[6];   ///< The destination MAC address
	uint8_t		bySrc[6];    ///< The source MAC address
	uint16_t	usType;      ///< The Ethernet type (0x5000, big-endian, for EtherTube)
} TEthernetHeader;

typedef struct
{
	uint8_t		byDest[6];   ///< The destination MAC address
	uint8_t		bySrc[6];    ///< The source MAC address
	uint16_t	usTPID;		// Tag protocol identifier
	uint16_t	usVID;		// VLAN ID
	uint16_t	usType;      ///< The Ethernet type (0x5000, big-endian, for EtherTube)
} TEthernetHeader8021Q;

typedef struct
{											// Offset  Length (bytes)
	uint8_t		ucVersion_HeaderLen;	// 14		1
	uint8_t		ucTOS;					// 15       1
	uint16_t	usLen;					// 16       2
	uint16_t	usId;					// 18       2
	uint16_t	usOffset;				// 20       2
	uint8_t		byTTL;					// 22       1
	uint8_t		byProtocol;				// 23       1

	uint16_t	usChecksum;				// 24       2

	// port addresses in network byte order
	uint32_t	ui32SrcIP;				// 26*       4
	uint32_t	ui32DestIP;				// 30*       4
} TIPV4Header;

typedef struct
{											// Offset  Length (bytes)
  uint16_t	usSrcPort;				// 34		4
  uint16_t	usDestPort;				// 38       4				// src/dest UDP ports
  uint16_t	usLen;					// 42       4
  uint16_t	usCheckSum;				// 46       4
} TUDPHeader;

typedef struct
{											// Offset  Length (bytes)
	uint8_t		byVersion;				// 50		1
	uint8_t		byPayloadType;			// 51       1
	uint16_t	usSeqNum;				// 52       2
	uint32_t	ui32Timestamp;			// 54       4
	uint32_t	ui32SSRC;					// 58       4
} TRTPHeader;


#define RTCP_PACKET_TYPE_SR		200
#define RTCP_PACKET_TYPE_RR		201
#define RTCP_PACKET_TYPE_SDES	202
#define RTCP_PACKET_TYPE_BYE	203
#define RTCP_PACKET_TYPE_APP	204

#define RTCP_PACKET_TYPE_SDES_END	0
#define RTCP_PACKET_TYPE_SDES_CNAME	1
#define RTCP_PACKET_TYPE_SDES_NAME	2
#define RTCP_PACKET_TYPE_SDES_EMAIL	3
#define RTCP_PACKET_TYPE_SDES_PHONE	4
#define RTCP_PACKET_TYPE_SDES_LOC	5
#define RTCP_PACKET_TYPE_SDES_TOOL	6
#define RTCP_PACKET_TYPE_SDES_NOTE	7
#define RTCP_PACKET_TYPE_SDES_PRIV	8


typedef struct
{
	uint8_t		byVersion;		// Version + padding + RC (Reception report count)
	uint8_t		byPacketType;
	uint16_t	usLength;
	uint32_t	ui32SSRC;			// Sender SSRC
} TRTCPHeader;

typedef struct
{
	uint8_t		byVersion;		// Version + padding + SC (source count)
	uint8_t		byPacketType;
	uint16_t	usLength;
} TRTCP_SourceDescriptionHeaderBase; //SDES

typedef struct
{
	uint8_t	byType;
	uint8_t	ucLength;
	uint8_t	ucData[1];
} TRTCP_SourceDescriptionItem; //SDES

typedef struct
{
	uint32_t				dwSSRC;
} TRTCP_SourceDescriptionChunk; //SDES

typedef struct
{
	uint32_t	ui32NTPTimestamp_MSW;
	uint32_t	ui32NTPTimestamp_LSW;
	uint32_t	ui32RTPTimestamp;
	uint32_t	ui32SenderPacketCount;
	uint32_t	ui32SenderOctetCount;
} TRTCP_SenderInfo;

typedef struct
{
	uint32_t	ui32SSRC;							// Source SSRC
	uint8_t		byFractionLost;
	uint8_t		byAccumNbOfPacketsLost[3];		// 24bits
	// Extended highest sequence number received
	uint32_t	ui32SequenceNumberCyclesCount;
	uint32_t	ui32HighestSequenceNumberReceived;
	uint32_t	ui32InterarrivalJitter;
	uint32_t	ui32LastSRTimestamp;
	uint32_t	ui32DelaySinceLastSRTimestamp;
} TRTCP_ReportBlock;

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/// Packets
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;	///< The Ethernet header
	uint16_t			usOpcode;
	uint16_t			usQuanta;
} TMACControlFrame;

/////////////////////////////////////////////////////////////////
// IPV4PacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;	///< The Ethernet header
	TIPV4Header			IPV4Header;
}  TIPV4PacketBase;

/////////////////////////////////////////////////////////////////
// UDPPacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;	///< The Ethernet header
	TIPV4Header			IPV4Header;
	TUDPHeader			UDPHeader;
} TUDPPacketBase;

/////////////////////////////////////////////////////////////////
// RTSPPacket
/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;
	TIPV4Header			IPV4Header;
	TUDPHeader			UDPHeader;
	char				cString[256];
} TRTSPPacket;

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// RTP
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

#define IP_PROTO_IGMP		2
#define IP_PROTO_UDP		17
#define RTP_PAYLOAD_TYPE	127	// Dynamic payload [96..127]

//#define RTP_PAYLOAD_L16ST_TYPE	10	// PCM L16 stereo 44100
//#define RTP_PAYLOAD_L16M_TYPE		11	// PCM L16 mono 44100

#define RTP_SET_VERSION(byte, ver) byte = (byte & (~0xc0)) | ((ver & 3) <<6)
#define RTP_GET_VERSION(byte) ((byte >> 6) & 3)
#define RTP_IS_PADDING(byte) (byte & 0x20)
#define RTP_IS_EXTENSION(byte) (byte & 0x10)
#define RTP_GET_CC(byte) (byte & 0xF)

/////////////////////////////////////////////////////////////////
// RTPPacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;	///< The Ethernet header
	TIPV4Header			IPV4Header;
	TUDPHeader			UDPHeader;
	TRTPHeader			RTPHeader;
} TRTPPacketBase;

// Special case for EtherTubeRTP packet
// We are using RTPHeader.ssrc to retrieve the UnitDeviceID
#define RTP_MAX_PAYLOAD_SIZE (ETHERNET_STANDARD_FRAME_SIZE - sizeof(TRTPPacketBase)) // 1460 bytes

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// RTCP
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////
// RTPCPacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TEthernetHeader		EthernetHeader;	///< The Ethernet header
	TIPV4Header			IPV4Header;
	TUDPHeader			UDPHeader;
	TRTCPHeader			RTCPHeader;
} TRTCPPacketBase;

/////////////////////////////////////////////////////////////////
// RTPC_SR_PacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TRTCPPacketBase					RTCPPacketBase;
	TRTCP_SenderInfo				RTCP_SenderInfo;
} TRTCP_SR_PacketBase;

/////////////////////////////////////////////////////////////////
// RTPC_RR_PacketBase
/////////////////////////////////////////////////////////////////
typedef struct
{
	TRTCPPacketBase		RTCPPacketBase;
	TRTCP_ReportBlock	RTCP_ReportBlock;
} TRTCP_RR_PacketBase;

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// Helpers
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
void dump_mac_addr(uint8_t const Addr[6]);
void dump_ip_addr(uint32_t ui32IP, char bCarriageReturn);
void dump_id(uint64_t ullID);
void dump_eth_header(TEthernetHeader* pEthernetHeader);
void dump_mac_ctrl_frame(TMACControlFrame* pMACControlFrame);
void dump_ipv4_header(TIPV4Header* pIPV4Header);
void dump_udp_header(TUDPHeader* pUDPHeader);

// int instead of bool because this is used by C file
int is_mac_equal(uint8_t Addr1[6], uint8_t Addr2[6]);
int is_ip_mcast(unsigned int uiIP);
int get_mac_from_remote_ip(unsigned int uiIP, uint8_t ui8MAC[6]);

uint16_t compute_cksum(void *dataptr, uint16_t len);
uint16_t compute_udp_cksum(void *dataptr, uint16_t len, uint16_t SrcIP[],uint16_t DestIP[]);

#pragma pack(pop)
