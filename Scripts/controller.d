module controller;
import unit, ability, grid, game;
import core, utility;
import yaml;
import std.path, std.conv;

final shared class Controller
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	Scene level; // The active scene in the engine
	Ability[ string ] abilities; // The instantiated units for this instance of the game
	
	this()
	{
		level = new shared Scene();
		Game.activeScene = level;
		
		// first load all the objects
		level.loadObjects( "Base" );
		
		// load the game
		loadAbilities();
		loadLevel( "TheOnlyLevel" ); //TODO: Remove hardcoded value
	}
	
	/// Load and create abilities from yaml
	void loadAbilities()
	{
		foreach( abilityNode; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, "Abilities" ) ) )
		{
			auto ability = Config.getObject!(shared Ability)( abilityNode );
			abilities[ ability.name ] = ability;

			logInfo( ability.name, ": ", ability.damage );
		}
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
			string[] abilityStrings;
			shared int[] abilityIDs;
			int[] spawn;
			
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
			string[shared GameObject] parents;
			string[][shared GameObject] children;
			auto unit = cast(shared Unit)Prefabs[ unitNode[ "Prefab" ].as!string ].createInstance( parents, children );
			
			// get the variables from the node
			unit.name = unitNode[ "Name" ].as!string;
			Config.tryGet( "HP", hp, unitNode );
			Config.tryGet( "Speed", sp, unitNode );
			Config.tryGet( "Attack", at, unitNode );
			Config.tryGet( "Defense", df, unitNode );
			Config.tryGet( "Abilities", abilityStrings, unitNode );
			foreach( name; abilityStrings )
			{
				abilityIDs ~= abilities[ name ].ID.to!( shared int );
			}
			
			// initialize the unit and add it to the active scene
			unit.init( spawn[ 0 ], spawn[ 1 ], team, hp, sp, at, df, abilityIDs );
			level[ unit.name ] = unit;
			( cast(shared Grid)level[ "Grid" ] ).tiles[ spawn[ 0 ] ][ spawn[ 1 ] ].type = TileType.HalfBlocked;
		}
	}
	
	/// Return the file path for a level to load
	string scanLevelDirectory( string levelName )
	{
		foreach( file; FilePath.scanDirectory( buildNormalizedPath( FilePath.Resources.Objects, "Levels" ), "*.yml" ) )
		{
			if( file.baseFileName() == levelName )
			{
				return file.fullPath();
			}
			
			//TODO: Handle level yaml not existing
		}
		
		return null;
	}
	
	/// Load and create a level from yaml
	void loadLevel( string levelName )
	{
		// load the level from yaml
		Node levelNode = loadYamlFile( scanLevelDirectory ( levelName ) );
		
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
		grid.transform.position.z = -50;
		grid.transform.updateMatrix();
		grid.initTiles( gridSize[ 0 ], gridSize[ 1 ] );
		level[ "Grid" ] = grid;
		
		// create the units
		loadUnits( unitsNode );
		
		// add props to the scene
		foreach( Node propNode; propsNode )
		{
			// setup variables
			int[] loc;
			string name, prefab, ttype;
			TileType tileType;
			
			// get the variables from the node
			Config.tryGet( "Location", loc, propNode );
			Config.tryGet( "Prefab", prefab, propNode );
			if( Config.tryGet( "TileType", ttype, propNode ) )
			{
				tileType = to!TileType( ttype );
			}
			
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
					string[shared GameObject] parents;
					string[][shared GameObject] children;
					auto prop = Prefabs[ prefab ].createInstance( parents, children );
					
					// make the name unique
					prop.name = prefab ~ x.to!string ~ "-" ~ y.to!string;
					
					// place the prop
					prop.transform.position.x = x * TILE_SIZE;
					prop.transform.position.z = y * TILE_SIZE - 50;
					
					// add the prop to the scene
					level[ prop.name ] = prop;
					
					// change the TileType of occupying tiles
					grid.tiles[ x ][ y ].type = tileType;
				}
			}
		}
	}
}

abstract class Action
{
public:
	uint originUnitId;
}

class MoveAction : Action
{
public:
	int x, y;
}

class AttackAction : Action
{
public:
	uint targetUnitID;
}

class AbilityAction : Action
{
public:
	uint targetUnitId;
	uint abilityID;
}
