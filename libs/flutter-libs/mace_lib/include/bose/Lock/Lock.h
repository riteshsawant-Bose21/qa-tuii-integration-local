#pragma once
#ifndef LOCK_H
#define LOCK_H

#include <cassert>
#include <mutex>
#include <shared_mutex>


namespace bosepro
{
    /**
     * \brief       Wrappers for various std c++17 thread locking objects and methods
     *
     * \details     Each lock type has scoped lock class for automatic un/lock of 1 and 2 locks
     *              Example: Lock, ScopedLock(Lock&), ScopedLockPair(Lock&, Lock&)
     *              This adds ease of use and error reduction as you do not need to pair lock/unlock calls
     */

    /**
     * \class       ILock
     *
     * \brief       Interface for simple lock object
     *
     * \details     See also Lock and LockNOP  
     *               
     * Requirements : Mutex, Lockable, BasicLockable
     */
    class ILock
    {
    public:
        virtual                     ~ILock()                = default;
                                    ILock()                 = default;
                                    ILock(const ILock&)     = delete;
        ILock&                      operator=(const ILock&) = delete;
                                    ILock(ILock&&)          = delete;
        ILock&                      operator=(ILock&&)      = delete;

        virtual void                lock()     const = 0;
        virtual bool                try_lock() const = 0;
        virtual void                unlock()   const = 0;
    };


    /**
     * \class       IReadWriteLock
     *
     * \brief       Interface for lock that allows multiple readers and only a single writer
     *
     * \details     See also ReadWriteLock, ScopedReadWriteLock and ScopedReadWriteLockPair
     *               
     * Requiements : SharedMutex, Mutex, Lockable, BasicLockable
     */
    class IReadWriteLock
    {
    public:
        virtual                     ~IReadWriteLock()                     = default;
                                    IReadWriteLock()                      = default;
                                    IReadWriteLock(const IReadWriteLock&) = delete;
        IReadWriteLock&             operator=(const IReadWriteLock&)      = delete;
                                    IReadWriteLock(IReadWriteLock&&)      = delete;
        IReadWriteLock&             operator=(IReadWriteLock&&)           = delete;

	    virtual void                lock()            const = 0;
        virtual bool                try_lock()        const = 0;
        virtual void                unlock()          const = 0;
                                                          
        virtual void                lock_shared()     const = 0;
        virtual void                unlock_shared()   const = 0;
        virtual bool                try_lock_shared() const = 0;
    };


    /**
     * \class       Lock
     *
     * \brief       Simple re-entrant thread lock object for exclusive ownership
     *
     * \details     See also LockNOP, ScopedLock & ScopedLockPair
     */
    class Lock : public ILock
    {
    public:
		                            ~Lock()                    = default;							    
                                    Lock()                     = default;
									Lock(const Lock&)          = delete;
        Lock&                       operator=(const Lock&)     = delete;
									Lock(Lock&&)               = delete;
        Lock&                       operator=(Lock&&)          = delete;

	    inline void					lock()     const override {_lock.lock();}
        inline bool                 try_lock() const override {return _lock.try_lock();}
        inline void					unlock()   const override {_lock.unlock();}

    private:
	    mutable std::recursive_mutex _lock;
    };


    /**
     * \class       LockNOP
     *
     * \brief       Dummy lock object, for which all methods are nops
     *
     * \details     See also Lock, ScopedLock and ScopedLockPair
     */
    class LockNOP : public ILock
    {
    public:
                                    ~LockNOP()                = default;							    
                                    LockNOP()                 = default;
								    LockNOP(const LockNOP&)   = delete;
        LockNOP&                    operator=(const LockNOP&) = delete;
                                    LockNOP(LockNOP&&)        = delete;
        LockNOP&                    operator=(LockNOP&&)      = delete;

	    inline void					lock()     const override {}
        inline bool                 try_lock() const override {return true;}
        inline void					unlock()   const override {}
    };


