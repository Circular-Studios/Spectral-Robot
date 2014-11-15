module turn;
import dash.core, dash.utility, dash.net;
import game, grid, tile, ability, unit, action;
import gl3n.linalg, gl3n.math;

enum Team {
	Robot,
	Wolf,
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
	
	// the last recorded camera positions for the teams
	vec3 lastCamPosRobot;
	quat lastCamRotRobot;
	vec3 lastCamPosWolf;
	quat lastCamRotWolf;
	
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
		}

		// update the units on the team
		foreach( unit; Game.units )
		{
			if( unit.team != currentTeam )
				Game.grid.getTileByID( unit.position ).type = TileType.OccupantInactive;
		}
	}
	
	// set the initial camera positions of the teams
	void setInitCamPos(vec3 robotPos, vec3 robotRot, vec3 wolfPos, vec3 wolfRot) {
		lastCamPosRobot = robotPos;
		lastCamRotRobot = quat.euler_rotation(robotRot.x.radians, robotRot.y.radians, robotRot.z.radians);
		
		lastCamPosWolf = wolfPos;
		lastCamRotWolf = quat.euler_rotation(wolfRot.x.radians, wolfRot.y.radians, wolfRot.z.radians);
	}
	
	// returns to the last recorded camera position for the active team
	void setCameraToRecord() {
		switch (activeTeam) {
			case Team.Robot:
				Game.level.camera.owner.transform.position = lastCamPosRobot;
				Game.level.camera.owner.transform.rotation = lastCamRotRobot;
				break;
				
			case Team.Wolf:
				Game.level.camera.owner.transform.position = lastCamPosWolf;
				Game.level.camera.owner.transform.rotation = lastCamRotWolf;
				break;
				
			default:
				break;
		}
	}
	
	// record the camera's current position for the active team
	void recordCameraPos() {
		switch (activeTeam) {
			case Team.Robot:
				lastCamPosRobot = Game.level.camera.owner.transform.position;
				lastCamRotRobot = Game.level.camera.owner.transform.rotation;
				break;
				
			case Team.Wolf:
				lastCamPosWolf = Game.level.camera.owner.transform.position;
				lastCamRotWolf = Game.level.camera.owner.transform.rotation;
				break;
				
			default:
				break;
		}
	}
	
	/// Switch the active team
	void switchActiveTeam()
	{
		recordCameraPos();
	
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
			setCameraToRecord();

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
