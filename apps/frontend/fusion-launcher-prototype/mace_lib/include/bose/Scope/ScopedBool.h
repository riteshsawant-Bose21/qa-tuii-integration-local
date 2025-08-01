#pragma once
#define SCOPEDBOOL
#ifdef SCOPEDBOOL

#include <atomic>

namespace bosepro
{
	/**
	 * \class      	ScopedBool
	 *					
	 * \brief      	Just a simple class to take a ref to an atomic bool and set to true (or false) when entering scope, and false (or true) when leaving scope
	 * \details    	
	 */
	class ScopedBool
	{
	public:
                                explicit ScopedBool(std::atomic_bool& b, const bool setValue = true) : _bool(b)
								{
									_bool = _setValue = setValue;
								}

								~ScopedBool()
								{
									_bool = !_setValue; // reset bool to the opposite of initial value
								}

								ScopedBool(const ScopedBool&) = delete;
		ScopedBool&				operator=(const ScopedBool&) = delete;
								ScopedBool(ScopedBool&&) = delete;
		ScopedBool&				operator=(ScopedBool&&) = delete;

	protected:
        bool                    _setValue; // the initial bool state of the atomic bool when this object is created.
		std::atomic_bool&       _bool;
	};
}

#endif // SCOPEDBOOL