    /**
     * \class       ReadWriteLock
     *
     * \brief       Thread lock object to allow multiple readers and only a single writer
     *
     * \details     See also ReadWriteLockNOP, ScopedReadWriteLock and ScopedReadWriteLockPair 
     */
    class ReadWriteLock : public IReadWriteLock
    {
    public:
		                            ~ReadWriteLock()					= default;							    
                                    ReadWriteLock()                     = default;
									ReadWriteLock(const ReadWriteLock&) = delete;
        ReadWriteLock&              operator=(const ReadWriteLock&)     = delete;
									ReadWriteLock(ReadWriteLock&&)      = delete;
        ReadWriteLock&              operator=(ReadWriteLock&&)          = delete;

	    inline void		            lock()            const override {_lock.lock();}
        inline bool                 try_lock()        const override {return _lock.try_lock();}
        inline void		            unlock()          const override {_lock.unlock();}
        
        inline void					lock_shared()     const override {_lock.lock_shared();}
        inline void					unlock_shared()   const override {_lock.unlock_shared();}
        inline bool                 try_lock_shared() const override {return _lock.try_lock_shared();}

    private:
	    mutable std::shared_mutex   _lock;
    };


    /**
     * \class       ReadWriteLockNOP
     *
     * \brief       Dummy lock object, for which all methods are nops
     *
     * \details     See also ReadWriteLock, ScopedReadWriteLock and ScopedReadWriteLockPair 
     */
    class ReadWriteLockNOP : public IReadWriteLock
    {
    public:
                                    ~ReadWriteLockNOP()                       = default;
                                    ReadWriteLockNOP()                        = default;
                                    ReadWriteLockNOP(const ReadWriteLockNOP&) = delete;
        ReadWriteLockNOP&           operator=(const ReadWriteLockNOP&)        = delete;
                                    ReadWriteLockNOP(ReadWriteLockNOP&&)      = delete;
        ReadWriteLockNOP&           operator=(ReadWriteLockNOP&&)             = delete;

	    inline  void                lock()            const override {}
        inline  bool                try_lock()        const override {return true;}
        inline  void				unlock()          const override {}

        inline  void                lock_shared()     const override {}
        inline  void                unlock_shared()   const override {}
        inline  bool                try_lock_shared() const override {return true;}
    };


    /**
     * \class       ScopedLock
     *
     * \brief       Auto lock and unlock of ILock 
     *
     * \details     Helper object for ease of use and error reduction
     */
    class ScopedLock
    {
    public:
									~ScopedLock()                 {_lock.unlock();}
                                    ScopedLock(const ILock& lock) : _lock(lock) {_lock.lock();}
									ScopedLock(const ScopedLock&) = delete;
        ScopedLock&                 operator=(const ScopedLock&)  = delete;
                                    ScopedLock(ScopedLock&&)      = delete;
        ScopedLock&                 operator=(ScopedLock&&)       = delete;

    private:
	    const ILock&                _lock;
    };

	/**
	 * \class       ScopedTryLock
	 *
	 * \brief       Auto try lock and maybe unlock of ILock (if try succeeded)
	 *
	 * \details     Helper object for ease of use and error reduction
	 */
	class ScopedTryLock
	{
	public:
		~ScopedTryLock()
		{
			if (_gotLock)
			{
				_lock.unlock();
			}
			_gotLock = false;
		}
		ScopedTryLock(const ILock& lock) : _lock(lock) { _gotLock = _lock.try_lock(); }
		ScopedTryLock(const ScopedTryLock&) = delete;
		ScopedTryLock& operator=(const ScopedTryLock&) = delete;
		ScopedTryLock(ScopedTryLock&&) = delete;
		ScopedTryLock& operator=(ScopedTryLock&&) = delete;
		bool gotLock() const { return _gotLock; }

	private:
		const ILock& _lock;
		bool _gotLock{false};
	};

