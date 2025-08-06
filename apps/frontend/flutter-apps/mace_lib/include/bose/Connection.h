#pragma once
#ifndef CONNECTION_H
#define CONNECTION_H

#include <string>
#include <utility>
#include "Placement.h"

namespace bosepro::mechanical
{
	/**
	 * \brief represents a single physical connection between hardware components. also see Connections
	 */
	class Connection
	{
	public:
		enum class Position 
        {
			None = 0x000,
			Above = 0x001,
			Below = 0x002,
			Left = 0x010,
			Right = 0x020,
			Front = 0x100,
			Back = 0x200
		};

		enum class State 
        {
			Invalid = 0x1,      // Invalid connection - (mostly here for future-proofing, connection shouldn't exist if it's invalid)
			InUse = 0x2,		// Valid connection - in use, unavailable
			Open = 0x4,			// Valid connection - open, ready to connect
			Any = 0x7			// Any connection state
		};     

									Connection(Position pos = Position::None, State state = State::Open)
										: Connection({}, pos, state) {}

									Connection(std::string destinationName, Position pos = Position::None, State state = State::Open)
										: m_ComponentName(std::move(destinationName)), m_State(state), m_Position(pos) {}


									Connection(std::string destinationName, std::string connectionId, Position pos = Position::None, State state = State::Open)
										: m_ConnectionId(std::move(connectionId)), m_ComponentName(std::move(destinationName)), m_State(state), m_Position(pos) {}

									Connection(const Connection&) = default;
		Connection&					operator=(const Connection&) = default;
									Connection(Connection&&) = default;
		Connection&					operator=(Connection&&) = default;
		virtual                     ~Connection() = default;

		void                        setId(const std::string& val)				        { m_ConnectionId = val; }
		std::string                 getId()								        const	{ return m_ConnectionId; }

		void                        setName(const std::string& val)				        { m_ComponentName = val; }
		std::string                 getName()                                   const	{ return m_ComponentName; }

		void                        setPosition(Position val)					        { m_Position = val; }
		Position                    getPosition()                               const	{ return m_Position; }
		bool                        isPosition(Position val)                    const	{ return val == m_Position; }

		void                        setState(State val) { m_State = val; }
		State                       getState()                                  const	{ return m_State; }
		bool                        isState(State val)                          const	{ return val == State::Any || m_State == State::Any || m_State == val; }

		void                        setPlacement(Placement val)					        { m_Placement = std::move(val); }
		Placement			        getPlacement()                              const	{ return m_Placement; }
		
		bool                        canConnect(const Connection& other)         const	{ return getPositionInverse(m_Position) == other.m_Position; }

        void                        setSplayAllowed(bool allowed)                       { m_SplayAllowed = allowed; }
        bool                        getSplayAllowed()                           const   { return m_SplayAllowed; }

		static Position             getPositionInverse(Position val)
                                    {
	                                    Position pos = Position::None;

	                                    switch (val)
	                                    {
	                                    case Position::Above: pos = Position::Below; break;
	                                    case Position::Below: pos = Position::Above; break;
	                                    case Position::Left: pos = Position::Right; break;
	                                    case Position::Right: pos = Position::Left; break;
	                                    case Position::Front: pos = Position::Back; break;
	                                    case Position::Back: pos = Position::Front; break;
	                                    case Position::None: pos = Position::None; break;
	                                    }

	                                    return pos;
                                    }

		static std::string          getPositionText(Position val)
                                    {
	                                    std::string pos;

	                                    switch (val)
	                                    {
	                                    case Position::Above: pos = "Above"; break;
	                                    case Position::Below: pos = "Below"; break;
	                                    case Position::Left: pos = "Left"; break;
	                                    case Position::Right: pos = "Right"; break;
	                                    case Position::Front: pos = "Front"; break;
	                                    case Position::Back: pos = "Back"; break;
	                                    case Position::None:  pos = "None"; break;
	                                    }

	                                    return pos;
                                    }

		/**
		 * \brief generates the opposite connection of the one specified.
		 *        for example, if A connects to B from above, then the inversion would be a connection from B to A from below
		 *                     with a name of "A" and the inverse values of transform
		 * \param connection : the connection to create an inversion of
		 * \param name : the name for the new connection (i.e. the device this connection connects to)
		 * \return the new connection
		 */
		static auto                 getInverseConnection(const Connection& connection, const std::string& name)
		                            {
			                            auto placement = connection.getPlacement();
			                            const auto originalPos = connection.getPosition();

			                            // create connection
			                            Connection c{ name, connection.getId(), getPositionInverse(originalPos) };
                                        c.setPlacement(Placement::fromMatrix(placement.getTransformInv()));
                                        c.setSplayAllowed(connection.getSplayAllowed());

			                            return c;
		                            }


		/**
		 * \brief gets whether this connection is the inverse of the given connection
		 * \param other : the other connection to compare against
		 * \return true if they are inverses
		 */
		auto                        isInverseOf(const Connection& other) const
		                            {
			                            auto isInverse = false;
			                            const auto positionOther = other.getPosition();
			                            const auto positionMatches = getPositionInverse(m_Position) == positionOther;

                                        if (positionMatches)
                                        {
                                            const auto placementOther = other.getPlacement();

                                            const auto placementOtherInverse = Placement::fromMatrix(placementOther.getTransformInv());

                                            // check inverted location and orientation match which is what method was doing a bit incorrectly before.
                                            // alternatively we could probably just compare the transform.
                                            isInverse = m_Placement.getLocation() == placementOtherInverse.getLocation() &&
                                                        m_Placement.getOrientation() == placementOtherInverse.getOrientation();
                                        }
			                            return isInverse;
		                            }
		/**
		 * \return returns true if both Connections have the same id, name, state, position, and placement information
		 */
		friend auto                 operator==(const Connection& lhs, const Connection& rhs)
                                    {
	                                    return lhs.m_ConnectionId == rhs.m_ConnectionId
                                            && lhs.m_SplayAllowed == rhs.m_SplayAllowed
		                                    && lhs.m_ComponentName == rhs.m_ComponentName
		                                    && lhs.m_State == rhs.m_State
		                                    && lhs.m_Position == rhs.m_Position
		                                    && lhs.m_Placement == rhs.m_Placement;
                                    }

		auto                        operator!=(const Connection& other)                     const { return !(*this == other); }

	private:
		// the ID/name of the connection, in the case that there exists more than 1 connection with the same component name and position
		std::string                 m_ConnectionId;

		// the name of the component to connect to
		std::string                 m_ComponentName;

		State                       m_State;
		Position                    m_Position;

		Placement					m_Placement;

        bool                        m_SplayAllowed{ true }; // allowed unless specified otherwise
	};
}

#endif //CONNECTION_H