module controller;
import unit, ability, grid, turn, tile, game;
import core, utility;
import yaml;
import std.path, std.conv;
import gl3n.linalg, gl3n.math;

final shared class Controller
{
public:
	Scene level; // The active scene in the engine
	Turn turn; // The turn controller
	
	this()
	{
		level = new shared Scene();
		turn = new shared Turn();
		Game.activeScene = level;
		
		// first load all the objects
		level.loadObjects( "Base" );
		
		// load the game
		loadLevel( "levelSRTF" ); //TODO: Remove hardcoded value
	}
	
	/// Load and create abilities from yaml
	/// 
	/// Returns: a list of the IDs created
	uint[] loadAbilities( string abilitiesFile )
	{
		uint[] abilityIDs;

		// load the yaml
		auto yaml = Loader( findInDirectory ( "Abilities", abilitiesFile ) );

		foreach( Node abilityNode; yaml )
		{
			auto ability = Config.getObject!(shared Ability)( abilityNode );
			turn.abilities[ ability.ID ] = ability;
			abilityIDs ~= ability.ID;
		}

		return abilityIDs;
	}
	
	/// Load and create units from yaml
	void loadUnits( Node unitsToLoad )
	{
		// So we are going to parse the Units folder for the unit files
		// For those, we'll get the Name of the node, which will be how we call into the gameObjects
		foreach( unitNode; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, "Units" ) ) )
		{
			// setup variables
			int team, hp, sp, at, df = 0;
			string abilities;
			uint[] spawn;
			
			// check if we want to load this unit
			bool nameCheck = false;
			foreach( Node unitCheck; unitsToLoad )
			{
				if( unitNode[ "Name" ].as!string == unitCheck[ "Name" ].as!string )
				{
					nameCheck = true;
					Config.tryGet( "Spawn", spawn, unitCheck );
					Config.tryGet( "Team", team, unitCheck );
					break;
				}
			}
			if( !nameCheck ) continue;
			
			// instantiate the prefab of a unit
			string[ shared GameObject ] parents;
			string[][ shared GameObject ] children;
			auto unit = cast(shared Unit)Prefabs[ unitNode[ "Prefab" ].as!string ].createInstance( parents, children );
			
			// get the variables from the node
			unit.name = unitNode[ "Name" ].as!string;
			Config.tryGet( "HP", hp, unitNode );
			Config.tryGet( "Speed", sp, unitNode );
			Config.tryGet( "Attack", at, unitNode );
			Config.tryGet( "Defense", df, unitNode );
			Config.tryGet( "Abilities", abilities, unitNode );
			
			// initialize the unit and add it to the active scene
			unit.init( toTileID( spawn [ 0 ], spawn[ 1 ] ), 
			           ( cast(shared Grid)level[ "Grid" ] ).gridX, 
			           team, hp, sp, at, df, 
			           loadAbilities( abilities ) );
			level.addChild( unit );
			( cast(shared Grid)level[ "Grid" ] ).tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].type = TileType.HalfBlocked;
		}
	}

	/// Convert ( x, y ) coordinates to an ID
	uint toTileID( uint x, uint y )
	{
		return x + ( y * ( cast(shared Grid)level[ "Grid" ] ).gridX );
	}
	
	/// Return the file path for a level to load
	string findInDirectory( string directory, string fileName )
	{
		foreach( file; FilePath.scanDirectory( buildNormalizedPath( FilePath.Resources.Objects, directory ), "*.yml" ) )
		{
			if( file.baseFileName() == fileName )
			{
				return file.fullPath();
			}
			
			//TODO: Handle yaml not existing
		}

		return null;
	}
	
	/// Load and create a level from yaml
	void loadLevel( string levelName )
	{
		// load the level from yaml
		Node levelNode = loadYamlFile( findInDirectory ( "Levels", levelName ) );
		
		// setup variables
		int[] gridSize;
		Node unitsNode;
		Node propsNode;
		
		// get the variables from the yaml node
		string name = levelNode[ "Name" ].as!string;
		Config.tryGet( "Grid", gridSize, levelNode );
		Config.tryGet( "Units", unitsNode, levelNode );
		Config.tryGet( "Objects", propsNode, levelNode );
		
		// create the grid
		auto grid = new shared Grid();
		grid.name = "Grid";
		level.addChild( grid );
		grid.initTiles( gridSize[ 0 ], gridSize[ 1 ] );
		
		// create the units
		loadUnits( unitsNode );
		
		// add props to the scene
		foreach( Node propNode; propsNode )
		{
			// setup variables
			int[] loc;
			string name, prefab, ttype;
			TileType tileType;
			shared vec3 rotationVec;
			shared quat rotation;
			
			// get the variables from the node
			Config.tryGet( "Location", loc, propNode );
			Config.tryGet( "Prefab", prefab, propNode );
			if( Config.tryGet( "TileType", ttype, propNode ) )
				tileType = to!TileType( ttype );
			if( Config.tryGet( "Rotation", rotationVec, propNode ) )
				rotation = quat.euler_rotation( radians( rotationVec.y ), radians( rotationVec.z ), radians( rotationVec.x ) );
			
			// fix up single-tile props for the double for-loop
			if ( loc.length == 2 )
			{
				loc ~= loc[ 0 ];
				loc ~= loc[ 1 ];
			}
			
			// create a prop on each tile it occupies
			for( int x = loc[ 0 ]; x <= loc[ 2 ]; x++ )
			{
				for( int y = loc[ 1 ]; y <= loc[ 3 ]; y++ )
				{
					// instantiate the prefab of a prop
					string[ shared GameObject ] parents;
					string[][ shared GameObject ] children;
					auto prop = Prefabs[ prefab ].createInstance( parents, children );
					
					// make the name unique
					prop.name = prefab ~ x.to!string ~ "-" ~ y.to!string;
					
					// place the prop
					prop.transform.position.x = x * TILE_SIZE;
					prop.transform.position.z = y * TILE_SIZE;
					if( rotation )
						prop.transform.rotation = rotation;
					
					// add the prop to the scene
					level.addChild( prop );
					
					// change the TileType of occupying tiles
					grid.tiles[ x ][ y ].type = tileType;
				}
			}
		}
	}
}