    /**
     * \class       ScopedReadLock
     *
     * \brief       Auto lock and unlock of IReadWriteLock for reading
     *
     * \details     Performs a shared lock
     */
    class ScopedReadLock
    {
    public:
                                    ~ScopedReadLock()                          {_lock.unlock_shared();}
                                    ScopedReadLock(const IReadWriteLock& lock) : _lock(lock){_lock.lock_shared();}
									ScopedReadLock(const ScopedReadLock&)      = delete;
        ScopedReadLock&             operator=(const ScopedReadLock&)           = delete;
                                    ScopedReadLock(ScopedReadLock&&)           = delete;
        ScopedReadLock&             operator=(ScopedReadLock&&)                = delete;

    private:
	    const IReadWriteLock&       _lock;
    };


    /**
     * \class       ScopedWriteLock
     *
     * \brief       Auto lock and unlock of ReadWriteLock for writing
     *
     * \details     Performs an exclusive lock
     */
    class ScopedWriteLock
    {
    public:
									~ScopedWriteLock()                          {_lock.unlock();}
                                    ScopedWriteLock(const IReadWriteLock& lock) : _lock(lock){_lock.lock();}
									ScopedWriteLock(const ScopedWriteLock&)     = delete;
        ScopedWriteLock&            operator=(const ScopedWriteLock&)           = delete;
									ScopedWriteLock(ScopedWriteLock&&)          = delete;
        ScopedWriteLock&            operator=(ScopedWriteLock&&)                = delete;

    private:
	    const IReadWriteLock&       _lock;
    };


    /**
     * \class       ScopedLockPair
     *
     * \brief       Auto lock and unlock of a pair of Lock references
     *
     * \details     Especially handy for ctor, mtor and assignment operators
     */
    class ScopedLockPair
    {
    public:
                                    ~ScopedLockPair()
									{
                                        _read.unlock();
                                        _write.unlock();
                                    }

									ScopedLockPair(const ILock& writeLock, const ILock& readLock)
									    : _read(readLock),
                                          _write(writeLock)
									{
                                        if(&writeLock == &readLock)
                                        {
                                            assert(0);
                                            throw std::invalid_argument("ScopedLockPair cctor");
                                        }
                                        
                                        //Uses a deadlock avoidance algorithm 
                                        std::lock(_read, _write);
									}

									ScopedLockPair(const ScopedLockPair&) = delete;
        ScopedLockPair&             operator=(const ScopedLockPair&)      = delete;
									ScopedLockPair(ScopedLockPair&&)      = delete;
        ScopedLockPair&             operator=(ScopedLockPair&&)           = delete;

    private:
	    const ILock&                _read;
        const ILock&                _write;
    };


    /**
     * \class       ScopedReadWriteLockPair
     *
     * \brief       Auto lock and unlock of a pair of Lock references
     *
     * \details     Especially handy for ctor, mtor and assignment operators
     */
    class ScopedReadWriteLockPair
    {
    public:
                                    ~ScopedReadWriteLockPair()
									{
                                        _write.unlock();
                                        _read.unlock_shared();
                                    }

									ScopedReadWriteLockPair(const IReadWriteLock& writeLock, const IReadWriteLock& readLock)
									    : _read(readLock),
                                          _write(writeLock)
									{
                                        if(&writeLock == &readLock)
                                        {
                                            assert(0);
                                            throw std::invalid_argument("ScopedReadWriteLockPair cctor");
                                        }

                                        _write.lock();
                                        _read.lock_shared();
									}

									ScopedReadWriteLockPair(const ScopedReadWriteLockPair&) = delete;
        ScopedReadWriteLockPair&    operator=(const ScopedReadWriteLockPair&)               = delete;
									ScopedReadWriteLockPair(ScopedReadWriteLockPair&&)      = delete;
        ScopedReadWriteLockPair&    operator=(ScopedReadWriteLockPair&&)                    = delete;

    private:
	    const IReadWriteLock&       _read;
        const IReadWriteLock&       _write;
    };
}//bosepro

#endif //LOCK_H