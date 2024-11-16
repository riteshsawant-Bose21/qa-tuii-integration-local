#pragma once

#include <spdlog/spdlog.h>

#include <array>
#include <cstdlib>
#include <forward_list>
#include <map>
#include <memory_resource>
#include <new>
#include <type_traits>

namespace bosepro {

/// This class manages multiple memory regions for storing data with different
/// usage patterns (real-time, non-real-time, etc.).  It is only used
/// internally: individual memory allocations are handled with the `DspMemory`
/// types.
class RegionManager {
public:
    RegionManager() : region()
    { }

    ~RegionManager()
    {
        close_region();
    }

    /// Different platforms may provide different regions for different
    /// purposes.  For example, a platform such as a DSP with small L1 SRAM
    /// may use different regions than a platform with cache and large
    /// external memory.
    enum RegionType {
        FAST,               ///< Most memory used in real time.
        SLOW,               ///< Memory never used in real time.
        SIGNAL,             ///< Memory for signals shared between blocks.
        NUM_REGION_TYPES
    };


    /// Allocate memory from a region.
    ///
    /// @param  size  The size of the request in bytes.
    /// @param  align  The alignment of the request in bytes.
    /// @param  rtype  The type of region to allocate from.
    /// @return  A pointer to the allocated memory.
    void *allocate(size_t size, size_t align, RegionType rtype)
    {
        return region[rtype].allocate(size, align);
    }


    /// Track the count of objects in this request so that the destructor
    /// can be called on each object when the memory is destroyed.
    ///
    /// @param  p  A pointer to the memory.
    /// @param  count  The number of objects stored in the memory.
    /// @param  rtype  The type of region the memory was allocated from.
    void mark_for_destruction(void *p, size_t count, RegionType rtype)
    {
        region[rtype].mark_for_destruction(p, count);
    }


    /// Get the number of objects stored in the memory, for the purpose
    /// of calling the destructor on each object.  This must be called on
    /// objects in the reverse order in which `mark_for_destruction()` was
    /// called.
    ///
    /// @param  p  A pointer to the memory.
    /// @param  rtype  The type of region the memory was allocated from.
    /// @return  The number of objects stored in the memory.
    size_t get_destruction_count(void *p, RegionType rtype)
    {
        return region[rtype].get_destruction_count(p);
    }


    /// Start using this region manager for future DspMemory allocations.
    void open_region();


    /// Stop using this region manager for future DspMemory allocations.
    void close_region();


private:
    /// An individual memory region.  The `RegionManager` handles the use
    /// of each of these regions.  The region is currently implented with the
    /// C++17 `monotonic_buffer_resource`.
    class Region {
    public:
        ~Region()
        {
            for (auto &p : large_chunks)
            {
                std::free(p);
            }
        }


        /// Allocate memory from this region.  If the request is very large,
        /// it may be allocated from the heap rather than this region.
        ///
        /// @param  size  The size of the request in bytes.
        /// @param  align  The alignment of the request in bytes.
        void *allocate(size_t size, size_t align)
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


        /// Track the count of objects in this request so that the destructor
        /// can be called on each object when the memory is destroyed.
        ///
        /// @param  p  A pointer to the memory.
        /// @param  count  The number of objects stored in the memory.
        void mark_for_destruction(void *p, size_t count)
        {
            if (to_destroy.count(p) != 0)
            {
                SPDLOG_CRITICAL("Can't mark pointer {} for destruction again",
                                p);
                return;
            }

            to_destroy[p] = count;
        }


        /// Get the number of objects stored in the memory, for the purpose
        /// of calling the destructor on each object.  This must be called on
        /// objects in the reverse order in which `mark_for_destruction()` was
        /// called.
        ///
        /// @param  p  A pointer to the memory.
        /// @return  The number of objects stored in the memory.
        size_t get_destruction_count(void *p)
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


    private:
        static const size_t LARGE_CHUNK_SIZE = 4096;
        std::pmr::monotonic_buffer_resource mbr;
        std::forward_list<void *> large_chunks;
        std::map<void *, size_t> to_destroy;
    };

    std::array<Region, NUM_REGION_TYPES> region;
};


/// This class should not be used directly in algorithms.  It implements the
/// common memory allocation functionality of all `DspMemory` types.
class DspMemoryImpl {
public:
    static void set_region_manager(RegionManager *region_manager)
    {
        mgr = region_manager;
    }


protected:
    static void *allocate(size_t size, size_t align,
                          RegionManager::RegionType rt)
    {
        if (mgr == nullptr)
        {
            SPDLOG_CRITICAL("Region manager does not exist!");
            return nullptr;
        }

        return mgr->allocate(size, align, rt);
    }

