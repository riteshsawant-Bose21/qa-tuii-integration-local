#pragma once
#ifndef BOMINFO_H
#define BOMINFO_H

#include <string>

namespace bosepro::model
{
	/**
	 * \class		BOMInfo
	 *
	 * \brief		Bill of materials record
	 *				See also BOM
	 */
    class BOMInfo
    {
    public:
            virtual                    ~BOMInfo()                          = default;
                                    BOMInfo(const BOMInfo&)             = default;
                                    BOMInfo& operator=(const BOMInfo&)  = default;
                                    BOMInfo(BOMInfo&&)                  = default;
                                    BOMInfo& operator=(BOMInfo&&)       = default;

                                    BOMInfo(std::string item = "",
                                            std::string sku  = "",
                                            std::string desc = "")
                                        : m_Item(std::move(item)),
                                            m_Sku(std::move(sku)),
                                            m_Desc(std::move(desc)),
                                            m_Quantity(1)
                                    {
                                    }

        inline friend bool          operator!=(const BOMInfo& lhs, const BOMInfo& rhs) {return !(lhs == rhs);}
        inline friend bool          operator==(const BOMInfo& lhs, const BOMInfo& rhs)
                                    {
                                        return lhs.m_Item == rhs.m_Item &&
                                                lhs.m_Sku  == rhs.m_Sku  &&
                                                lhs.m_Desc == rhs.m_Desc;
                                    }

        inline std::string          getItem()                           const   {return m_Item;}
        inline std::string          getSku()                            const   {return m_Sku;}
        inline std::string          getDesc()                           const   {return m_Desc;}
        inline unsigned int         getQuantity()                       const   {return m_Quantity;}

        inline void                 setItem(std::string val)                    {m_Item      = std::move(val);}
        inline void                 setSku (std::string val)                    {m_Sku       = std::move(val);}
        inline void                 setDesc(std::string val)                    {m_Desc      = std::move(val);}

    protected:
        friend class                BOM;

                                    //Prefix
        BOMInfo&                    operator++()                                {++m_Quantity; return *this;}
        BOMInfo&                    operator--()                                {if(m_Quantity > 0)--m_Quantity; return *this;}

                                    //Postfix
        BOMInfo                     operator++(int)                             {BOMInfo tmp(*this); operator++(); return tmp;}
        BOMInfo                     operator--(int)                             {BOMInfo tmp(*this); operator--(); return tmp;}

    private:
        std::string                 m_Item;
        std::string                 m_Sku;
        std::string                 m_Desc;
        unsigned int                m_Quantity;
    };
}//bosepro::model

#endif //BOMINFO_H