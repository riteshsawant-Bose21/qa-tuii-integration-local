#pragma once
#ifndef TIMESTAMP_H

#include <chrono>

namespace bosepro
{
    /**
     * \class       Timestamp
     *
     * \brief       Wrap std::chrono for a steady timestamp (ms)
     *
     * \details     
     */
	class Timestamp
	{
        using millis            = std::chrono::milliseconds;

	public:
                                Timestamp() { set(); }
                                ~Timestamp()                            = default;
                                Timestamp(const Timestamp&)             = default;
                                Timestamp& operator=(const Timestamp&)  = default;
                                Timestamp(Timestamp&&)                  = default;
                                Timestamp& operator=(Timestamp&&)       = default;

		void                    set()
			                    {
			                        auto ms = std::chrono::duration_cast<millis> (std::chrono::steady_clock::now().time_since_epoch());
				                    _milli = ms.count();
			                    }

        void                    reset() { _milli = 0; }

        const uint64_t&         get() const { return _milli; }

		bool                    operator< (const Timestamp& other) const { return _milli < other._milli; }
        bool                    operator> (const Timestamp& other) const { return _milli > other._milli; }

        bool                    operator==(const Timestamp& other) const { return _milli == other._milli; }
        bool                    operator!=(const Timestamp& other) const { return !(*this == other); }

        uint64_t                absDelta(const Timestamp& tsOther) const
                                {
                                    return std::abs(static_cast<long long>(tsOther.get()) - static_cast<long long>(_milli));
                                }

	protected:
        uint64_t                _milli{ 0 };
	};	

    class ScopedDuration
    {
    public:
        ScopedDuration(uint64_t &msDur) : _msDur(msDur)
        {
            _ts1.set();
        }
        ~ScopedDuration()
        {
            _ts2.set();
            _msDur = _ts1.absDelta(_ts2);
        }

    private:
        Timestamp _ts1;
        Timestamp _ts2;
        uint64_t& _msDur;
    };
}
#endif // !TIMESTAMP_H