    static void mark_for_destruction(void *p, size_t count,
                                     RegionManager::RegionType rt)
    {
        if (mgr == nullptr)
        {
            SPDLOG_CRITICAL("Region manager does not exist!");
        }

        mgr->mark_for_destruction(p, count, rt);
    }

    static size_t get_destruction_count(void *p, RegionManager::RegionType rt)
    {
        if (mgr == nullptr)
        {
            SPDLOG_CRITICAL("Region manager does not exist!");
            return 0;
        }

        return mgr->get_destruction_count(p, rt);
    }

    static RegionManager *mgr;
};


/// DSP memory for a single object of type `T`.  1-D and 2-D arrays are
/// implemented in specializations below. The memory is stored in the
/// region of type `R`.  The `R2` region type is unused except in the
/// specialization of `DspMemory` for 2-D arrays.
///
/// If `T` has a default constructor, it will be called when the memory is
/// created.  If `T` does not have a default constructor, the constructor should
/// be called using placement new.
///
/// When the `DspMemory` is destroyed, the destructor will be called, if `T` has
/// a non-trivial destructor.
///
/// This class implements the `->` operator for accessing the object, as well
/// as the `get()` function for retrieving its pointer.
///
/// This can be thought of roughly as a `std::unique_ptr` which stores its
/// memory in a region.
template <typename T, RegionManager::RegionType R, RegionManager::RegionType R2=R>
class DspMemory : public DspMemoryImpl {
public:
    template <typename X = T, typename SFINAE = typename std::enable_if_t<std::is_default_constructible_v<X>>, typename P = SFINAE>
    DspMemory(size_t align=alignof(std::max_align_t))
    {
        p = static_cast<T *>(allocate(sizeof(T), align, R));
        new (p) T();
    }


    template <typename X = T, typename = typename std::enable_if_t<!std::is_default_constructible_v<X>>>
    DspMemory(size_t align=alignof(std::max_align_t))
    {
        p = static_cast<T *>(allocate(sizeof(T), align, R));
    }


    ~DspMemory()
    {
        // Schedule the destructor to be called for the object when the
        // region containing the memory is destroyed.
        if (!std::is_trivially_destructible_v<T>)
        {
            p->~T();
        }
    }


    DspMemory(const DspMemory &) = delete;
    DspMemory &operator=(const DspMemory &) = delete;
    DspMemory(DspMemory &&) = delete;
    DspMemory &operator=(DspMemory &&) = delete;


    T* get()
    {
        return p;
    }


    const T* get() const
    {
        return p;
    }


    T* operator->()
    {
        return p;
    }


    const T* operator->() const
    {
        return p;
    }

    static const size_t CACHE_LINE_SIZE = 64;
private:
    T *p;
};


/// DSP memory for an array of objects of type `T`.  The memory is stored in
/// the region of type `R`.  The `R2` region type is unused.
///
/// If `T` has a default constructor, it will be called for each element in
/// the array when the memory is created (or when it is resized, if the
/// default constructor for `DspMemory` is used).  If `T` does not have a
/// default constructor, the constructor should be called on each element
/// using placement new.
///
/// When the `DspMemory` is destroyed, the destructor will be called on each
/// element, if `T` has a non-trivial destructor.
///
/// This class implements the `[]` operator for accessing elements, as well
/// as the `get()` function for retrieving a pointer to the first element.
///
/// This can be thought of roughly as a `std::unique_ptr` which stores its
/// memory in a region.
template <typename T, RegionManager::RegionType R, RegionManager::RegionType R2>
class DspMemory<T[], R, R2> : public DspMemoryImpl {
public:
    /// The default constructor doesn't allocate memory.  The `resize()`
    /// function must be used later to allocate it.
    DspMemory() : DspMemoryImpl(), p(nullptr) { }


    /// Create and allocate memory with the given size in the region of type
    /// `R`.  The `resize()` function must not be called on memory created
    /// with this constructor.
    ///
    /// @param  size  The size of the memory in elements of type `T`.
    /// @param  align  The alignment of the memory in bytes.
    DspMemory(size_t size, size_t align=alignof(std::max_align_t))
        : DspMemoryImpl(), p(nullptr)
    {
        resize(size, align);
    }


