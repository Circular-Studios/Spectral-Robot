module controller;
import unit, grid, ability, tile, game, turn;
import dash.core, dash.utility;
import yaml;
import std.path, std.conv;
import gl3n.linalg, gl3n.math;

final class Controller
{
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
					if( unitNode.tryFind( "Rotation", rotationVec ) )
						rotation = quat.euler_rotation( radians( rotationVec.y ), radians( rotationVec.z ), radians( rotationVec.x ) );

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
	void loadLevel( string levelName )
	{
		// load the level from yaml
		Node levelNode = loadYamlFile( Resources.Objects ~ "/Levels/" ~ levelName ~ ".yml" );

		// setup variables
		int[] gridSize;
		bool fogOfWar;
		Node unitsNode;
		Node propsNode;

		// get the variables from the yaml node
		string name = levelNode[ "Name" ].as!string;
		levelNode.tryFind( "Grid", gridSize );
		levelNode.tryFind( "FogOfWar", fogOfWar );
		levelNode.tryFind( "Units", unitsNode );
		levelNode.tryFind( "Objects", propsNode );

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
			vec3 rotationVec;
			quat rotation;

			// get the variables from the node
			propNode.tryFind( "Location", loc );
			propNode.tryFind( "Prefab", prefab );
			propNode.tryFind( "TileSize", tileSize );
			if( propNode.tryFind( "TileType", ttype ) )
				tileType = to!TileType( ttype );
			if( propNode.tryFind( "Rotation", rotationVec ) )
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

		// do some fog of war
		Game.grid.fogOfWar = fogOfWar;
		Game.grid.updateFogOfWar();
	}
}
