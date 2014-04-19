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
		Game.serverConn.onReceiveData!Action ~= action => doAction( action );
	}

	/// Process an action
	void doAction( Action action )
	{
		// Move a unit
		if( action.actionID == 0 )
		{
			units[ action.originID ].move( action.targetID );
		}
		// Preview move for a unit
		if( action.actionID == 1 )
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
		Game.serverConn.send!Action( action, ConnectionType.TCP );
	}
}
