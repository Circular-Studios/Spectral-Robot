module controller;
import unit, ability, grid;
import core, utility;
import yaml;
import std.path, std.conv;

final shared class Controller
{
public:
	Action[] lastTurn; // Gets cleared after a turn
	Action[] currentTurn; // Gets populated as the user makes actions
	GameObjectCollection gameObjects; // Abstract this to a GameState class or something? Idk yet
	Ability[string] abilities; // The instantiated units for this instance of the game
	
	this()
	{
		gameObjects = new shared GameObjectCollection();
		
		// first load all the objects
		gameObjects.loadObjects("Base");
		
		// create the grid
		auto grid = new shared Grid();
		grid.transform.position.z = -50;
		grid.transform.updateMatrix();
		gameObjects["Grid"] = grid;
		
		// load the game
		loadAbilities();
		loadUnits();
		loadLevel();
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
			int damage, range, cooldown;
			
			// get the variables from the yaml node
			string name = abilityNode["Name"].as!string;
			if( Config.tryGet( "TargetType", ttype, abilityNode ) )
			{
				targetType = to!TargetType(ttype);
			}
			if( Config.tryGet( "TargetArea", tarea, abilityNode ) )
			{
				targetArea = to!TargetArea(tarea);
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
	void loadUnits()
	{
		// So we are going to parse the Units folder for the unit files
		// For those, we'll get the Name of the node, which will be how we call into the gameObjects
		foreach( unitNode; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, "Units" ) ) )
		{
			// instantiate the prefab of a unit
			string[shared GameObject] parents;
			string[][shared GameObject] children;
			auto unit = cast(shared Unit)Prefabs[ unitNode[ "InstanceOf" ].as!string ].createInstance( parents, children );
			
			// get the variables from the yaml node
			int posX, posY, hp, sp, at, df = 0;
			string ability;
			unit.name = unitNode["Name"].as!string;
			Config.tryGet( "PosX", posX, unitNode );
			Config.tryGet( "PosY", posY, unitNode );
			Config.tryGet( "HP", hp, unitNode );
			Config.tryGet( "Speed", sp, unitNode );
			Config.tryGet( "Attack", at, unitNode );
			Config.tryGet( "Defense", df, unitNode );
			
			// initialize the unit and add it to the GameObjectCollection
			unit.init( posX, posY, hp, sp, at, df, [] );
			gameObjects[ unit.name ] = unit;
		}
	}
	
	/// Load and create levels from yaml
	void loadLevel()
	{
		
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
