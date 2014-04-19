module turn;
import core, utility;
import game, ability, unit;
import speed;

import action;

shared class Turn
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	Ability[ uint ] abilities; // The abilities
	Unit[] units; // The units

	/// Recieve actions from the server
	this()
	{

	}

	/// Process an action
	void doAction( Action action )
	{
		logInfo( "Action received ", action );
		// Move a unit
		if( action.actionID == 0 )
		{
			units[ action.originID ].move( action.targetID );
		}
		// Preview move for a unit
		else if( action.actionID == 1 )
		{
			units[ action.originID ].previewMove();
		}
		else
		{
			abilities[ action.actionID ].use( action.originID, action.targetID );
		}
	}

	/// Send an action to the server
	void sendAction( Action action )
	{
		// only send if we are connected to the server
		if( Game.serverConn )
		{
			logInfo( "Action being sent ", action );
			Game.serverConn.send!Action( action, ConnectionType.TCP );
		}
	}
}