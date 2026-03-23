
#include <bosepro/dspmemory.h>

namespace bosepro {

RegionManager *DspMemoryImpl::mgr = nullptr;


RegionManager::RegionManager() : region()
{
}


RegionManager::~RegionManager()
{
    close_region();
}


void *RegionManager::allocate(size_t size, size_t align, RegionType rtype)
{
    return region[rtype].allocate(size, align);
}


void RegionManager::mark_for_destruction(void *p, size_t count,
                                         RegionType rtype)
{
    region[rtype].mark_for_destruction(p, count);
}


size_t RegionManager::get_destruction_count(void *p, RegionType rtype)
{
    return region[rtype].get_destruction_count(p);
}


void RegionManager::open_region()
{
    DspMemoryImpl::set_region_manager(this);
}


void RegionManager::close_region()
{
    DspMemoryImpl::set_region_manager(nullptr);
}


RegionManager::Region::~Region()
{
    for (auto &p : large_chunks)
    {
        std::free(p);
    }
}


void *RegionManager::Region::allocate(size_t size, size_t align)
{
    void *p;

    if (size < LARGE_CHUNK_SIZE)
    {
        // Allocate small requests from within the region.
        p = mbr.allocate(size, align);
    }
    else
    {
        // Allocate large requests from the heap, and store the pointer
        // in the list of large chunks to be freed when the region is
        // destroyed.
        p = std::aligned_alloc(align, size);
        large_chunks.push_front(p);
    }

    return p;
}


void RegionManager::Region::mark_for_destruction(void *p, size_t count)
{
    if (to_destroy.count(p) != 0)
    {
        SPDLOG_CRITICAL("Can't mark pointer {} for destruction again", p);
        return;
    }

    to_destroy[p] = count;
}


size_t RegionManager::Region::get_destruction_count(void *p)
{
    if (p == nullptr)
    {
        return 0;
    }

    if (to_destroy.count(p) == 0)
    {
        SPDLOG_CRITICAL("Pointer not found for destruction! {}", p);
        return 0;
    }

    size_t count = to_destroy[p];
    to_destroy.erase(p);
    return count;
}


void DspMemoryImpl::set_region_manager(RegionManager *region_manager)
{
    mgr = region_manager;
}


void *DspMemoryImpl::allocate(size_t size, size_t align,
                              RegionManager::RegionType rt)
{
    if (mgr == nullptr)
    {
        SPDLOG_CRITICAL("Region manager does not exist!");
        return nullptr;
    }

    return mgr->allocate(size, align, rt);
}


void DspMemoryImpl::mark_for_destruction(void *p, size_t count,
                                         RegionManager::RegionType rt)
{
    if (mgr == nullptr)
    {
        SPDLOG_CRITICAL("Region manager does not exist!");
    }

    mgr->mark_for_destruction(p, count, rt);
}


size_t DspMemoryImpl::get_destruction_count(void *p,
                                            RegionManager::RegionType rt)
{
    if (mgr == nullptr)
    {
        SPDLOG_CRITICAL("Region manager does not exist!");
        return 0;
    }

    return mgr->get_destruction_count(p, rt);
}


}
