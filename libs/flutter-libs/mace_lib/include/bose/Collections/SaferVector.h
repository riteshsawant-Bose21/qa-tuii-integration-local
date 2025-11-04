#pragma once

#ifndef SAFERVECTOR_H
#define SAFERVECTOR_H

#include <vector>
#include <bose/Lock/Lock.h>

namespace bosepro
{	
    /**
     * \class      	SaferVector
     *
     * \brief      	Use a vector class with an additional lock to provide extra protection for non const methods
     *                 
     * \details    	HasA vector in order to add extra thread safety (like for doing an append, push_back, etc.)
     */
	template <class T = uint64_t>
	class SaferVector
	{
	public:
		

			                    SaferVector() = default;
                        		~SaferVector() = default;

								SaferVector(std::initializer_list<T> l) : _col(l)
								{
									ScopedLock sl(_lock);
								}

                        		SaferVector(const SaferVector& other)
                        		{
                        			ScopedLock sl(other._lock);
                        			_col = other._col;
                        		}

                                SaferVector(SaferVector&& other) noexcept
                        		{
                        			ScopedLock sl(other._lock);
                        			_col = std::move(other._col);
                        		}

        SaferVector&			operator=(const SaferVector& other)
			                    {
				                    if(this != &other)
				                    {
					                    ScopedLockPair sl(_lock, other._lock);

					                    _col = other._col;
				                    }

				                    return *this;
			                    }

		SaferVector&            operator=(SaferVector&& other) noexcept
			                    {
				                    if(this != &other)
				                    {
					                    ScopedLockPair sl(_lock, other._lock);

					                    _col = std::move(other._col);
				                    }

				                    return *this;
			                    }

		bool					operator==(const SaferVector& other) const
								{
									ScopedLockPair sl(_lock, other._lock);
									if(this->size() != other.size())
										return false;
                                    // avoid undefined behavior with empty
                                    if(this->empty() && other.empty())
                                        return true;

									return std::equal(this->cbegin(), this->cend(), other.cbegin());
								}

        bool                    operator!=(const SaferVector& other) const
                                {
                                    ScopedLockPair sl(_lock, other._lock);
                                    return !(*this == other);
                                }

			                    // std::vector pass-throughs
		auto&                   operator[](std::size_t idx)
			                    {
				                    // no need for lock due to STL guarantee.  for vector [] behaves as const for thread safety.
                                    // but, in order to range check that the index is valid, we need a lock
				                    return _col[idx];
			                    }

		const auto&             operator[](std::size_t idx) const
			                    {
				                    return _col[idx];
			                    }

        auto&                   at(std::size_t idx)
			                    {                                        
				                    ScopedLock sl(_lock);
					                if(idx >= _col.size())
					                {
						                return getDefaultValue();
					                }
				                    return _col[idx];
			                    }

        const auto&             at(std::size_t idx) const
			                    {
			                        return _col.at(idx);
			                    }

        auto                    atGuardCopy(std::size_t idx)
			                    {
				                    ScopedLock sl(_lock);
					                if(idx >= _col.size())
					                {
					                    return getDefaultValue();
					                }
                                    return _col[idx];
			                    }

		template<typename... Ts>
		auto					emplace(typename std::vector<T>::const_iterator it, Ts&&... args)
								{
							 		ScopedLock sl(_lock);
						 			return _col.emplace(it, std::forward<Ts>(args)...);
								}

		void                    emplace_back(T&& t)
			                    {
				                    ScopedLock sl(_lock);
				                    _col.emplace_back(std::move(t));
			                    }

		void                    emplace_back(T& t)
			                    {
				                    ScopedLock sl(_lock);
				                    _col.emplace_back(t);
			                    }

        void                    push_back(const T& t)
			                    {
			                        ScopedLock sl(_lock);
                                    _col.push_back(t);
			                    }

		void                    push_back(T&& t) // allow rvalues
								{
									ScopedLock sl(_lock);
									_col.push_back(t);
								}

		void                    appendAll(SaferVector &col)
			                    {
				                    ScopedLock sl(_lock);
				                    _col.insert(_col.end(), col.begin(), col.end());
			                    }

