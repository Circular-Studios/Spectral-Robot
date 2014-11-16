module turn;
import dash.core, dash.utility, dash.net;
import game, grid, tile, ability, unit, action;
import gl3n.linalg, gl3n.math;

enum Team {
	Robot,
	Criminal,
}

enum NetworkAction {
	move, // move unit
	preview, // preview move for unit
	deselect, // deselect unit
	select, // select ability
	switchTeam, // switch active team
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
				Game.turn.sendAction( Action( NetworkAction.switchTeam, 0, 0, true ) );
				switchActiveTeam();
			}
		} );
	}

	/// Process an action
	void doAction( Action action )
	{
		info( "Action received ", action );

		switch(action.actionID) {
			// Move a unit
			case NetworkAction.move:
				Game.units[ action.originID ].move( action.targetID );
				break;

			// Preview move for a unit
			case NetworkAction.preview:
				Game.units[ action.originID ].previewMove();
				break;

			// Deselect a unit
			case NetworkAction.deselect:
				Game.units[ action.originID ].deselect();
				break;

			// Select ability
			case NetworkAction.select:
				Game.grid.selectAbility( action.originID );
				break;

			// Switch active team
			case NetworkAction.switchTeam:
				switchActiveTeam();
				break;

			// Use an ability
			default:
				Game.units[ action.originID ].useAbility( action.actionID, action.targetID );
				break;
		}
	}

	/// Send an action to the server
	void sendAction( Action action )
	{
		// only send if we are connected to the server
		if( Game.serverConn )
		{
			info( "Action being sent ", action );
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
			Game.turn.sendAction( Action( NetworkAction.switchTeam, 0, 0, true ) );
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
			currentTeam = Team.Criminal;

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
				activeTeam = Team.Criminal;
				break;
			case Team.Criminal:
				activeTeam = Team.Robot;
				break;
		}

		// hotseat multiplayer
		if( !Game.serverConn )
			currentTeam = activeTeam;

		info( "Active team: ", activeTeam );

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
