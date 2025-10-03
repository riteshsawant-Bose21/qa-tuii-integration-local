
#include <bosepro/dspmemory.h>

#include <doctest/doctest.h>
//#include <spdlog/spdlog.h>


TEST_SUITE_BEGIN("DSP Memory");


TEST_CASE("Operators")
{
    bosepro::RegionManager region_manager;
    region_manager.open_region();

    bosepro::DspStateMemory<float[]> s;
    CHECK(s.get() == nullptr);
    s.resize(32);
    CHECK(s.get() != nullptr);
    CHECK(s.get() == *((float **)&s));
    CHECK(s.get() == &s[0]);

    bosepro::DspStateMemory<float[]> sc(32);
    CHECK(sc.get() != nullptr);
    CHECK(sc.get() == *((float **)&sc));
    CHECK(sc.get() == &sc[0]);
}


TEST_CASE("Alignment")
{
    bosepro::RegionManager region_manager;
    region_manager.open_region();

    // Make sure allocations with large alignments are successful, and that
    // the resulting pointers are aligned on the specified boundary.
    // Alternating small and large alignments ensure the allocator has to do
    // some work to align things correctly, and we don't accidentally have
    // everything aligned.
    bosepro::DspStateMemory<float> align_s32(32);
    bosepro::DspStateMemory<float> align_s8(8);
    bosepro::DspStateMemory<float> align_s256(256);
    CHECK(align_s32.get() != nullptr);
    CHECK(((intptr_t)align_s32.get() & (32 - 1)) == 0);
    CHECK(align_s8.get() != nullptr);
    CHECK(((intptr_t)align_s8.get() & (8 - 1)) == 0);
    CHECK(align_s256.get() != nullptr);
    CHECK(((intptr_t)align_s256.get() & (256 - 1)) == 0);

    bosepro::DspStateMemory<float[]> align_v32;
    bosepro::DspStateMemory<float[]> align_v8;
    bosepro::DspStateMemory<float[]> align_v256;
    align_v32.resize(8, 32);
    align_v8.resize(8, 8);
    align_v256.resize(8, 256);
    CHECK(align_v32.get() != nullptr);
    CHECK(((intptr_t)align_v32.get() & (32 - 1)) == 0);
    CHECK(align_v8.get() != nullptr);
    CHECK(((intptr_t)align_v8.get() & (8 - 1)) == 0);
    CHECK(align_v256.get() != nullptr);
    CHECK(((intptr_t)align_v256.get() & (256 - 1)) == 0);

    bosepro::DspStateMemory<float[]> align_vc32(8, 32);
    bosepro::DspStateMemory<float[]> align_vc8(8, 8);
    bosepro::DspStateMemory<float[]> align_vc256(8, 256);
    CHECK(align_vc32.get() != nullptr);
    CHECK(((intptr_t)align_vc32.get() & (32 - 1)) == 0);
    CHECK(align_vc8.get() != nullptr);
    CHECK(((intptr_t)align_vc8.get() & (8 - 1)) == 0);
    CHECK(align_vc256.get() != nullptr);
    CHECK(((intptr_t)align_vc256.get() & (256 - 1)) == 0);

    bosepro::DspStateMemory<float*[]> align_m32;
    bosepro::DspStateMemory<float*[]> align_m8;
    bosepro::DspStateMemory<float*[]> align_m256;
    align_m32.resize(8, 8, 32);
    align_m8.resize(8, 8, 8);
    align_m256.resize(8, 8, 256);
    CHECK(align_m32.get() != nullptr);
    CHECK(align_m32[0] != nullptr);
    CHECK(((intptr_t)align_m32[0] & (32 - 1)) == 0);
    CHECK(align_m8.get() != nullptr);
    CHECK(align_m8[0] != nullptr);
    CHECK(((intptr_t)align_m8[0] & (8 - 1)) == 0);
    CHECK(align_m256.get() != nullptr);
    CHECK(align_m256[0] != nullptr);
    CHECK(((intptr_t)align_m256[0] & (256 - 1)) == 0);

    bosepro::DspStateMemory<float*[]> align_mc32(8, 8, 32);
    bosepro::DspStateMemory<float*[]> align_mc8(8, 8, 8);
    bosepro::DspStateMemory<float*[]> align_mc256(8, 8, 256);
    CHECK(align_mc32.get() != nullptr);
    CHECK(align_mc32[0] != nullptr);
    CHECK(((intptr_t)align_mc32[0] & (32 - 1)) == 0);
    CHECK(align_mc8.get() != nullptr);
    CHECK(align_mc8[0] != nullptr);
    CHECK(((intptr_t)align_mc8[0] & (8 - 1)) == 0);
    CHECK(align_mc256.get() != nullptr);
    CHECK(align_mc256[0] != nullptr);
    CHECK(((intptr_t)align_mc256[0] & (256 - 1)) == 0);
}