		void					appendAll(std::initializer_list<T> l)
								{
									ScopedLock sl(_lock);
									_col.insert(_col.end(), l.begin(), l.end());
								}
                    
        auto                    insert(typename std::vector<T>::const_iterator it, const T& t)
                                {
                                    ScopedLock sl(_lock);
                                    return _col.insert(it, t);
                                }

        auto                    insert(typename std::vector<T>::const_iterator it, std::size_t n, const T& t)
                                {
                                    ScopedLock sl(_lock);
                                    return _col.insert(it, n, t);
                                }

        auto                    insert(typename std::vector<T>::const_iterator it, typename std::vector<T>::iterator first, typename std::vector<T>::iterator last)
                                {
                                    ScopedLock sl(_lock);
                                    return _col.insert(it, first, last);
                                }

        auto                    insert(typename std::vector<T>::const_iterator it, T&& t)
                                {
                                    ScopedLock sl(_lock);
                                    return _col.insert(it, t);
                                }

        auto                    insert(typename std::vector<T>::const_iterator it, std::initializer_list<T> l)
                                {
                                    ScopedLock sl(_lock);
                                    return _col.insert(it, l);
                                }

		auto                    begin() noexcept
			                    {
				                    // behaves as const for thread safety so no need for lock
				                    return _col.begin();
			                    }

        auto                    begin() const noexcept
                                {
                                    // behaves as const for thread safety so no need for lock
                                    return _col.begin();
                                }

		auto                    cbegin() const noexcept
			                    {
				                    return _col.begin();
			                    }

        auto                    rbegin() noexcept
                                {
                                    return _col.rbegin();
                                }

        auto                    rbegin() const noexcept
                                {
                                    return _col.rbegin();
                                }

		auto                    end() noexcept
			                    {
				                    // same guarantee, behaves as const for thread safety
				                    return _col.end();
			                    }

        auto                    end() const noexcept
                                {
                                    // same guarantee, behaves as const for thread safety
                                    return _col.end();
                                }

		auto                    cend() const noexcept
			                    {
				                    return _col.end();
			                    }

        auto                    rend() noexcept
                                {
                                    return _col.rend();
                                }

        auto                    rend() const noexcept
                                {
                                    return _col.rend();
                                }

        auto&                   front()
                        		{
                        			return _col.front();
                        		}

        const auto&             front() const
                        		{
                        			return _col.front();
                        		}

        auto&                   back()
                        		{
                        			return _col.back();
                        		}

        const auto&             back() const
                        		{
                        			return _col.back();
                        		}

		auto                    size() const noexcept
			                    {
				                    // no need to take lock for the methods that are const, guarantee in STL.  See 
				                    // see https://en.cppreference.com/w/cpp/container
                        			return _col.size();
			                    }

		void					resize(size_t n)
								{
									ScopedLock sl(_lock);
									_col.resize(n);
								}

		void					resize(size_t n, T val)
								{
									ScopedLock sl(_lock);
									_col.resize(n, val);
								}

        bool                    empty() const
                        		{
                        			ScopedLock sl(_lock);
                                    return _col.empty();
                        		}

		void                    clear()
			                    {
				                    ScopedLock sl(_lock);
				                    _col.clear();
			                    }

        void                    erase(typename std::vector<T>::const_iterator it)
                        		{
                        			ScopedLock sl(_lock);
                                    _col.erase(it);
                        		}

        void                    erase(typename std::vector<T>::const_iterator first, typename std::vector<T>::const_iterator last)
                                {
                                    ScopedLock sl(_lock);
                                    _col.erase(first, last);
                                }

        auto&                   getDefaultValue() const
                        		{
                                    static T tBad; // default val returned if out of range.
                                    return tBad;
                        		}

        void                    reserve(std::size_t count)
                        		{
                                    ScopedLock sl(_lock);
                        			_col.reserve(count);
                        		}

		auto					capacity() const noexcept
								{
									return _col.capacity();
								}
								using value_type = T;
		
	private:
		Lock                    _lock;
		std::vector<T>          _col;
	};	

	template<class T = uint64_t>
	using SaferVectorPtr = std::shared_ptr<SaferVector<T>>;
}

#endif
