module turn;
import dash.core, dash.utility;
import game, grid, tile, ability, unit, action;
import gl3n.linalg, gl3n.math;
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
		Input.addButtonDownEvent( "EndTurn", ( kc )
		{
			if( currentTeam == activeTeam )
			{
				// send the switch to the server
				Game.turn.sendAction( Action( 9, 0, 0, true ) );
				switchActiveTeam();
			}
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
		// Deselect a unit
		else if( action.actionID == 2 )
		{
			Game.units[ action.originID ].deselect();
		}
		// Select ability
		else if( action.actionID == 3 )
		{
			Game.grid.selectAbility( action.originID );
		}
		// Switch active team
		else if( action.actionID == 9 )
		{
			switchActiveTeam();
		}
		// Use an ability
		else
		{
			Game.units[ action.originID ].useAbility( action.actionID, action.targetID );
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
			foreach ( ability; unit.abilities)
			{
				Game.abilities[ability].decrementCooldown();
			}
		}
		if ( turnOver )
		{
			Game.turn.sendAction( Action( 9, 0, 0, true ) );
			switchActiveTeam();
		}
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

			// make the camera look nice
			// TODO: This will break when we have multiple levels
			Game.level.camera.owner.transform.position = vec3( 300, Game.level.camera.owner.transform.position.y, 0 );
			Game.level.camera.owner.transform.rotation = quat.euler_rotation( radians( 180 ), 0, radians( -45 ) );
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

		// hotseat multiplayer
		if( !Game.serverConn )
			currentTeam = activeTeam;

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
