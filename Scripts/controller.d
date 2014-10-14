module controller;
import unit, grid, ability, tile, game, turn;
import dash.core, dash.utility;
import yaml;
import std.path, std.conv;
import gl3n.linalg, gl3n.math;

final class Controller
{
	struct unitInfo
	{
		string Name;
		int[] Spawn;
		@rename("Team")
		Team team;
		vec3 Rotation;
	}

	struct propInfo
	{
		int[] Location;
		int height;
		int[] tileSize;
		string name, prefab, ttype;
		@rename("TileType")
		TileType tileType;
		vec3 rotationVec;
		quat rotation;
	}

	struct levelInfo
	{
		string Name;
		@rename("Grid")
		int[] gridSize;
		bool FogOfWar;
		unitInfo[] units;
		propInfo[] props;
	}

	this()
	{
		// first load all the objects
		Game.level.loadObjects( "Base" );

		// load the game
		loadLevel( "levelSRTF" ); //TODO: Remove hardcoded value

		logInfo( Game.units.length, " units loaded." );
	}

	/// Load and create abilities from yaml
	///
	/// Returns: a list of the IDs created
	uint[] loadAbilities( string abilitiesFile )
	{
		uint[] abilityIDs;

		struct abilityInfo
		{
			string name;
			TargetType targetType;
			TargetArea targetArea;
			int range;
			int damage;
		}

		// load the yaml
		abilityInfo[] ability = deserializeMultiFile!abilityInfo( Resources.Objects ~ "/Abilities/" ~ abilitiesFile )[0];

		/*foreach( Node abilityNode; yaml )
		{
			auto ability = abilityNode.getObject!(Ability)();
			Game.abilities[ ability.ID ] = ability;
			abilityIDs ~= ability.ID;
		}*/

		return abilityIDs;
	}

	/// Load and create units from yaml
	void loadUnits( unitInfo[] unitsToLoad )
	{
		// So we are going to parse the Units folder for the unit files
		// For those, we'll get the Name of the node, which will be how we call into the gameObjects
		foreach( Node unitNode; unitsToLoad )
		{
			// setup variables
			int hp, sp, at, df = 0;
			Team team;
			string abilities, teamName;
			uint[] spawn;
			vec3 rotationVec;
			quat rotation;

			/*foreach( Node unitCheck; loadYamlDocuments( buildNormalizedPath( Resources.Objects, "Units" ) ) )
			{
				// check if we want to load this unit
				if( unitNode[ "Name" ].as!string == unitCheck[ "Name" ].as!string )
				{
					unitNode.tryFind( "Spawn", spawn );
					if( unitNode.tryFind( "Team", teamName ) )
						team = to!Team( teamName );
						// validate team
					if( unitNode.tryFind( "Rotation", rotationVec ) )
						rotation = quat.euler_rotation( radians( rotationVec.y ), radians( rotationVec.z ), radians( rotationVec.x ) );

					// validate spawn position
					if (spawn[0] > Game.grid.gridX || spawn[1] > Game.grid.gridY) {
						logInfo("Unit '", unitNode["Name"].as!string, "' is not within the grid and therefore not built.");
						break;
					}

					// instantiate the prefab of a unit
					auto u = Prefabs[ unitCheck[ "Prefab" ].as!string ].createInstance();
					auto unit = u.getComponent!Unit;

					// get the variables from the node
					unitCheck.tryFind( "HP", hp );
					unitCheck.tryFind( "Speed", sp );
					unitCheck.tryFind( "Attack", at );
					unitCheck.tryFind( "Defense", df );
					unitCheck.tryFind( "Abilities", abilities );

					// initialize the unit and add it to the active scene
					unit.init( toTileID( spawn [ 0 ], spawn[ 1 ] ), team, hp, sp, at, df, loadAbilities( abilities ) );
					if ( rotation )
						unit.transform.rotation = rotation;
					Game.level.addChild( u );
					Game.units ~= unit;

					// block and occupy the spawn tile
					Game.grid.tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].occupant = unit;
					Game.grid.tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].type = TileType.OccupantActive;
					break;
				}
			}*/
		}
	}

	/// Convert ( x, y ) coordinates to an ID
	uint toTileID( uint x, uint y )
	{
		return x + ( y * Game.grid.gridX );
	}

	/// Load and create a level from yaml
	void loadLevel( string levelName )
	{
		// load the level from yaml
		levelInfo level = deserializeFileByName!levelInfo( Resources.Objects ~ "/Levels/" ~ levelName )[0];

		// fill the grid
		Game.grid.initTiles( level.gridSize[ 0 ], level.gridSize[ 1 ] );

		// add props to the scene
		foreach( propInfo p; level.props )
		{
			// get the variables from the node
			if ( !p.prefab )
			{
				for( int x = p.Location[ 0 ]; x <= p.Location[ 2 ]; x++ )
				{
					for( int y = p.Location[ 1 ]; y <= p.Location[ 3 ]; y++ )
					{
						Game.grid.getTileByID( toTileID( x, y ) ).z = p.height;
						logInfo( x, ", ", y );
					}
				}
			}
			else
			{
				// make an object
				if( p.rotationVec )
					p.rotation = quat.euler_rotation( radians( p.rotationVec.y ), radians( p.rotationVec.z ), radians(p. rotationVec.x ) );

				// check that the tile size and location are compatible
				if( p.Location.length > 2 )
				{
					if( p.tileSize[ 0 ] > 1 )
					{
						if( ( p.Location[ 2 ] - p.Location[ 0 ] + 1 ) % ( p.tileSize[ 0 ] ) != 0 )
						{
							logInfo( "Object at location ", p.Location, " has improper location for tile size along the x-axis. Object building aborted." );
							break;
						}
					}
					else if( p.tileSize[ 1 ] > 1 )
					{
						if( ( p.Location[ 3 ] - p.Location[ 1 ] + 1 ) % ( p.tileSize[ 1 ] ) != 0 )
						{
							logInfo( "Object at location ", p.Location, " has improper location for tile size along the y-axis. Object building aborted." );
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

				// create a p on each tile it occupies
				for( int x = p.Location[ 0 ]; x <= p.Location[ 2 ]; x += p.tileSize[ 0 ] )
				{
					for( int y = p.Location[ 1 ]; y <= p.Location[ 3 ]; y += p.tileSize[ 1 ] )
					{
						// instantiate the prefab of a prop
						auto prop = Prefabs[ p.prefab ].createInstance();

						// make the name unique
						prop.name = p.prefab ~ " ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";

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
		loadUnits( level.units );

		// do some fog of war
		Game.grid.fogOfWar = level.FogOfWar;
		Game.grid.updateFogOfWar();
	}
}
