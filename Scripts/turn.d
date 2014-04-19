module turn;
import core, utility;
import game, ability, unit;
import speed;

struct Action
{
public:
	uint actionID;
	uint originID;
	uint targetID;
	bool saveToDatabase;
}

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
		logInfo( "Action being sent ", action );
		Game.serverConn.send!Action( action, ConnectionType.TCP );
	}
}
