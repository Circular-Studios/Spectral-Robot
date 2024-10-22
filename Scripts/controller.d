﻿module controller;
import unit, grid, ability, tile, game, turn;
import dash.core, dash.utility, dash.components;
import gl3n.linalg, gl3n.math;

final class Controller
{
  struct UnitInfo
  {
    string Class;
    int[] Spawn;
    @rename( "Team" ) @byName
    Team team;
    @rename( "Rotation" ) @optional
    float[] rotationVec;
  }

  struct ClassInfo
  {
    string Name;
    string Abilities;
    string Prefab;
    @ignore
    quat rotation;
    int HP;
    int Speed;
  }

  struct PropInfo
  {
    int[] Location;
    @rename( "Height" ) @optional
    int height;
    @rename( "TileSize" ) @optional
    int[] tileSize;
    @ignore
    string name, ttype;
    @rename( "Prefab" )
    string prefab;
    @rename( "TileType" ) @byName
    TileType tileType;
    @rename( "Rotation" ) @optional
    float[] rotationVec;
    @ignore
    quat rotation;
  }

  struct LevelInfo
  {
    @rename( "Name" )
    string name;
    @rename("Grid")
    int[] gridSize;
    @rename( "Objects" )
    PropInfo[] props;
    @rename( "GameModes" )
    GameModeInfo[] gameModes;
  }

  struct AbilityInfo
  {
    string name;
    @byName
    TargetType targetType;
    @byName
    TargetArea targetArea;
    int range;
    int damage;
    @optional
    int cooldown = 0;
    int accuracy;
  }

  struct GameModeInfo
  {
    @rename( "Name" )
    string name;
    @rename( "FogOfWar" ) @optional
    bool fogOfWar;
    @rename( "Units" )
    UnitInfo[] units;
    @rename( "RobotCamera" )
    CameraInfo robotCamera;
    @rename( "CriminalCamera" )
    CameraInfo criminalCamera;
  }

  struct CameraInfo
  {
    @rename( "Position" )
    float[] position;
    @rename( "Rotation" )
    float[] rotation;
  }

  this( string level, string gameMode )
  {
    // first load all the objects
    Game.level.loadObjects( "Base" );

    // load the game
    loadLevel( level, gameMode );

    info( Game.units.length, " units loaded." );
  }

  /// Load and create abilities from yaml
  ///
  /// Returns: a list of the IDs created
  uint[] loadAbilities( string abilitiesFile )
  {
    uint[] abilityIDs;

    // load the yaml
    Resource file = Resource( Resources.Objects ~ "/Abilities/" ~ abilitiesFile ~ ".yml" );
    AbilityInfo[] abilities = deserializeMultiFile!AbilityInfo( file );

    foreach( AbilityInfo abInfo; abilities )
    {
      Ability ability = new Ability();
      ability.name = abInfo.name;
      ability.damage = abInfo.damage;
      ability.range = abInfo.range;
      ability.cooldown = abInfo.cooldown;
      ability.accuracy = abInfo.accuracy;
      ability.targetType = abInfo.targetType;
      ability.targetArea = abInfo.targetArea;

      Game.abilities[ ability.ID ] = ability;
      abilityIDs ~= ability.ID;
    }

    return abilityIDs;
  }

  /// Load and create units from yaml
  void loadUnits( UnitInfo[] unitsToLoad )
  {
    foreach( UnitInfo unitNode; unitsToLoad )
    {
      // this might break depending on how structs override information
      ClassInfo classNode = deserializeFileByName!ClassInfo( Resources.Objects ~ "/Classes/" ~ unitNode.team.to!string ~ "/" ~ unitNode.Class )[ 0 ];

      if( unitNode.rotationVec )
        classNode.rotation = fromEulerAngles( unitNode.rotationVec );

      // validate spawn position
      if ( unitNode.Spawn[ 0 ] < 0 ||
         unitNode.Spawn[ 1 ] < 0 ||
         unitNode.Spawn[ 0 ] > Game.grid.gridX ||
         unitNode.Spawn[ 1 ] > Game.grid.gridY )
      {
        error( "Unit '", unitNode.Class, "' is not within the grid. Fix its position." );
      }

      // instantiate the prefab of a unit
      auto u = Prefabs[ classNode.Prefab ].createInstance();
      auto unit = new Unit();
      u.addComponent( unit );

      // initialize the unit and add it to the active scene
      unit.initialize( toTileID( unitNode.Spawn[ 0 ], unitNode.Spawn[ 1 ] ), unitNode.team, classNode.HP, classNode.Speed, loadAbilities( classNode.Abilities ) );
      if ( classNode.rotation )
        unit.transform.rotation = classNode.rotation;
      Game.level.addChild( u );
      Game.units ~= unit;

      // block and occupy the spawn tile
      Game.grid.tiles[ unitNode.Spawn[ 0 ] ][ unitNode.Spawn[ 1 ] ].occupant = unit;
      Game.grid.tiles[ unitNode.Spawn[ 0 ] ][ unitNode.Spawn[ 1 ] ].type = TileType.OccupantActive;
    }
  }