class WithDefaultCtor
{
public:
    WithDefaultCtor()
    {
        construction_count++;
    }

    static int get_construction_count()
    {
        return construction_count;
    }

private:
    static int construction_count;
};

int WithDefaultCtor::construction_count = 0;

class WithNontrivialDtor
{
public:
    WithNontrivialDtor()
    {
        destruction_count++;
    }

    static int get_destruction_count()
    {
        return destruction_count;
    }

private:
    static int destruction_count;
};

int WithNontrivialDtor::destruction_count = 0;

TEST_CASE("Constructors and Destructors")
{
    SUBCASE("Default Constructors")
    {
        bosepro::RegionManager region_manager;
        region_manager.open_region();

        // If `DspMemory` is used with types that have default constructors,
        // the default constructors should be called for each allocated
        // element.
        int previous_count;

        previous_count = WithDefaultCtor::get_construction_count();
        bosepro::DspStateMemory<WithDefaultCtor> wdc_s;
        CHECK(WithDefaultCtor::get_construction_count() == previous_count + 1);

        // For vectors, we don't allocate in the `DspMemory()` default
        // constructor, so we don't expect allocations (and default constructors
        // of the elements) to be called until `resize()` is called.
        previous_count = WithDefaultCtor::get_construction_count();
        bosepro::DspStateMemory<WithDefaultCtor[]> wdc_v;
        CHECK(WithDefaultCtor::get_construction_count() == previous_count);
        wdc_v.resize(4);
        CHECK(WithDefaultCtor::get_construction_count() == previous_count + 4);

        previous_count = WithDefaultCtor::get_construction_count();
        bosepro::DspStateMemory<WithDefaultCtor[]> wdc_v2(8);
        CHECK(WithDefaultCtor::get_construction_count() == previous_count + 8);

        previous_count = WithDefaultCtor::get_construction_count();
        bosepro::DspStateMemory<WithDefaultCtor*[]> wdc_m;
        CHECK(WithDefaultCtor::get_construction_count() == previous_count);
        wdc_m.resize(4, 8);
        CHECK(WithDefaultCtor::get_construction_count() == previous_count + 32);

        previous_count = WithDefaultCtor::get_construction_count();
        bosepro::DspStateMemory<WithDefaultCtor*[]> wdc_m2(8, 16);
        CHECK(WithDefaultCtor::get_construction_count() == previous_count + 128);
    }

    SUBCASE("Non-trivial Destructors")
    {
        bosepro::RegionManager region_manager;
        region_manager.open_region();

        // If `DspMemory` is used with types that have non-trivial destructors,
        // the destructors should be called for each allocated element when the
        // `DspMemory` is destroyed.
        int previous_count;

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor> wnd_s;
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count + 1);

        // If `DspMemory` for a vector is created with its default constructor,
        // the memory is not allocated until `resize()` is called.  We don't
        // expect the destructor to be called for objects that were never
        // allocated.
        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor[]> wnd_v;
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count);

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor[]> wnd_v;
            wnd_v.resize(4);
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count + 4);

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor[]> wnd_v(8);
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count + 8);

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor*[]> wnd_m;
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count);

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor*[]> wnd_m;
            wnd_m.resize(4, 8);
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count + 32);

        previous_count = WithNontrivialDtor::get_destruction_count();
        {
            bosepro::DspStateMemory<WithNontrivialDtor*[]> wnd_m(8, 16);
        }
        CHECK(WithNontrivialDtor::get_destruction_count() == previous_count + 128);
    }
}

TEST_SUITE_END(); // "DSP Memory"
