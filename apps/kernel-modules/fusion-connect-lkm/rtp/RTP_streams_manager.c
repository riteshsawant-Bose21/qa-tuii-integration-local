/****************************************************************************
*
*  Module Name    : RTP_streams_manager.c
*  Version        : 
*
*  Abstract       : RAVENNA/AES67 ALSA LKM
*
*  Written by     : van Kempen Bertrand
*  Date           : 25/07/2010
*  Modified by    : Baume Florian
*  Date           : 13/01/2017
*  Modification   : C port (source: RTP_streams_manager.cpp)
*  Known problems : None
*
* Copyright(C) 2017 Merging Technologies
*
* RAVENNA/AES67 ALSA LKM is free software; you can redistribute it and / or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* RAVENNA/AES67 ALSA LKM is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with RAVAENNA ALSA LKM ; if not, see <http://www.gnu.org/licenses/>.
*
****************************************************************************/

#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/netfilter.h>

#include "network_utils.h"

#include "RTP_streams_manager.h"

// // Windows min and max defines clash with std::min and std::max
// #undef min
// #undef max

#define RTCP_ENABLED			1
#define RTCP_COUNTDOWN_INIT		125 //750	// ~ 1s


////////////////////////////////////////////////////////
int init_(struct fusion_aes67_rtp_manager* self, struct rtp_audio_stream_ops* pManager, fusion_aes67_netfilter* pEth_netfilter)
{
    int i;
	printk(KERN_DEBUG "CRTP_streams_manager::Init\n");
	if (!pManager || !pEth_netfilter)
    {
        return 1;
    }

	self->m_ui32RTCPPacketCountdown = RTCP_COUNTDOWN_INIT;

	self->m_pManager = pManager;
	self->m_pEth_netfilter = pEth_netfilter;

	for (i = 0; i < MAX_SOURCE_STREAMS*2; i++)
	{
        Init(&self->m_apRTPSourceStreams[i], pManager, pEth_netfilter);
	}
	memset(self->m_apRTPSourceOrderedStreams, 0, sizeof(self->m_apRTPSourceOrderedStreams));
	self->m_usNumberOfRTPSourceStreams = 0;

	for (i = 0; i < MAX_SINK_STREAMS*2; i++)
	{
        Init(&self->m_apRTPSinkStreams[i], pManager, pEth_netfilter);
	}
	memset(self->m_apRTPSinkOrderedStreams, 0, sizeof(self->m_apRTPSinkOrderedStreams));
	self->m_usNumberOfRTPSinkStreams = 0;

	self->m_csSourceRTPStreams = (void*)kmalloc(sizeof(spinlock_t), GFP_ATOMIC/*GFP_KERNEL*/);
	memset(self->m_csSourceRTPStreams, 0, sizeof(spinlock_t));
	spin_lock_init((spinlock_t*)self->m_csSourceRTPStreams);

	self->m_csSinkRTPStreams = (void*)kmalloc(sizeof(spinlock_t), GFP_ATOMIC/*GFP_KERNEL*/);
	memset(self->m_csSinkRTPStreams, 0, sizeof(spinlock_t));
	spin_lock_init((spinlock_t*)self->m_csSinkRTPStreams);

	return 1;
}


////////////////////////////////////////////////////////
void destroy_(struct fusion_aes67_rtp_manager* self)
{
	printk(KERN_DEBUG "CRTP_streams_manager::Destroy\n");

	// destroy RTPStreams
	remove_all_RTP_streams(self);

	kfree(self->m_csSourceRTPStreams);
	kfree(self->m_csSinkRTPStreams);
}

