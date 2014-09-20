module controller;
import unit, grid, ability, tile, game, turn;
import dash.core, dash.utility;
import yaml;
import std.path, std.conv;
import gl3n.linalg, gl3n.math;

final class Controller
{
	this( string level, string gameMode )
	{
		// first load all the objects
		Game.level.loadObjects( "Base" );

		// load the game
		loadLevel( level, gameMode );

		logInfo( Game.units.length, " units loaded." );
	}

	/// Load and create abilities from yaml
	///
	/// Returns: a list of the IDs created
	uint[] loadAbilities( string abilitiesFile )
	{
		uint[] abilityIDs;

		// load the yaml
		auto yaml = loadAllDocumentsInYamlFile( Resources.Objects ~ "/Abilities/" ~ abilitiesFile ~ ".yml" );

		foreach( Node abilityNode; yaml )
		{
			auto ability = abilityNode.getObject!(Ability)();
			Game.abilities[ ability.ID ] = ability;
			abilityIDs ~= ability.ID;
		}

		return abilityIDs;
	}

	/// Load and create units from yaml
	void loadUnits( Node unitsToLoad )
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

			foreach( Node unitCheck; loadYamlDocuments( buildNormalizedPath( Resources.Objects, "Units" ) ) )
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
			}
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
		Node levelNode = loadYamlFile( Resources.Objects ~ "/Levels/" ~ levelName ~ ".yml" );

		// setup variables
		int[] gridSize;
		bool fogOfWar;
		Node gameModeNode;
		Node unitsNode;
		Node propsNode;

		// get the variables from the yaml node
		string name = levelNode[ "Name" ].as!string;
		levelNode.tryFind( "Grid", gridSize );
		levelNode.tryFind( "GameModes", gameModeNode );
		levelNode.tryFind( "Objects", propsNode );

		// fill the grid
		Game.grid.initTiles( gridSize[ 0 ], gridSize[ 1 ] );

		// Load the game mode
		Node currentGameMode;
		gameModeNode.tryFind( gameMode, currentGameMode );

		// get the fog of war and the units for the current game mode
		currentGameMode.tryFind( "FogOfWar", fogOfWar );
		currentGameMode.tryFind( "Units", unitsNode );

		// add props to the scene
		foreach( Node propNode; propsNode )
		{
			// setup variables
			int[] loc;
			int height;
			int[] tileSize;
			string name, prefab, ttype;
			TileType tileType;
			vec3 rotationVec;
			quat rotation;

			// get the variables from the node
			propNode.tryFind( "Location", loc );
			if (!propNode.tryFind( "Prefab", prefab )) {
				// define the height of some tiles
				propNode.tryFind("Height", height);
				
				for (int x = loc[0]; x <= loc[2]; x++) {
					for (int y = loc[1]; y <= loc[3]; y++) {
						Game.grid.getTileByID(toTileID(x, y)).z = height;
						logInfo(x, ", ", y);
					}
				}
			} else {
				// make an object
				propNode.tryFind( "TileSize", tileSize );
				if( propNode.tryFind( "TileType", ttype ) )
					tileType = to!TileType( ttype );
				if( propNode.tryFind( "Rotation", rotationVec ) )
					rotation = quat.euler_rotation( radians( rotationVec.y ), radians( rotationVec.z ), radians( rotationVec.x ) );
					
				// check that the tile size and location are compatible
				if (loc.length > 2) {
					if (tileSize[0] > 1) {
						if ((loc[2] - loc[0] + 1) % (tileSize[0]) != 0) {
							logInfo("Object at location ", loc, " has improper location for tile size along the x-axis.  Object building aborted.");
							break;
						}
					} else if (tileSize[1] > 1) {
						if ((loc[3] - loc[1] + 1) % (tileSize[1]) != 0) {
							logInfo("Object at location ", loc, " has improper location for tile size along the y-axis.  Object building aborted.");
							break;
						}
					}
				}

				// fix up single-tile props for the double for-loop
				if ( loc.length == 2 )
				{
					loc ~= loc[ 0 ];
					loc ~= loc[ 1 ];
				}

				// default values for tileSize if not in the yaml
				if ( !tileSize )
					tileSize = [ 1, 1 ];

				// create a prop on each tile it occupies
				for( int x = loc[ 0 ]; x <= loc[ 2 ]; x += tileSize[ 0 ] )
				{
					for( int y = loc[ 1 ]; y <= loc[ 3 ]; y += tileSize[ 1 ] )
					{
						// instantiate the prefab of a prop
						auto prop = Prefabs[ prefab ].createInstance();

						// make the name unique
						prop.name = prefab ~ " ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";

						// place the prop
						if( tileSize[ 0 ] % 2 == 0 )
							prop.transform.position.x = x * TILE_SIZE + ( tileSize[ 0 ] / 2 * TILE_SIZE / 2 );
						else
							prop.transform.position.x = x * TILE_SIZE + ( tileSize[ 0 ] / 2 * TILE_SIZE );

						if( tileSize[ 1 ] % 2 == 0 )
							prop.transform.position.z = y * TILE_SIZE + ( tileSize[ 1 ] / 2 * TILE_SIZE / 2 );
						else
							prop.transform.position.z = y * TILE_SIZE + ( tileSize[ 1 ] / 2 * TILE_SIZE );
							
						prop.transform.position.y = Game.grid.getTileByID(toTileID(x, y)).z;

						if( rotation )
							prop.transform.rotation = rotation;

						// add the prop to the scene
						Game.level.addChild( prop );

						// change the TileType of occupying tiles
						for ( int xx = x; xx < x + tileSize[ 0 ]; xx++ )
							for ( int yy = y; yy < y + tileSize[ 1 ]; yy++ )
								Game.grid.tiles[ xx ][ yy ].type = tileType;
					}
				}
			}
		}
		
		// create the units
		loadUnits( unitsNode );

		// do some fog of war
		Game.grid.fogOfWar = fogOfWar;
		Game.grid.updateFogOfWar();
	}
}
