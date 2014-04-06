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
			// setup variables
			string ttype, tarea;
			TargetType targetType;
			TargetArea targetArea;
			int damage, range, cooldown = 0;
			
			// get the variables from the yaml node
			string name = abilityNode[ "Name" ].as!string;
			if( Config.tryGet( "TargetType", ttype, abilityNode ) )
			{
				targetType = to!TargetType( ttype );
			}
			if( Config.tryGet( "TargetArea", tarea, abilityNode ) )
			{
				targetArea = to!TargetArea( tarea );
			}
			Config.tryGet( "Damage", damage, abilityNode );
			Config.tryGet( "Range", range, abilityNode );
			Config.tryGet( "Cooldown", cooldown, abilityNode );
			
			// initialize the ability
			abilities[ name ] = new shared Ability();
			abilities[ name ].init( name, targetType, targetArea, damage, range, cooldown );
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
			int posX, posY, hp, sp, at, df = 0;
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
					break;
				}
			}
			if( !nameCheck ) continue;
			
			// instantiate the prefab of a unit
			string[shared GameObject] parents;
			string[][shared GameObject] children;
			auto unit = cast(shared Unit)Prefabs[ unitNode[ "InstanceOf" ].as!string ].createInstance( parents, children );
			
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
			
			logInfo(unit.name, spawn[0], spawn[1]);
			
			// initialize the unit and add it to the active scene
			unit.init( spawn[ 0 ], spawn[ 1 ], hp, sp, at, df, abilityIDs );
			level[ unit.name ] = unit;
		}
	}
	
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
		Node levelNode = loadYamlFile( scanLevelDirectory ( levelName ) );
		
		// setup variables
		int[] gridSize;
		Node unitsNode;
		
		// get the variables from the yaml node
		string name = levelNode[ "Name" ].as!string;
		Config.tryGet( "Grid", gridSize, levelNode );
		Config.tryGet( "Units", unitsNode, levelNode );
		
		// create the grid
		auto grid = new shared Grid();
		grid.transform.position.z = -50;
		grid.transform.updateMatrix();
		grid.initTiles( gridSize[ 0 ], gridSize[ 1 ] );
		level[ "Grid" ] = grid;
		
		// create the units
		loadUnits( unitsNode );
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
