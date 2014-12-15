module unit;
import game, ability, action, grid, effect, tile, turn, gameMode;
import dash.core, dash.utility, dash.components;
import gl3n.linalg, gl3n.math, gl3n.interpolate;
import std.algorithm;

enum ACTIONS_RESET = 3;

class Unit : Component
{
private:
  static uint nextID = 0;

public:
  alias owner this;
  @ignore
  immutable uint ID;
  @optional
  int hp;
  @optional
  int maxHP;
  @optional
  int speed;
  @optional
  uint position;
	@optional
	uint spawnPoint;
  @optional
  Animation animation;
  @rename("Team") @byName
  Team team;
  @ignore
  int remainingRange;
  @ignore
  int remainingActions;
  @ignore
  uint[] abilities;
  @ignore
  Tile[] selectedTiles;
  @ignore
  IEffect[] activeEffects;
  @ignore
  GameObject parent;
  @property int x() { return cast(int)position % Game.grid.gridX; }
  @property int y() { return cast(int)position / Game.grid.gridX; }
  @property float z() { return Game.grid.getTileByID( position ).z; }

  this()
  {
    ID = nextID++;
    remainingActions = ACTIONS_RESET;
  }

  /// Initialize a unit
  void initialize( uint position, Team team, int hp, int sp, uint[] abilities )
  {
    this.position = position;
    this.team = team;
    this.hp = hp;
    this.maxHP = hp;
    this.speed = sp;
    this.remainingRange = this.speed;
    this.abilities = abilities;
    spawnPoint = position;
    updatePosition();
    this.animation = this.getComponent!Animation;

    // begin idle animation
    if (team == Team.Robot) animation.changeAnimation("robot_idle", 0);
  }

  /// Use an ability
  bool useAbility( uint abilityID, uint targetID )
  {
    if( remainingActions > 0 &&
        abilities.countUntil( abilityID ) > -1 &&
        Game.abilities[ abilityID ].checkRange( this.position, targetID ) )
    {
      // animation
      int range = Game.abilities[abilityID].range;
      if (range == 1) {
        if (team == Team.Robot) animation.runAnimationOnce("Robot_Anim_Melee");
      } else if (range > 1) {
        if (team == Team.Robot) animation.runAnimationOnce("Robot_Anim_Range");
      }

      if( Game.abilities[ abilityID ].use( position, targetID ) )
      {
        return actionUsed();
      }
    }

    return false;
  }

  /// Apply an effect to the unit
  ///
  /// Params:
  ///  prop =   the variable you want to effect
  ///  diff =   the amount to change prop by
  ///  duration = the number of turns the effect is applied
  ///  reset =  true if prop should return to its original value when the effect is over
  @ignore
  void applyEffect( string prop )( int diff, int duration = 0, bool reset = false )
  {
    // apply the effect for a number of turns
    if( duration > 0 )
    {
      // add the ability to a list
      activeEffects ~= new Effect!prop( diff, duration, reset, mixin( prop ) );
    }

    // apply the effect now
    mixin( prop ) -= diff;
  }

  /// Use an effect stored in the unit
  @ignore
  void reEffect( string prop )( int diff, int duration, bool reset, int originalValue )
  {
    mixin( prop ) -= diff;
    duration--;

    // check if the ability has run its course
    if( duration <= 0 )
    {
      if( reset )
        mixin( prop ) = originalValue;
    }
  }

  /// Move the unit to a tile
  void move( uint targetTileID )
  {
    if( checkMove( targetTileID ) )
    {
      // easy names for the tiles
      auto curTile = Game.grid.getTileByID( position );
      auto targetTile = Game.grid.getTileByID( targetTileID );

      // change the tile types
      curTile.type = TileType.Open;
      targetTile.type = TileType.OccupantActive;

      // Rotate the unit to face the direction he moved
      //Down
      transform.rotation = quat.euler_rotation( 0, 0, 0 );
      // Up
      if( curTile.y > targetTile.y )
        transform.rotation = quat.euler_rotation( 180.radians, 0, 0 );
      // Left
      else if( curTile.x > targetTile.x )
        transform.rotation = quat.euler_rotation( 270.radians, 0, 0 );
      // Right
      else if( curTile.x < targetTile.x )
        transform.rotation = quat.euler_rotation( 90.radians, 0, 0 );

      // scale the tile back down
      curTile.transform.scale = vec3( TILE_SIZE / 2 );

      // change the tile occupants
      curTile.occupant = null;
      targetTile.occupant = this;

      // move the unit to the new location
      position = targetTileID;
      updatePosition();
      deselect();
      Game.grid.isUnitSelected = false;

      // decrement remaining actions and distance
      actionUsed();
      remainingRange -= abs( ( targetTile.x - curTile.x ) ) + abs ( ( targetTile.y - curTile.y ) );

      // update fog of war
      Game.grid.updateFogOfWar();

      // check if the turn is over
      Game.turn.checkTurnOver();
    }
  }

