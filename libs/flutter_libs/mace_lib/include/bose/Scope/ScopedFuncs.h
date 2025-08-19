#pragma once
#define SCOPEDFUNCS
#ifdef SCOPEDFUNCS

#include <functional>
#include <utility>

namespace bosepro
{
    /**
     * \class      	ScopedFuncs
     *					
     * \brief      	simple class that runs some code when entering scope and some other code when leaving scope.
     *                 
     * \details    	
     */
    class ScopedFuncs
    {
    public:
                        ScopedFuncs(std::function<void()> fnIn, std::function<void()> fnOut) : _fnIn(std::move(fnIn)), _fnOut(std::move(fnOut))
                        {
                            if (_fnIn)
                            {
                                _fnIn();
                            }
                        }

                        ~ScopedFuncs()
                        {
                            if (_fnOut)
                            {
                                _fnOut();
                            }
                        }

                        ScopedFuncs(const ScopedFuncs&)         = delete;
        ScopedFuncs&      operator=(const ScopedFuncs&)         = delete;
                        ScopedFuncs(ScopedFuncs&&)              = delete;
        ScopedFuncs&      operator=(ScopedFuncs&&)              = delete;

    private:
        std::function<void()>   _fnIn, _fnOut;
    };
}

#endif // SCOPEDFUNCS