module controller;
import unit, grid, ability, tile, game, turn;
import core, utility;
import yaml;
import std.path, std.conv;
import gl3n.linalg, gl3n.math;

final shared class Controller
{
	this()
	{
		// first load all the objects
		Game.level.loadObjects( "Base" );
		
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
		foreach( unitNode; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, "Units" ) ) )
		{
			// setup variables
			int hp, sp, at, df = 0;
			Team team;
			string abilities, teamName;
			uint[] spawn;
			shared vec3 rotationVec;
			shared quat rotation;
			
			// check if we want to load this unit
			bool nameCheck = false;
			foreach( Node unitCheck; unitsToLoad )
			{
				if( unitNode[ "Name" ].as!string == unitCheck[ "Name" ].as!string )
				{
					nameCheck = true;
					Config.tryGet( "Spawn", spawn, unitCheck );
					if( Config.tryGet( "Team", teamName, unitCheck ) )
						team = to!Team( teamName );
					if( Config.tryGet( "Rotation", rotationVec, unitCheck ) )
						rotation = quat.euler_rotation( radians( rotationVec.y ), radians( rotationVec.z ), radians( rotationVec.x ) );
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
			unit.init( toTileID( spawn [ 0 ], spawn[ 1 ] ), team, hp, sp, at, df, loadAbilities( abilities ) );
			if ( rotation )
				unit.transform.rotation = rotation;
			Game.level.addChild( unit );
			Game.units ~= unit;
			
			// block and occupy the spawn tile
			Game.grid.tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].type = TileType.HalfBlocked;
			Game.grid.tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].occupant = unit;
		}
	}
	
	/// Convert ( x, y ) coordinates to an ID
	uint toTileID( uint x, uint y )
	{
		return x + ( y * Game.grid.gridX );
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
		
		// fill the grid
		Game.grid.initTiles( gridSize[ 0 ], gridSize[ 1 ] );
		
		// create the units
		loadUnits( unitsNode );
		
		// add props to the scene
		foreach( Node propNode; propsNode )
		{
			// setup variables
			int[] loc;
			int[] tileSize;
			string name, prefab, ttype;
			TileType tileType;
			shared vec3 rotationVec;
			shared quat rotation;
			
			// get the variables from the node
			Config.tryGet( "Location", loc, propNode );
			Config.tryGet( "Prefab", prefab, propNode );
			Config.tryGet( "TileSize", tileSize, propNode );
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
			
			// default values for tileSize if not in the yaml
			if ( !tileSize )
				tileSize = [ 1, 1 ];
			
			// create a prop on each tile it occupies
			for( int x = loc[ 0 ]; x <= loc[ 2 ]; x += tileSize[ 0 ] )
			{
				for( int y = loc[ 1 ]; y <= loc[ 3 ]; y += tileSize[ 1 ] )
				{
					// instantiate the prefab of a prop
					string[ shared GameObject ] parents;
					string[][ shared GameObject ] children;
					auto prop = Prefabs[ prefab ].createInstance( parents, children );
					
					// make the name unique
					prop.name = prefab ~ " ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";
					
					// place the prop
					prop.transform.position.x = x * TILE_SIZE + ( tileSize[ 0 ] - 1 ) * 0.5;
					prop.transform.position.z = y * TILE_SIZE + ( tileSize[ 1 ] - 1 ) * 0.5;
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
}