////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
int add_RTP_stream_(struct fusion_aes67_rtp_manager* self, struct fusion_aes67_rtp_stream_info* pRTPStreamInfo, uint64_t* phRTPStream)
{
    int i;
    struct fusion_aes67_rtp_audio_stream_handler* pUsableRTPStreamHandler = NULL;

	if(!pRTPStreamInfo || !phRTPStream)
	{
		printk(KERN_DEBUG "CRTP_streams_manager::add_RTP_stream: invalid arguments\n");
		return 0;
	}
	if(!check_struct_version(pRTPStreamInfo))
	{
		printk(KERN_DEBUG "CRTP_streams_manager::add_RTP_stream: wrong CRTP_stream_info class version; probably needs host or target recompilation\n");
		return 0;
	}
	if(!is_valid(pRTPStreamInfo))
	{
		return 0;
	}
	if(pRTPStreamInfo->m_bSource)
	{   // SOURCE
        int ret = 0;

		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

        do {
        unsigned short us = 0;
        // find a free stream
        for (i = 0; i < MAX_SOURCE_STREAMS*2; i++)
        {
			if (IsFree(&self->m_apRTPSourceStreams[i]))
			{
				Acquire(&self->m_apRTPSourceStreams[i]);
				pUsableRTPStreamHandler = &self->m_apRTPSourceStreams[i];
				break;
			}
		}
		if (!pUsableRTPStreamHandler)
		{
			printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: No empty slot\n");
			break;
		}
        if(!Create(&pUsableRTPStreamHandler->m_RTPAudioStream, pRTPStreamInfo, self->m_pManager, self->m_pEth_netfilter))
		{
			printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: Failed to init RTPStream\n");
			break;
		}
		printk(KERN_DEBUG "added source at %p", pUsableRTPStreamHandler);

		if(self->m_usNumberOfRTPSourceStreams == MAX_SOURCE_STREAMS)
		{
            printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: error m_apRTPSourceOrderedStreams is full\n");
			break;
		}

        ///$not double checked if the old algo match$ The list is sorted by number of channels (biggest to smallest). This is done to help Horus which doesn't like small stream especially when the number of samples per channel is big > 256

		for(us = 0; us < self->m_usNumberOfRTPSourceStreams; us++)
		{
			if(GetNbOfLivesOut(&pUsableRTPStreamHandler->m_RTPAudioStream) > GetNbOfLivesOut(&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream))
			{ // insert before
                unsigned short us2;
				for(us2 = self->m_usNumberOfRTPSourceStreams; us2 > us; us2--)
				{
					self->m_apRTPSourceOrderedStreams[us2] = self->m_apRTPSourceOrderedStreams[us2 - 1];
				}
				self->m_apRTPSourceOrderedStreams[us] = pUsableRTPStreamHandler;
				self->m_usNumberOfRTPSourceStreams++;
				break;
			}
		}
		if(us == self->m_usNumberOfRTPSourceStreams)
        {
            self->m_apRTPSourceOrderedStreams[self->m_usNumberOfRTPSourceStreams++] = pUsableRTPStreamHandler;
        }

        *phRTPStream = (uint64_t)(size_t)&pUsableRTPStreamHandler->m_RTPAudioStream;

        ret = 1;
        } while (0);

		spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);

        return ret;
	}
	else
	{   // SINK
        int i;
        int ret = 0;

		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

        do {
        // find a free stream
        for (i = 0; i < MAX_SINK_STREAMS*2; i++)
        {
			if (IsFree(&self->m_apRTPSinkStreams[i]))
			{
				Acquire(&self->m_apRTPSinkStreams[i]);
				pUsableRTPStreamHandler = &self->m_apRTPSinkStreams[i];
				break;
			}
		}

        if (!pUsableRTPStreamHandler)
		{
            printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: No empty slot\n");
            break;
		}

        if(!Create(&pUsableRTPStreamHandler->m_RTPAudioStream, pRTPStreamInfo, self->m_pManager, self->m_pEth_netfilter))
        {
            printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: Failed to init RTPStream\n");
            break;
		}
		printk(KERN_DEBUG "added sink at %p", pUsableRTPStreamHandler);

		if(self->m_usNumberOfRTPSinkStreams == MAX_SINK_STREAMS)
		{
            printk(KERN_DEBUG "CRTP_streams_manager::AddRTPStream: error m_apRTPSinkOrderedStreams is full\n");
            break;
		}

        self->m_apRTPSinkOrderedStreams[self->m_usNumberOfRTPSinkStreams++] = pUsableRTPStreamHandler;
        *phRTPStream = (uint64_t)(size_t)&pUsableRTPStreamHandler->m_RTPAudioStream;

        ret = 1;
        } while (0);

        spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

        return ret;
	}
	return 1;
}

