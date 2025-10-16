#ifndef _OCALITE_OCF_MSG_QUEUE_H
#define _OCALITE_OCF_MSG_QUEUE_H

#include <queue>
#include <mutex>
#include <condition_variable>

template <typename T>
class ControlPal_MsgQueue {
public:
    void push(T new_value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(new_value));
        cond_var_.notify_one();
    }

    void wait_and_pop(T& value) {
        std::unique_lock<std::mutex> lock(mutex_);
        cond_var_.wait(lock, [this]{ return !queue_.empty(); });
        value = std::move(queue_.front());
        queue_.pop();
    }

    bool try_pop(T& value) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return false;
        }
        value = std::move(queue_.front());
        queue_.pop();
        return true;
    }
private:
    std::queue<T> queue_;
    mutable std::mutex mutex_;
    std::condition_variable cond_var_;
};

#endif
