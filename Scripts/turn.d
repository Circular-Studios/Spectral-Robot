module turn;
import core, utility;
import game, ability, unit;

struct Action
{
public:
	uint actionID;
	uint originID;
	uint targetID;
}

shared class Turn
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	Ability[ uint ] abilities; // The abilities
	Unit[] units; // The units
	
	/// Process an action into an ability or movement
	void doAction( uint actionID, uint originID, uint targetID )
	{
		// Move a unit
		if( actionID == 0 )
		{
			units[ originID ].move( targetID );
		}
		else
		{
			abilities[ actionID ].use( originID, targetID );
		}
	}
}