////////////////////////////////////////////////////////////////////
int remove_RTP_stream_(struct fusion_aes67_rtp_manager* self, uint64_t hRTPStream)
{
    int ret = 0;
    unsigned short us;
	{   // SOURCE

		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

        do {
        for(us = 0; us < self->m_usNumberOfRTPSourceStreams; us++)
        {
            if(&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)hRTPStream)
            {
                unsigned short i;
                self->m_usNumberOfRTPSourceStreams--;
                // move next elements to remove the hole if any
                for(; us < self->m_usNumberOfRTPSourceStreams; us++)
                {
                    self->m_apRTPSourceOrderedStreams[us] = self->m_apRTPSourceOrderedStreams[us + 1];
                }

                for (i = 0; i < MAX_SOURCE_STREAMS*2; i++)
                {
                    if(&self->m_apRTPSourceStreams[i].m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)hRTPStream)
                    {
                        if (IsActive(&self->m_apRTPSourceStreams[i]))
                        {
                            Release(&self->m_apRTPSourceStreams[i]);
                            ret = 1;
                            break;
                        }
                        printk(KERN_DEBUG "remove_RTP_stream ERROR: CRTP_audio_stream is not active\n");
                        break;
                    }
                }
                if (ret == 0)
                    printk(KERN_DEBUG "remove_RTP_stream ERROR: CRTP_audio_stream not found in the sources collection\n");
                break;
            }
        }
        } while (0);

		spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);

		if (ret)
        	return ret;
	}
	{   // SINK
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

		do {
		for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
		{
			if(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)hRTPStream)
			{
                unsigned short i;
				self->m_usNumberOfRTPSinkStreams--;
				// move next elements to remove the hole if any
				for(; us < self->m_usNumberOfRTPSinkStreams; us++)
				{
					self->m_apRTPSinkOrderedStreams[us] = self->m_apRTPSinkOrderedStreams[us + 1];
				}

				for (i = 0; i < MAX_SINK_STREAMS*2; i++)
				{
					if(&self->m_apRTPSinkStreams[i].m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)hRTPStream)
					{
						if (IsActive(&self->m_apRTPSinkStreams[i]))
						{
							Release(&self->m_apRTPSinkStreams[i]);
							ret = 1;
							break;
						}
						printk(KERN_DEBUG "remove_RTP_stream ERROR: CRTP_audio_stream is not active\n");
						break;
					}
				}
				if (ret == 0)
					printk(KERN_DEBUG "remove_RTP_stream ERROR: CRTP_audio_stream not found in the sinks collection\n");
				break;
			}
		}
		} while (0);

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

		if (ret)
			return ret;
	}
	return 0; // not found
}

