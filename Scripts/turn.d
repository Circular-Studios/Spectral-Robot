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
			Game.units[ action.originID ].move( action.targetID );
		}
		// Preview move for a unit
		else if( action.actionID == 1 )
		{
			Game.units[ action.originID ].previewMove();
		}
		else
		{
			Game.abilities[ action.actionID ].use( action.originID, action.targetID );
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