    ~DspMemory()
    {
        // If `T` has a destructor, call it on each element.
        if (!std::is_trivially_destructible_v<T>)
        {
            size_t count = get_destruction_count((void *)p, R);
            for (size_t i = 0; i < count; i++)
            {
                p[i].~T();
            }
        }
    }


    DspMemory(const DspMemory &) = delete;
    DspMemory &operator=(const DspMemory &) = delete;
    DspMemory(DspMemory &&) = delete;
    DspMemory &operator=(DspMemory &&) = delete;


    /// Resize the memory.  This may only be called once, and only if the
    /// default constructor was used to create this memory.  This allocates
    /// the requested amount of memory from the region of type `R`.
    ///
    /// @param  size  The size of the memory in elements of type `T`.
    /// @param  align  The alignment of the memory in bytes.
    void resize(size_t size, size_t align=alignof(std::max_align_t))
    {
        if (p != nullptr)
        {
            SPDLOG_CRITICAL("Resized DSP memory more than once!");
        }

        if (size > 0)
        {
            p = static_cast<T *>(allocate(size * sizeof(T), align, R));

            // Call the default constructor on all elements, if available.
            if (std::is_default_constructible_v<T>)
            {
                for (size_t i = 0; i < size; i++)
                {
                    new ((void *)&p[i]) T();
                }
            }

            // Schedule the destructor to be called for all elements when the
            // region containing the memory is destroyed.
            if (!std::is_trivially_destructible_v<T>)
            {
                mark_for_destruction((void *)(p), size, R);
            }
        }
    }


    T& operator[](int index)
    {
        return p[index];
    }


    const T& operator[](int index) const
    {
        return p[index];
    }


    T* get()
    {
        return p;
    }


    const T* get() const
    {
        return p;
    }

private:
    T *p;
};


/// DSP memory for an 2-D array of objects of type `T`.  The first dimension
/// (an array of pointers) is stored in the region of type `R`.  The actual
/// data is stored in the region of type `R2` (which defaults to the same as
/// `R`).
///
/// If `T` has a default constructor, it will be called for each element in
/// the 2-D array when the memory is created (or when it is resized, if the
/// default constructor for `DspMemory` is used).  If `T` does not have a
/// default constructor, the constructor should be called on each element
/// using placement new.
///
/// When the `DspMemory` is destroyed, the destructor will be called on each
/// element, if `T` has a non-trivial destructor.
///
/// This class implements the `[]` operator for accessing pointers to rows, as
/// well as the `get()` function for retrieving a pointer to the first row's
/// pointer.
///
/// This can be thought of roughly as a `std::unique_ptr` which stores its
/// memory in a region, but with support for 2-D arrays (without nesting).
template <typename T, RegionManager::RegionType R, RegionManager::RegionType R2>
class DspMemory<T*[], R, R2> : public DspMemoryImpl {
public:
    /// The default constructor doesn't allocate memory.  The `resize()`
    /// function must be used later to allocate it.
    DspMemory() : DspMemoryImpl(), p(nullptr) { }


    /// Create and allocate a 2-D memory with the given sizes, placing the row
    /// pointers in the region of type `R`, and the data in the region of type
    /// `R2`.  The `resize()` function must not be called on memory created
    /// with this constructor.
    ///
    /// @param  size1  The size of the first dimension in rows.
    /// @param  size2  The size of the second dimension in elements of type `T`.
    /// @param  align  The alignment of the second dimension memory in bytes.
    DspMemory(size_t size1, size_t size2, size_t align=alignof(std::max_align_t))
        : DspMemoryImpl(), p(nullptr)
    {
        resize(size1, size2, align);
    }


    ~DspMemory()
    {
        // If `T` has a destructor, call it on each element.
        if (!std::is_trivially_destructible_v<T>)
        {
            size_t count = get_destruction_count((void *)p[0], R);
            for (size_t i = 0; i < count; i++)
            {
                p[0][i].~T();
            }
        }
    }


    DspMemory(const DspMemory &) = delete;
    DspMemory &operator=(const DspMemory &) = delete;
    DspMemory(DspMemory &&) = delete;
    DspMemory &operator=(DspMemory &&) = delete;