////////////////////////////////////////////////////////////////////
void remove_all_RTP_streams(struct fusion_aes67_rtp_manager* self)
{
    unsigned short us;
	{   // SOURCE
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

		for (us = 0; us < self->m_usNumberOfRTPSourceStreams; us++)
		{
			self->m_apRTPSourceOrderedStreams[us] = NULL;
		}
        self->m_usNumberOfRTPSourceStreams = 0;
        for (us = 0; us < MAX_SOURCE_STREAMS*2; us++)
		{
			Release(&self->m_apRTPSourceStreams[us]);
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
	}

	{

		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

		for (us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
		{
            self->m_apRTPSinkOrderedStreams[us] = NULL;
		}
        self->m_usNumberOfRTPSinkStreams = 0;
        for (us = 0; us < MAX_SINK_STREAMS*2; us++)
		{
			Release(&self->m_apRTPSinkStreams[us]);
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
	}
}

////////////////////////////////////////////////////////////////////
int update_RTP_stream_name(struct fusion_aes67_rtp_manager* self, const struct fusion_aes67_rtp_stream_update_name* pRTP_stream_update_name)
{
    unsigned short us;
	//printk(KERN_DEBUG "update_RTP_stream_name: %s\n", pRTP_stream_update_name->m_cName);
	{
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

		for(us = 0; us < self->m_usNumberOfRTPSourceStreams; us++)
		{
            if(&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)pRTP_stream_update_name->m_hRTPStreamHandle)
			{
				set_stream_name(&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream.m_tRTPStream.m_RTP_stream_info, pRTP_stream_update_name->m_cName);
				return 1;
			}
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
	}
	{
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

		for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
		{
            if(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)(size_t)pRTP_stream_update_name->m_hRTPStreamHandle)
			{
				set_stream_name(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream.m_tRTPStream.m_RTP_stream_info, pRTP_stream_update_name->m_cName);
				return 1;
			}
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
	}
	return 0; // not found
}

////////////////////////////////////////////////////////////////////
int get_RTPStream_status_(struct fusion_aes67_rtp_manager* self, uint64_t hRTPStream, struct fusion_aes67_rtp_stream_status* pstream_status)
{
	int ret = 0;
	unsigned short us;
	{
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);
		
		for (us = 0; us < self->m_usNumberOfRTPSourceStreams; us++)
		{
			//warning: cast to pointer from integer of different size [-Wint-to-pointer-cast]
			if (&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)hRTPStream)
			{
				ret = get_RTPStream_status(&self->m_apRTPSourceOrderedStreams[us]->m_RTPAudioStream, pstream_status);
				break;
			}
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);

		if (ret)
		{
			return ret;
		}
	}
	{
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

		for (us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
		{
			//warning: cast to pointer from integer of different size [-Wint-to-pointer-cast]
			if (&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream == (struct fusion_aes67_rtp_audio_stream*)hRTPStream)
			{
				ret = get_RTPStream_status(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream, pstream_status);
				break;
			}
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

		if (ret)
		{
			return ret;
		}
	}
	return 0;
}

uint8_t GetNumberOfSources(struct fusion_aes67_rtp_manager* self)
{
	return (uint8_t)self->m_usNumberOfRTPSourceStreams;
}

uint8_t GetNumberOfSinks(struct fusion_aes67_rtp_manager* self)
{
	return (uint8_t)self->m_usNumberOfRTPSinkStreams;
}


/*
////////////////////////////////////////////////////////////////////
int GetSinkStats(struct fusion_aes67_rtp_manager* self, uint8_t ui8StreamIdx, TRTPStreamStats* pRTPStreamStats)
{
    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        unsigned long flags;
    #endif
	if(!pRTPStreamStats)
	{
		return 0;
	}

	#ifdef UNDER_RTSS
		CMTAL_SingleLockEventTrace Lock(&self->m_csSinkRTPStreams, 1, RTTRACEEVENT_SINK_MUTEX, RT_TRACE_EVENT_COLOR_PURPLE);
    #elif defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);
	#else
		CMTAL_SingleLock Lock(&self->m_csSinkRTPStreams, 1);
	#endif // UNDER_RTSS
    if(ui8StreamIdx < self->m_usNumberOfRTPSinkStreams && self->m_apRTPSinkOrderedStreams[ui8StreamIdx])
	{
        self->m_apRTPSinkOrderedStreams[ui8StreamIdx]->m_RTPAudioStream.GetStats(pRTPStreamStats);
        #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
            spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
        #endif
		return 1;
	}

	memset(pRTPStreamStats, 0, sizeof(TRTPStreamStats));
    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
    #endif
	return 0;
}
*/

////////////////////////////////////////////////////////////////////
int GetSinkStatsFromTIC(struct fusion_aes67_rtp_manager* self, uint8_t ui8StreamIdx, TRTPStreamStatsFromTIC* pRTPStreamStatsFromTIC)
{
	unsigned long flags;

	if(!pRTPStreamStatsFromTIC)
	{
		return 0;
	}

	spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

    if(ui8StreamIdx < self->m_usNumberOfRTPSinkStreams && self->m_apRTPSinkOrderedStreams[ui8StreamIdx])
	{
        GetStatsFromTIC(pRTPStreamStatsFromTIC);

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

		return 1;
	}

	memset(pRTPStreamStatsFromTIC, 0, sizeof(TRTPStreamStatsFromTIC));

	spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

	return 0;
}

////////////////////////////////////////////////////////////////////
int GetMinSinkAheadTime(struct fusion_aes67_rtp_manager* self, TSinkAheadTime* pSinkAheadTime)
{

	unsigned long flags;

	unsigned short us;
	TSinkAheadTime SinkAheadTime;

	if(!pSinkAheadTime)
	{
		return 0;
	}

	memset(pSinkAheadTime, 0, sizeof(TSinkAheadTime));

	spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

	for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
	{
        GetStats_SinkAheadTime(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream, &SinkAheadTime);
		if(us == 0)
		{
			pSinkAheadTime->ui32MinSinkAheadTime = SinkAheadTime.ui32MinSinkAheadTime;
		}
		else
		{
			pSinkAheadTime->ui32MinSinkAheadTime = min(pSinkAheadTime->ui32MinSinkAheadTime, SinkAheadTime.ui32MinSinkAheadTime);
		}
	}

	spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

	return 1;
}

////////////////////////////////////////////////////////////////////
int GetMinMaxSinksJitter(struct fusion_aes67_rtp_manager* self, TSinksJitter* pSinksJitter)
{
	unsigned long flags;
    unsigned short us;
	if(!pSinksJitter)
	{
		return 0;
	}

	memset(pSinksJitter, 0, sizeof(TSinksJitter));

	spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

	for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
	{
        uint32_t ui32SinkJitter = GetStats_SinkJitter(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream);
		if(us == 0)
		{
			pSinksJitter->ui32MinSinkJitter = ui32SinkJitter;
			pSinksJitter->ui32MaxSinkJitter = ui32SinkJitter;
		}
		else
		{
			pSinksJitter->ui32MinSinkJitter = min(pSinksJitter->ui32MinSinkJitter, ui32SinkJitter);
			pSinksJitter->ui32MaxSinkJitter = max(pSinksJitter->ui32MaxSinkJitter, ui32SinkJitter);
		}
	}

	spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
    
	return 1;
}

////////////////////////////////////////////////////////////////////
/*f10bint GetLastProcessedSinkFromTIC(struct fusion_aes67_rtp_manager* self, TLastProcessedRTPDeltaFromTIC* pLastProcessedRTPDeltaFromTIC)
{
    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        unsigned long flags;
    #endif
	memset(pLastProcessedRTPDeltaFromTIC, 0, sizeof(TLastProcessedRTPDeltaFromTIC));
	if(GetNumberOfSinks(self) == 0)
	{
		return 0;
	}

	#ifdef UNDER_RTSS
		CMTAL_SingleLockEventTrace nLock(&self->m_csSinkRTPStreams, 1, RTTRACEEVENT_SINK_MUTEX, RT_TRACE_EVENT_COLOR_RED);
    #elif defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);
	#else
		CMTAL_SingleLock Lock(&self->m_csSinkRTPStreams, 1);
	#endif // UNDER_RTSS

	pLastProcessedRTPDeltaFromTIC->ui32MinLastProcessedRTPDeltaFromTIC = self->m_pmmmLastProcessedRTPDeltaFromTIC.GetMin() / 10; // [us]
	pLastProcessedRTPDeltaFromTIC->ui32MaxLastProcessedRTPDeltaFromTIC = self->m_pmmmLastProcessedRTPDeltaFromTIC.GetMax() / 10; // [us]
	self->m_pmmmLastProcessedRTPDeltaFromTIC.ResetAtNextPoint();

    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
    #endif
	return 1;
}

////////////////////////////////////////////////////////////////////
int GetLastSentSourceFromTIC(struct fusion_aes67_rtp_manager* self, TLastSentRTPDeltaFromTIC* pLastSentRTPDeltaFromTIC)
{
    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        unsigned long flags;
    #endif
	if(!pLastSentRTPDeltaFromTIC)
	{
		return 0;
	}
    memset(pLastSentRTPDeltaFromTIC, 0, sizeof(TLastSentRTPDeltaFromTIC));

    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);
    #else
        CMTAL_SingleLock nLock(&self->m_csSourceRTPStreams, 1);
	#endif
	pLastSentRTPDeltaFromTIC->ui32MinLastSentRTPDeltaFromTIC = self->m_pmmmLastSentRTPDeltaFromTIC.GetMin() / 10; // [us]
	pLastSentRTPDeltaFromTIC->ui32MaxLastSentRTPDeltaFromTIC = self->m_pmmmLastSentRTPDeltaFromTIC.GetMax() / 10; // [us]
	self->m_pmmmLastSentRTPDeltaFromTIC.ResetAtNextPoint();

    #if defined(MTAL_LINUX) && defined(MTAL_KERNEL)
        spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
    #endif
	return 1;
}*/

////////////////////////////////////////////////////////////////////
// CEtherTubeAdviseSink
////////////////////////////////////////////////////////////////////
int process_UDP_packet(struct fusion_aes67_rtp_manager* self, TUDPPacketBase* pUDPPacketBase, uint32_t packet_size)
{
    bool processed = false;
    unsigned long flags;

	if(packet_size < sizeof(TRTPPacketBase))
	{
		//printk(KERN_DEBUG "Wrong RTP packet size %u\n", packet_size);
		return NF_ACCEPT;
	}

	// AES67 6.1 fragmented IP packet must be  ignored
	if((swab16(pUDPPacketBase->IPV4Header.usOffset) & 0x0FFF) != 0 || (swab16(pUDPPacketBase->IPV4Header.usOffset) & 0x2000)) {
		printk(KERN_DEBUG "Fragmented packet 0x%x\n", swab16(pUDPPacketBase->IPV4Header.usOffset));
		return NF_ACCEPT;
	}

	// Is this UDP packet is a RTP packet that we have to use?
    spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);
	{
        unsigned short us;
        uint64_t ui64Key = ((uint64_t)pUDPPacketBase->IPV4Header.ui32DestIP) << 16 | pUDPPacketBase->UDPHeader.usDestPort;
        for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
        {
            if(ui64Key == get_key(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream.m_tRTPStream.m_RTP_stream_info))
            {
                processed |= ProcessRTPAudioPacket(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream, (TRTPPacketBase*)pUDPPacketBase);
            }
        }
    }
    spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);

	return processed ? NF_DROP : NF_ACCEPT;
}

//////////////////////////////////////////////////////////////
void prepare_buffer_lives(struct fusion_aes67_rtp_manager* self)
{
    unsigned short us;
	{   // SOURCE
        unsigned short	usNumberOfRTPSourceStreams;
        struct fusion_aes67_rtp_audio_stream_handler* apRTPSourceStreams[MAX_SOURCE_STREAMS];
		{
            unsigned short i;
			unsigned long flags;
			spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);
			memcpy(apRTPSourceStreams, self->m_apRTPSourceOrderedStreams, sizeof(apRTPSourceStreams));
			usNumberOfRTPSourceStreams = self->m_usNumberOfRTPSourceStreams;
			for (i = 0; i < usNumberOfRTPSourceStreams; i++)
			{
				ReaderEnter(apRTPSourceStreams[i]);
			}

			spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
		}
		for (us = 0; us < usNumberOfRTPSourceStreams; us++)
		{
			if(apRTPSourceStreams[us])
			{
                PrepareBufferLives(&apRTPSourceStreams[us]->m_RTPAudioStream);
			}
		}
		{
            unsigned short i;
			unsigned long flags;
			spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

            for (i = 0; i < usNumberOfRTPSourceStreams; i++)
            {
				ReaderLeave(apRTPSourceStreams[i]);
            }
                
			spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
		}
	}
	{
        unsigned short us;
		unsigned long flags;
		spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

		for(us = 0; us < self->m_usNumberOfRTPSinkStreams; us++)
		{
            PrepareBufferLives(&self->m_apRTPSinkOrderedStreams[us]->m_RTPAudioStream);
		}

		spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
	}
}

