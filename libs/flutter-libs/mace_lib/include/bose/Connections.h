#pragma once
#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <string>
#include <utility>
#include <vector>
#include <algorithm>
#include <iterator>
#include "Connection.h"


namespace bosepro::mechanical
{	
	/**
        * \brief Container for connection objects. A simple std::vector child with helper methods
        */
    class Connections : public std::vector<Connection>
    {
    public:
                                    Connections(std::string name = "")			: m_Name(std::move(name)) {}
									~Connections()								= default;
                                    Connections(const Connections&)             = default;
                                    Connections& operator=(const Connections&)  = default;
                                    Connections(Connections&&)                  = default;
                                    Connections& operator=(Connections&&)       = default;

                                    //Connections for
        inline std::string          getName() const {return m_Name;}
        inline void                 setName(const std::string& name){m_Name = name;}

                                        
	    /**
            * \brief gets the subset of connections that have the specified name, id, and state. if no Id is specified, then only name and state need to match
            * \param name	:	module name 
            * \param id	:	connection Id. if left blank, then only name and state will be checked
            * \param state :	connection state
            * \return subset of connections that match the request
            */
        Connections                 getConnectionsByName(const std::string& name, const std::string& id = "", Connection::State state = Connection::State::Any) const
                                    {
                                        Connections cons(m_Name);

                                        std::copy_if(cbegin(), cend(), std::back_inserter(cons), [&](auto const& c)
                                        {
										    return c.getName() == name && c.isState(state) && (id.empty() || c.getId() == id);
                                        });
                                       
                                        return cons;
                                    }

	    /**
            * \brief gets the subset of connections that have the specified position and state
            * \param pos	:	connection position
            * \param state :	connection state
            * \return  subset of connections by position
            */
        Connections                 getConnectionsByPosition(Connection::Position pos, Connection::State state = Connection::State::Any) const
                                    {
                                        Connections cons(m_Name);

                                        std::copy_if(cbegin(), cend(), std::back_inserter(cons), [&](auto const& c){return c.getPosition() == pos && c.isState(state);});
                                       
                                        return cons;
                                    }

		/**
		* \brief gets the subset of connections that have the specified state
		* \param state :	connection state
		* \return  subset of connections by state
		*/
        Connections                 getConnectionsByState(Connection::State state)
                                    {
                                        Connections cons(m_Name);

                                        std::copy_if(cbegin(), cend(), std::back_inserter(cons), [&](auto const& c){return c.isState(state);});
                                       
                                        return cons;
                                    }

	    /**
            * \brief gets the subset of connections that can connect to the specified connection
            * \param con		: the connection to test against
            * \param state	: connection state
            * \return subset of connections that can connect to the specified connection
            */
            Connections                getConnectionsTo(const Connection& con, Connection::State state = Connection::State::Any) const
                                    {
                                        Connections cons(m_Name);

                                        std::copy_if(cbegin(), cend(), std::back_inserter(cons), [&](auto const& c){return c.canConnect(con) && c.isState(state);});
                                       
                                        return cons;
                                    }

    private:
        std::string                 m_Name;
    };
}//bosepro::mechanical

#endif //CONNECTIONS_H