    /// Resize the memory.  This may only be called once, and only if the
    /// default constructor was used to create this memory.  This allocates
    /// the requested amount of memory from the region of type `R`.
    ///
    /// @param  size1  The size of the first dimension in rows.
    /// @param  size2  The size of the second dimension in elements of type `T`.
    /// @param  align  The alignment of the second dimension memory in bytes.
    void resize(size_t size1, size_t size2,
                size_t align=alignof(std::max_align_t))
    {
        if (p != nullptr)
        {
            SPDLOG_CRITICAL("Resized DSP memory more than once!");
        }

        p = static_cast<T **>(allocate(size1 * sizeof(T *),
                              alignof(std::max_align_t), R2));

        if (size2 > 0)
        {
            p[0] = static_cast<T *>(allocate(size1 * size2 * sizeof(T),
                                             align, R));

            for (size_t i = 1; i < size1; i++)
            {
                p[i] = &p[0][i * size2];
            }

            // Call the default constructor on all elements, if available.
            if (std::is_default_constructible_v<T>)
            {
                for (size_t i = 0; i < size1 * size2; i++)
                {
                    new ((void *)&p[0][i]) T();
                }
            }

            // Schedule the destructor to be called for all elements when the
            // region containing the memory is destroyed.
            if (!std::is_trivially_destructible_v<T>)
            {
                mark_for_destruction((void *)p[0], size1 * size2, R);
            }
        }
    }


    T*& operator[](int index)
    {
        return p[index];
    }


    const T* const & operator[](int index) const
    {
        return p[index];
    }


    T** get()
    {
        return p;
    }


    const T* const * get() const
    {
        return p;
    }

private:
    T **p;
};


// The memory types specified below are the ones that should ultimately be
// used in algorithm code.  They indicate the usage pattern of the memory
// by the algorithm so that it can be stored in the appropriate memory region
// for the platform.  For example, we may discover that we can gain performance
// by placing `DspTableMemory` in a separate section from other fast DSP memory.

/// Memory that is used for an algorithm's internal, private state.  The
/// algorithm generally reads and writes this memory during every frame, and
/// retains its value between frames.  This would be used for things like
/// a delay buffer in a delay algorithm, or smoothed signal levels in an
/// automatic microphone mixer.
template<typename T>
using DspStateMemory = DspMemory<T, RegionManager::FAST>;


/// Memory that is used internally by an algorithm as a temporary workspace.
/// The algorithm generally reads and writes this memory during every frame,
/// but does not retain its value between frames.  This would be used for
/// things like storing a windowed input signal before applying an FFT.
template<typename T>
using DspTempMemory = DspMemory<T, RegionManager::FAST>;


/// Memory that is used internally by an algorithm that does not change over
/// time.  This may be stored statically or generated when a block is created,
/// and is read by the algorithm in real time.  Examples are tables of FFT
/// twiddle factors, or a window.  In some cases, the same table may be used
/// by multiple blocks (such as when multiple blocks use the same size FFT).
template <typename T>
using DspTableMemory = DspMemory<T, RegionManager::FAST>;


/// Memory that is used by an algorithm to store coefficients.  These are
/// written in non-real-time as a result of user control parameter changes,
/// and used by the algorithm in real time.  Examples are gain values or
/// equalizer coefficients.
///
/// This should not be used for non-real-time, user facing parameter values.
/// Those should be stored in `DspParamMemory`.  For example, a parametric
/// EQ would keep its gain, center frequency, and Q values in `DspParamMemory`
/// while keeping the actual IIR coefficients in `DspCoeffMemory`.
template<typename T>
using DspCoeffMemory = DspMemory<T, RegionManager::FAST>;


/// Memory that is used for input or output signals.  Signal memory is written
/// to by the source block, and read by any number of destination blocks.
template<typename T>
using DspSignalMemory = DspMemory<T, RegionManager::FAST, RegionManager::SIGNAL>;


/// Memory that is used for storing non-real-time, user facing parameter
/// values.  These are written when a user parameter change occurs, but are
/// not used in real-time by the algorithm.  Rather, the control parameter will
/// use a post-processing function to calculate coefficients based on these
/// parameters (which will then likely be written to a `DspCoeffMemory`).
template<typename T>
using DspParamMemory = DspMemory<T, RegionManager::SLOW>;


/// Memory that is used for storing meter values.  Meter memory is written
/// in real-time by the algorithm, and read in non-real-time as the meters are
/// displayed.
template<typename T>
using DspTelemetryMemory = DspMemory<T, RegionManager::FAST>;


} // namespace bosepro
