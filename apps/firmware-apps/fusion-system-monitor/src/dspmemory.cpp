
#include <bosepro/dspmemory.h>

namespace bosepro {

RegionManager *DspMemoryImpl::mgr = nullptr;


void RegionManager::open_region()
{
    DspMemoryImpl::set_region_manager(this);
}


void RegionManager::close_region()
{
    DspMemoryImpl::set_region_manager(nullptr);
}

}
