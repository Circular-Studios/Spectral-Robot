module turn;
import game, ability, unit, action;
import core, utility;
import speed;

enum Team {
	Robot,
	Wolf,
}

shared class Turn
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	Team currentTeam;
	
	
	this()
	{
		// arbitrary starting team
		currentTeam = Team.Wolf;
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
	
	/// Check all the units on the current team for no more actions available
	void checkTurnOver()
	{
		bool turnOver = true;
		foreach( unit; Game.units )
		{
			if( unit.team == currentTeam && unit.remainingActions > 0 )
				turnOver = false;
		}
		if ( turnOver )
			switchActiveTeam();
	}
	
	/// Switch the active team
	void switchActiveTeam()
	{
		switch ( currentTeam )
		{
			default:
				break;
			case Team.Robot:
				currentTeam = Team.Wolf;
				break;
			case Team.Wolf:
				currentTeam = Team.Robot;
				break;
		}
		
		logInfo( "New turn: ", currentTeam );
		
		foreach( unit; Game.units )
		{
			if( unit.team == currentTeam )
				unit.newTurn();
		}
	}
}
