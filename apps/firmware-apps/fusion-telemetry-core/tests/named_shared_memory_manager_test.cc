#include <gtest/gtest.h>

#include <array>
#include <atomic>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>

#include <boost/interprocess/shared_memory_object.hpp>

#include "named_shared_memory_manager_factory.h"

namespace {

std::string uniqueShmName() {
  static std::atomic<unsigned long> counter{0};
  const auto suffix = std::to_string(getpid()) + std::to_string(++counter);
  std::string name = "tshm_mgr_" + suffix;
  if (name.size() >= bosepro::Metadata::NAME_MAX_LENGTH) {
    name.resize(bosepro::Metadata::NAME_MAX_LENGTH - 1);
  }
  return name;
}

void cleanupSharedMemory(const std::string& name) {
  boost::interprocess::shared_memory_object::remove(name.c_str());
  boost::interprocess::shared_memory_object::remove((name + "_metadata").c_str());
}

struct SharedMemoryCleanupGuard {
  explicit SharedMemoryCleanupGuard(std::string n) : name(std::move(n)) {}
  ~SharedMemoryCleanupGuard() { cleanupSharedMemory(name); }
  std::string name;
};

}  // namespace

TEST(NamedSharedMemoryManagerTest, FactoryReturnsSameInstance) {
  auto& first = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  auto& second = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  EXPECT_EQ(&first, &second);
}

TEST(NamedSharedMemoryManagerTest, CreateGetRemoveLifecycle) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  auto& shm = manager.createSharedMemory(name, 128);
  EXPECT_EQ(shm.getSize(), 128U);
  EXPECT_NO_THROW(manager.getSharedMemory(name));

  auto names = manager.getSharedMemoryNames();
  EXPECT_NE(std::find(names.begin(), names.end(), name), names.end());

  EXPECT_NO_THROW(manager.removeSharedMemory(name));
  EXPECT_THROW(manager.getSharedMemory(name), std::runtime_error);
}

TEST(NamedSharedMemoryManagerTest, DuplicateCreateThrows) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  EXPECT_NO_THROW(manager.createSharedMemory(name, 64));
  EXPECT_THROW(manager.createSharedMemory(name, 64), std::runtime_error);
  EXPECT_NO_THROW(manager.removeSharedMemory(name));
}

TEST(NamedSharedMemoryManagerTest, OpenMissingSharedMemoryThrows) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  EXPECT_THROW(manager.openSharedMemory(name), std::runtime_error);
}

TEST(NamedSharedMemoryManagerTest, OpenReturnsExistingHandleInSameManager) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  auto& created = manager.createSharedMemory(name, 64);
  auto& opened = manager.openSharedMemory(name);
  EXPECT_EQ(&created, &opened);

  EXPECT_NO_THROW(manager.removeSharedMemory(name));
}

TEST(NamedSharedMemoryManagerTest, RemoveMissingThrows) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name = uniqueShmName();
  SharedMemoryCleanupGuard cleanup(name);

  EXPECT_THROW(manager.removeSharedMemory(name), std::runtime_error);
}

TEST(NamedSharedMemoryManagerTest, TotalBytesAllocatedReflectsWrites) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  const std::string name1 = uniqueShmName();
  const std::string name2 = uniqueShmName();
  SharedMemoryCleanupGuard cleanup1(name1);
  SharedMemoryCleanupGuard cleanup2(name2);

  auto& shm1 = manager.createSharedMemory(name1, 64);
  auto& shm2 = manager.createSharedMemory(name2, 64);
  shm1.setPersonalityAsWriter();
  shm2.setPersonalityAsWriter();

  std::array<char, 10> data1{};
  std::array<char, 7> data2{};
  ASSERT_NO_THROW(shm1.write(data1.data(), data1.size(), "bytes"));
  ASSERT_NO_THROW(shm2.write(data2.data(), data2.size(), "bytes"));

  EXPECT_EQ(manager.getTotalBytesAllocated(), data1.size() + data2.size());

  EXPECT_NO_THROW(manager.removeSharedMemory(name1));
  EXPECT_NO_THROW(manager.removeSharedMemory(name2));
}

TEST(NamedSharedMemoryManagerTest, ConcurrentFactoryAccessReturnsSameInstance) {
  std::vector<bosepro::NamedSharedMemoryManager*> instances(8, nullptr);
  std::vector<std::thread> threads;

  for (std::size_t i = 0; i < instances.size(); ++i) {
    threads.emplace_back([&instances, i]() {
      instances[i] = &bosepro::NamedSharedMemoryManagerFactory::getInstance();
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }

  for (const auto* instance : instances) {
    ASSERT_NE(instance, nullptr);
    EXPECT_EQ(instance, instances[0]);
  }
}

TEST(NamedSharedMemoryManagerTest, RapidCreateRemoveCycles) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  for (int i = 0; i < 100; ++i) {
    const std::string name = uniqueShmName();
    SharedMemoryCleanupGuard cleanup(name);
    ASSERT_NO_THROW(manager.createSharedMemory(name, 64));
    ASSERT_NO_THROW(manager.removeSharedMemory(name));
  }
}

TEST(NamedSharedMemoryManagerTest, ConcurrentCreateRemoveDifferentNames) {
  auto& manager = bosepro::NamedSharedMemoryManagerFactory::getInstance();
  std::vector<std::thread> threads;

  for (int t = 0; t < 4; ++t) {
    threads.emplace_back([&manager]() {
      for (int i = 0; i < 25; ++i) {
        const std::string name = uniqueShmName();
        SharedMemoryCleanupGuard cleanup(name);
        manager.createSharedMemory(name, 64);
        manager.removeSharedMemory(name);
      }
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }
}
