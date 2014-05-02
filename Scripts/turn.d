module turn;
import core, utility;
import game, grid, tile, ability, unit, action;
import speed;

enum Team {
	Robot,
	Wolf,
}

class Turn
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	Team currentTeam; // the team this player controls
	Team activeTeam; // the active team
	
	this()
	{
		// arbitrary starting team
		activeTeam = Team.Robot;

		// update the units on the team
		foreach( unit; Game.units )
		{
			if( unit.team == currentTeam )
				unit.newTurn();
		}

		// hotkey to end turn
		Input.addKeyDownEvent( "EndTurn", ( kc )
		{
			// send the switch to the server
			Game.turn.sendAction( Action( 9, 0, 0, true ) );
			switchActiveTeam();
		} );
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
		// Preview move for a unit
		else if( action.actionID == 2 )
		{
			Game.units[ action.originID ].deselect();
		}
		// Switch active team
		else if( action.actionID == 9 )
		{
			switchActiveTeam();
		}
		// Use an ability
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
			if( unit.team == activeTeam && unit.remainingActions > 0 )
				turnOver = false;
		}
		if ( turnOver )
			switchActiveTeam();
	}

	/// Set the team of the player
	void setTeam( uint teamNum )
	{
		if( teamNum == 1 )
		{
			currentTeam = Team.Robot;
		}
		else
		{
			currentTeam = Team.Wolf;
		}

		// update the units on the team
		foreach( unit; Game.units )
		{
			if( unit.team != currentTeam )
				Game.grid.getTileByID( unit.position ).type = TileType.OccupantInactive;
		}
	}
	
	/// Switch the active team
	void switchActiveTeam()
	{
		switch ( activeTeam )
		{
			default:
				break;
			case Team.Robot:
				activeTeam = Team.Wolf;
				break;
			case Team.Wolf:
				activeTeam = Team.Robot;
				break;
		}

		logInfo( "Active team: ", activeTeam );
		
		// update the units on the team
		foreach( unit; Game.units )
		{
			if( unit.team == activeTeam )
				unit.newTurn();
			else
				Game.grid.getTileByID( unit.position ).type = TileType.OccupantInactive;
		}
		
		Game.grid.updateFogOfWar();
	}
}