///////////////////////////////////////////////////////////////////////////
void frame_process_begin(struct fusion_aes67_rtp_manager* self)
{
	//printk(KERN_DEBUG "send_outgoing_packets(): called from current thread\n");
	send_outgoing_packets(self);
}

///////////////////////////////////////////////////////////////////////////
void send_outgoing_packets(struct fusion_aes67_rtp_manager* self)
{
	// check if the link is up
	if(!fusion_aes67_netfilter_running(self->m_pEth_netfilter))
	{
		return;
	}

    {   // SOURCE
        uint32_t ui32SourceStreamIdx;
        unsigned short usNumberOfRTPSourceStreams;
        struct fusion_aes67_rtp_audio_stream_handler* apRTPSourceStreams[MAX_SOURCE_STREAMS];
        {
            uint32_t i;
			unsigned long flags;
			spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

            memcpy(apRTPSourceStreams, self->m_apRTPSourceOrderedStreams, sizeof(apRTPSourceStreams));
            usNumberOfRTPSourceStreams = self->m_usNumberOfRTPSourceStreams;
            for (i = 0; i < usNumberOfRTPSourceStreams; i++)
            {
				ReaderEnter(apRTPSourceStreams[i]);
            }
			self->m_ui32RTCPPacketCountdown--;

			spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
        }
        for (ui32SourceStreamIdx = 0; ui32SourceStreamIdx < usNumberOfRTPSourceStreams; ui32SourceStreamIdx++)
		{
            if(apRTPSourceStreams[ui32SourceStreamIdx])
			{
                SendRTPAudioPackets(&apRTPSourceStreams[ui32SourceStreamIdx]->m_RTPAudioStream);
                /*if (addr != apRTPSourceStreams[ui32SourceStreamIdx])
				{
                    addr = apRTPSourceStreams[ui32SourceStreamIdx];
                    printk(KERN_DEBUG "NEW ADDR = 0x%x\n", addr);
                }*/

				#ifdef RTCP_ENABLED
					// we spread RTCP_SR packet on several frames
					if(self->m_ui32RTCPPacketCountdown == ui32SourceStreamIdx)
					{ // send RTCP sender report
						// RTCP_SR packets are disabled because GetSystemTime() cannot be used in real-time process and RTCP is not mandatory
			            //F10B apRTPSourceStreams[ui32SourceStreamIdx]->m_RTPAudioStream.SendRTCP_SR_Packet();
					}
				#endif
			}
		}
		{
            uint32_t i;
			unsigned long flags;
			spin_lock_irqsave((spinlock_t*)self->m_csSourceRTPStreams, flags);

			for (i = 0; i < usNumberOfRTPSourceStreams; i++)
			{
				ReaderLeave(apRTPSourceStreams[i]);
			}

			spin_unlock_irqrestore((spinlock_t*)self->m_csSourceRTPStreams, flags);
		}
		//f10bself->m_pmmmLastSentRTPDeltaFromTIC.NewPoint((uint32_t)(MTAL_GetSystemTime() - self->m_pManager->get_global_time(self->m_pManager->user)));

		#ifdef RTCP_ENABLED
			// Send RTCP RR
			{
                uint32_t ui32SinkStreamIdx;
                unsigned long flags;
                spin_lock_irqsave((spinlock_t*)self->m_csSinkRTPStreams, flags);

				for(ui32SinkStreamIdx = 0; ui32SinkStreamIdx < self->m_usNumberOfRTPSinkStreams; ui32SinkStreamIdx++)
				{
					if(self->m_ui32RTCPPacketCountdown == ui32SinkStreamIdx)
					{ // send RTCP receiver report
						//F10B self->m_apRTPSinkOrderedStreams[ui32SinkStreamIdx]->m_RTPAudioStream.SendRTCP_RR_Packet();
					}
				}

                spin_unlock_irqrestore((spinlock_t*)self->m_csSinkRTPStreams, flags);
			}
		#endif

		if(self->m_ui32RTCPPacketCountdown == 0)
		{
			self->m_ui32RTCPPacketCountdown = RTCP_COUNTDOWN_INIT;
		}
	}
}
