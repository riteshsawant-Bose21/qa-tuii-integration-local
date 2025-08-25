#pragma once
#ifndef BOM_H
#define BOM_H

#include <vector>
#include "BOMInfo.h"

namespace bosepro::model
{
	/**
	 * \class		BOM
	 *
	 * \brief		Bill of materials data for hardware components such as loudspeakers & rigging accessories
	 *				See also BOMInfo
	 */
    class BOM 
    {
    public:
        virtual                 ~BOM()                  = default;
                                BOM()                   = default;
                                BOM(const BOM&)         = default;
                                BOM(BOM&&)              = default;
        BOM&                    operator=(const BOM&)   = default;
        BOM&                    operator=(BOM&&)        = default;


        inline friend bool      operator!=(const BOM& lhs, const BOM& rhs) {return !(lhs == rhs);}
        inline friend bool      operator==(const BOM& lhs, const BOM& rhs)
                                {
                                    bool equal = false;

                                    if(lhs.getNumItems() == rhs.getNumItems())
                                    {
                                        equal = true;

                                        for(unsigned int i = 0; i < lhs.getNumItems(); ++i)
                                        {
                                            if(lhs.m_Items[i] != rhs.m_Items[i])
                                            {
                                                equal = false;
                                                break;
                                            }
                                        }
                                    }

                                    return equal;
                                }

        BOM&                    operator+=(const BOM& other)            {append(other); return *this;}
        BOM&                    operator-=(const BOM& other)            {remove(other); return *this;}

        void                    append(const BOM& other);
        void                    remove(const BOM& other);

        void                    addItem(const BOMInfo& item);
        void                    removeItem(const BOMInfo& item);

        inline void             removeAllItems()                        {m_Items.clear();}

        BOMInfo                 getItem(unsigned int index)     const;
        const BOMInfo&          getItemRef(unsigned int index)  const;

        inline unsigned int     getNumItems()                   const   {return static_cast<unsigned int>(m_Items.size());}

    private:
        using Items             = std::vector<BOMInfo>;
        Items                   m_Items;
    };
}//bosepro

#endif //BOM_H