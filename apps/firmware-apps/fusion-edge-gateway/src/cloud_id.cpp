#include "cloud_id.h"
#include <fcntl.h>
#include <unistd.h>
#include <string>
#include <cmath>
#include <vector>
#include <cstdint>

// This borrows code from nano_cpp:
//   https://github.com/mcmikecreations/nanoid_cpp/blob/master/src/nanoid/nanoid.cpp
//
//   MIT License
//   Copyright (c) 2020 Mykola Morozov
//
//   Permission is hereby granted, free of charge, to any person obtaining a
//   copy of this software and associated documentation files (the "Software"),
//   to deal in the Software without restriction, including without limitation
//   the rights to use, copy, modify, merge, publish, distribute, sublicense,
//   and/or sell copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//   DEALINGS IN THE SOFTWARE.

// Get some random data.
static int next_bytes(uint8_t* buffer, size_t size)
{
    // printf(" -- next_bytes %lu\n", size);
    int randomFd = open("/dev/urandom", O_RDONLY);
    if (randomFd < 0) {
        printf("Error opening urandom\n");
        return 1;
    }
    ssize_t result = read(randomFd, buffer, size);
    close(randomFd);

    if (result < 0) {
        // something went wrong
        printf("Error reading from urandom %d\n", errno);
        return 2;
    }
    return 0;
}

// Note: The clz32 and mask stuff helps with better distribution of the
// characters in the alphabet.
static int clz32(int x)
{
    return __builtin_clz(x); // GCC built-in count leading zeros.
}


// Generate a cloud ID for devices to register on Xyte.
// In tests this did not produce any duplicates in over one million IDs. This
// generates a modified "nanoid", without all the modern C++ from nano_cpp that
// won't compile on Redline and Inferno.
std::string makeCloudId(const std::string &partnerId)
{
    // The cloud ID has our 4 digit partner ID prepended.
    std::string output = partnerId;
    if (output.empty()) {
        // Default partner ID if the parameter is empty.
        output = "5bPj";
    }
    const size_t NUM_CHARS = 17; // 17 - 2 dashes = 15 chars of random data.
                              // 17 + 4 (partner ID) = 21 total characters.
    // `alphabet` has confusable characters removed, e.g., 1lI, 0Oo, 5S
    // '-' is also removed, because double dashes and dashes at the end are dumb.
    // Some vowels are removed so random IDs are less likely to spell offensive words.
    // And two dashes are inserted for readability.
    const char alphabet[] = {"234689bcdefghjkmnpqrstvwxyzBCDEFGHJKLMNPQRTVWXYZ"};
    const size_t maxindex = sizeof(alphabet) - 2;
    const size_t split1 = NUM_CHARS / 7;
    const size_t split2 = (int)NUM_CHARS / 1.7f;

    // See https://github.com/ai/nanoid/blob/main/README.md#Security
    // for an explanation of why masking is used rather than
    // `alphabet[randomData[i] % maxindex]`.
    const std::size_t mask = ( 2 << (31 - clz32( (int)(maxindex | 1) )) ) - 1;
    const auto step = (std::size_t)std::ceil(1.6 * (double)mask * (double)NUM_CHARS / (double)(maxindex + 1));

    auto randomData = std::vector<std::uint8_t>(step);
    size_t nRandomChars = 0;
    char c;

    while (true)
    {
        next_bytes(randomData.data(), randomData.size());

        for (std::size_t i = 0; i < step; i++)
        {
            const std::size_t alphabetIndex = randomData[i] & mask;
            if (alphabetIndex > maxindex) {
                continue;
            }
            if (nRandomChars == split1 || nRandomChars == split2) {
                c = '-';
            }
            else {
                c = alphabet[alphabetIndex];
            }

            output.push_back(c);
            if (++nRandomChars == NUM_CHARS) {
                return output;
            }
        }
    }
}