  /// Check if the move is allowed
  bool checkMove( uint targetTileID )
  {
    auto tile = Game.grid.getTileByID( targetTileID );

    // get the distance away from the unit's current position
    uint distance = abs( ( tile.x - x ) ) + abs ( ( tile.y - y ) );

    // Check speed, actions, and tileType
    return remainingRange >= distance && remainingActions > 0 && tile.type == TileType.Open;
  }

  /// Highlight the tiles the unit can move to
  void previewMove()
  {
    selectedTiles = Game.grid.getInRange( position, remainingRange );

    Game.level.ui.callJSFunction( "selectCharacter", [ ID ] );

    // change the material of the tiles
    foreach( tile; selectedTiles )
    {
      tile.selection = TileSelection.Blue;

      // animate the tile
      /*auto startTime = Time.totalTime;
      auto dur = 100.msecs;
      scheduleTimedTask( dur,
      {
        tile.transform.scale =
          interp( vec3( 0 ), vec3( TILE_SIZE / 2 ),
                 ( Time.totalTime - startTime ) / dur.toSeconds );
      } );*/
    }

    // only run this if a unit isn't already selected
    if( !Game.grid.isUnitSelected )
    {
      // update the grid
      Game.grid.isUnitSelected = true;
      Game.grid.selectedUnit = this;

      // automatically select the first ability
      Game.grid.selectAbility( 0 );
    }
  }

  /// Remove focus from the unit and any highlighted tiles
  void deselect()
  {
    // change the material of the tiles
    foreach( tile; selectedTiles )
    {
      tile.resetSelection();
    }

    // scale the tile back down
    Game.grid.getTileByID( position ).transform.scale = vec3( TILE_SIZE / 2 );

    // Modify grid variables
    Game.grid.selectedUnit = null;
    Game.grid.isUnitSelected = false;

    // deselect the ability if there was one
    if ( Game.grid.isAbilitySelected )
      Game.abilities[ Game.grid.selectedAbility ].unpreview();

    info( "Deselected ", name, ", ", remainingActions, " action(s) remaining." );
  }

  /// Decrement remaining actions
  bool actionUsed( int numActions = 1 )
  {
    remainingActions -= numActions;
    if( remainingActions <= 0 )
    {
      Game.grid.getTileByID( position ).type = TileType.OccupantInactive;
      Game.turn.checkTurnOver();
    }
    deselect();
    return true;
  }

  /// Prep the unit to begin a turn anew
  void newTurn()
  {
    // reset action and range
    remainingActions = ACTIONS_RESET;
    remainingRange = speed;
    Game.grid.getTileByID( position ).type = TileType.OccupantActive;

    // apply active effects (reversed to allow for deletions)
    foreach_reverse( effect; activeEffects )
    {
      effect.use( this );
    }

    // decrement cooldown on abilities
    foreach( ability; abilities )
    {
      Game.abilities[ ability ].decrementCooldown();
    }
  }

  /// Convert grid coordinates to 3D space
  void updatePosition()
  {
    this.transform.position.x = this.x * TILE_SIZE;
    this.transform.position.z = this.y * TILE_SIZE;
    if (hp > 0) this.transform.position.y = this.z;
  }

  override void update()
  {
    // on death
    if( hp <= 0 )
    {
      hp = maxHP;

      // set the current tile to default state
      Tile curTile = Game.grid.getTileByID( position );
      curTile.type( TileType.Open );
      curTile.selection( TileSelection.None );
      curTile.occupant = null;

      // fall through the floor animation
      auto startTime = Time.totalTime;
      auto dur = 500.msecs;
      float initZ = this.transform.position.y; float finalZ = initZ - 40;
      scheduleTimedTask( dur,
      {
        this.transform.position.y =
          interp( initZ, finalZ,
                 ( Time.totalTime - startTime ) / dur.toSeconds );
      } );

      // wait till the fall animation is over
      scheduleDelayedTask( dur,
      {
        // tell the turn counter to give the other team a point
        if (team == Team.Robot) {
          Game.turnCounter.wolfKills++;
          info("Team Wolf Kills Now: ", Game.turnCounter.wolfKills);
        } else {
          Game.turnCounter.robotKills++;
          info("Team Robot Kills Now: ", Game.turnCounter.robotKills);
        }

        // respawn
        if( Game.gameMode == GameMode.Deathmatch )
        {
          position = spawnPoint;
          updatePosition();
          //this.transform.position.y = finalZ;

          curTile = Game.grid.getTileByID(position);
          curTile.type( TileType.OccupantInactive );
          curTile.selection( TileSelection.Black );
          curTile.occupant = this;

          // rise like Jesus
          auto newStartTime = Time.totalTime;
          scheduleTimedTask( dur,
          {
            this.transform.position.y =
              interp( finalZ, initZ,
                     ( Time.totalTime - newStartTime ) / dur.toSeconds );
          } );
        }

        // die
        else
        {
          // get index of unit in Game.units
          int idx;
          for( int i = 0; i < Game.units.length; i++ )
          {
            if( Game.units[ i ] == this )
            {
              idx = i;
            }
          }

          // slice unit outside of game.units
          Game.units = Game.units[ 0..idx ]~Game.units[ idx+1..Game.units.length ];

          // remove from level
          Game.level.removeChild( this.parent );

          hp = 0;
        }
      } );

    }

  }
}