  /// Convert ( x, y ) coordinates to an ID
  uint toTileID( uint x, uint y )
  {
    return x + ( y * Game.grid.gridX );
  }

  /// Load and create a level from yaml
  void loadLevel( string levelName, string gameMode )
  {
    // load the level from yaml
    LevelInfo level = deserializeFileByName!LevelInfo( Resources.Objects ~ "/Levels/" ~ levelName )[ 0 ];

    // fill the grid
    Game.grid.initTiles( level.gridSize[ 0 ], level.gridSize[ 1 ] );

    // set up the gamemode
    int activeMode = -1;
    foreach( int i, GameModeInfo gm; level.gameModes )
    {
      if ( gm.name == gameMode )
      {
        activeMode = i;
        break;
      }
    }
    if( activeMode == -1 )
      error( "Gamemode ", gameMode, " is not defined in the level ", level.name );

    // set starting camera positions
    Game.turn.setInitCamPos(
      level.gameModes[ activeMode ].robotCamera.position,
      level.gameModes[ activeMode ].robotCamera.rotation,
      level.gameModes[ activeMode ].criminalCamera.position,
      level.gameModes[ activeMode ].criminalCamera.rotation );

    // add props to the scene
    foreach( PropInfo p; level.props )
    {
      // get the variables from the node
      if ( !p.prefab )
      {
        for( int x = p.Location[ 0 ]; x <= p.Location[ 2 ]; x++ )
        {
          for( int y = p.Location[ 1 ]; y <= p.Location[ 3 ]; y++ )
          {
            Game.grid.getTileByID( toTileID( x, y ) ).z = p.height;
            info( x, ", ", y );
          }
        }
      }
      else
      {
        // make an object
        if( p.rotationVec )
          p.rotation = fromEulerAngles( p.rotationVec );

        // check that the tile size and location are compatible
        if( p.Location.length > 2 )
        {
          if( p.tileSize[ 0 ] > 1 )
          {
            if( ( p.Location[ 2 ] - p.Location[ 0 ] + 1 ) % ( p.tileSize[ 0 ] ) != 0 )
            {
              info( "Object at location ", p.Location, " has improper location for tile size along the x-axis. Object building aborted." );
              break;
            }
          }
          else if( p.tileSize[ 1 ] > 1 )
          {
            if( ( p.Location[ 3 ] - p.Location[ 1 ] + 1 ) % ( p.tileSize[ 1 ] ) != 0 )
            {
              info( "Object at location ", p.Location, " has improper location for tile size along the y-axis. Object building aborted." );
              break;
            }
          }
        }

        // fix up single-tile props for the double for-loop
        if ( p.Location.length == 2 )
        {
          p.Location ~= p.Location[ 0 ];
          p.Location ~= p.Location[ 1 ];
        }

        // default values for tileSize if not in the yaml
        if ( !p.tileSize )
          p.tileSize = [ 1, 1 ];

        // create a prop on each tile it occupies
        for( int x = p.Location[ 0 ]; x <= p.Location[ 2 ]; x += p.tileSize[ 0 ] )
        {
          for( int y = p.Location[ 1 ]; y <= p.Location[ 3 ]; y += p.tileSize[ 1 ] )
          {
            // instantiate the prefab of a prop
            GameObject.Description desc;
            desc.prefab = Prefabs[ p.prefab ];
            desc.name = desc.prefab.name ~ " ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";
            auto prop = GameObject.create( desc );

            // place the prop
            if( p.tileSize[ 0 ] % 2 == 0 )
              prop.transform.position.x = x * TILE_SIZE + ( p.tileSize[ 0 ] / 2 * TILE_SIZE / 2 );
            else
              prop.transform.position.x = x * TILE_SIZE + ( p.tileSize[ 0 ] / 2 * TILE_SIZE );

            if( p.tileSize[ 1 ] % 2 == 0 )
              prop.transform.position.z = y * TILE_SIZE + ( p.tileSize[ 1 ] / 2 * TILE_SIZE / 2 );
            else
              prop.transform.position.z = y * TILE_SIZE + ( p.tileSize[ 1 ] / 2 * TILE_SIZE );

            prop.transform.position.y = Game.grid.getTileByID( toTileID( x, y ) ).z;

            if( p.rotation )
              prop.transform.rotation = p.rotation;

            // add the prop to the scene
            Game.level.addChild( prop );

            // change the TileType of occupying tiles
            for ( int xx = x; xx < x + p.tileSize[ 0 ]; xx++ )
              for ( int yy = y; yy < y + p.tileSize[ 1 ]; yy++ )
                Game.grid.tiles[ xx ][ yy ].type = p.tileType;
          }
        }
      }
    }

    // create the units
    loadUnits( level.gameModes[ activeMode ].units );

    // do some fog of war
    Game.grid.fogOfWar = level.gameModes[ activeMode ].fogOfWar;
    Game.grid.updateFogOfWar();
  }
}
