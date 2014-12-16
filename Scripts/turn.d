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

  // the last recorded camera positions for the teams
  vec3 lastCamPosRobot;
  quat lastCamRotRobot;
  vec3 lastCamPosCriminal;
  quat lastCamRotCriminal;

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
        // deselect the active unit, if any
        if( Game.grid.selectedUnit )
        {
          Game.turn.sendAction( Action( NetworkAction.deselect, Game.grid.selectedUnit.ID, 0, false ) );
          Game.grid.selectedUnit.deselect();
        }

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
    }

    // update the units on the team
    foreach( unit; Game.units )
    {
      if( unit.team != currentTeam )
        Game.grid.getTileByID( unit.position ).type = TileType.OccupantInactive;
    }
  }

    // set the initial camera positions of the teams
  void setInitCamPos( float[] robotPos, float[] robotRot, float[] criminalPos, float[] criminalRot )
  {
    lastCamPosRobot = vec3( robotPos[ 0 ], robotPos[ 1 ], robotPos[ 2 ] );
    lastCamRotRobot = quat.euler_rotation( robotRot[ 0 ].radians, robotRot[ 1 ].radians, robotRot[ 2 ].radians );

    lastCamPosCriminal = vec3( criminalPos[ 0 ], criminalPos[ 1 ], criminalPos[ 2 ] );
    lastCamRotCriminal = quat.euler_rotation( criminalRot[ 0 ].radians, criminalRot[ 1 ].radians, criminalRot[ 2 ].radians );
  }

  // returns to the last recorded camera position for the active team
  void setCameraToRecord()
  {
    final switch ( activeTeam )
    {
      case Team.Robot:
        Game.level.camera.owner.transform.position = lastCamPosRobot;
        Game.level.camera.owner.transform.rotation = lastCamRotRobot;
        break;

      case Team.Criminal:
        Game.level.camera.owner.transform.position = lastCamPosCriminal;
        Game.level.camera.owner.transform.rotation = lastCamRotCriminal;
        break;
    }
  }

  // record the camera's current position for the active team
  void recordCameraPos()
  {
    final switch ( activeTeam )
    {
      case Team.Robot:
        lastCamPosRobot = Game.level.camera.owner.transform.position;
        lastCamRotRobot = Game.level.camera.owner.transform.rotation;
        break;

      case Team.Criminal:
        lastCamPosCriminal = Game.level.camera.owner.transform.position;
        lastCamRotCriminal = Game.level.camera.owner.transform.rotation;
        break;
    }
  }

  /// Switch the active team
  void switchActiveTeam()
  {
    recordCameraPos();
	
	Game.turnCounter.Iterate();

    final switch ( activeTeam )
    {
      case Team.Robot:
        activeTeam = Team.Criminal;
        Game.level.ui.callJSFunction( "setTurn", [ Game.turnCounter.turnCounter, 1 ] );
        break;
      case Team.Criminal:
        activeTeam = Team.Robot;
        Game.level.ui.callJSFunction( "setTurn", [ Game.turnCounter.turnCounter, 0 ] );
        break;
    }

    // hotseat multiplayer
    if( !Game.serverConn )
      currentTeam = activeTeam;
	  setCameraToRecord();
	  
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
