#pragma once
#ifndef COLLECTIONS_UTILITIES_H__
#define COLLECTIONS_UTILITIES_H__

#include "SaferVector.h"

namespace bosepro
{
    /**
    \brief    General utilities to work on collection
    */
    class CollectionsUtilities
    {
    public:
        /**
        \brief      Check if a vector is a subset of another vector
        \tparam     masterVector :   The containing vector
        \tparam     subsetVector :   The contained vector
        \result     True if subsetVector is contained in masterVector
        */
        template <typename T>
        static bool contains(std::vector<T> const& masterVector, std::vector<T> const& subsetVector)
        {
            for (T const& vector1Element : subsetVector)
            {
                if (std::find(masterVector.begin(), masterVector.end(), vector1Element) == masterVector.end())
                    return false;
            }

            return true;
        }

        /**
        \brief      Check if a safer vector is a subset of another safer vector
        \tparam     masterVector :   The containing vector
        \tparam     subsetVector :   The contained vector
        \result     True if subsetVector is contained in masterVector
        */
        template <typename T>
        static bool contains(SaferVector<T> const& masterVector, SaferVector<T> const& subsetVector)
        {
            for (T const& vector1Element : subsetVector)
            {
                if (std::find(masterVector.begin(), masterVector.end(), vector1Element) == masterVector.end())
                    return false;
            }

            return true;
        }
    };
}

#endif // COLLECTIONS_UTILITIES_H__
