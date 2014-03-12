module controller;
import unit, ability, grid;
import core, utility;
import yaml;
import std.path;

final class Controller
{
public:
	Action[] lastTurn; //Gets cleared after a turn
	Action[] currentTurn; //Gets populated as the user makes actions
	GameObjectCollection gameObjects; //Abstract this to a GameState class or something? Idk yet
	Ability[string] abilities; //The instantiated units for this instance of the game
	
	this()
	{
		gameObjects = new GameObjectCollection();
		// So we'll first load all the objects
		gameObjects.loadObjects("Base");
		
		auto grid = new Grid();
		gameObjects["Grid"] = grid;
		
		loadAbilities();
		loadUnits();
		loadLevel();
	}
	
	
	void loadAbilities()
	{
		//Add the ability to the Ability array by loading it from yaml, just like in loadUnits
		Config.processYamlDirectory(
			buildNormalizedPath( FilePath.Resources.Objects, "Abilities" ),
			( Node abilityNode )
			{
			string name = abilityNode["Name"].as!string;
			abilities[name] = new Ability();
		} );
	}
	
	void loadUnits()
	{
		// So we are going to parse the Units folder for the unit files
		// For those, we'll get the Name of the node, which will be how we call into the gameObjects
		
		Config.processYamlDirectory( 
		                            buildNormalizedPath( FilePath.Resources.Objects, "Units" ),
		                            ( Node unitNode ) //Callback function.  See gameobjectcollection lines 34 for example
		                            {
			Unit unit = cast(Unit)Prefabs[ unitNode["InstanceOf"].as!string ].createInstance();
			unit.name = unitNode["Name"].as!string;
			
			//Then for each variable, accessed by unitNode["varname"] or better off, a tryGet
			//Set the values
			int hp, sp, at, df = 0;
			string ability;
			Ability melee, ranged;
			Config.tryGet( "HP", hp, unitNode );
			Config.tryGet( "Speed", sp, unitNode );
			Config.tryGet( "Attack", at, unitNode );
			Config.tryGet( "Defense", df, unitNode );
			if( Config.tryGet( "MeleeAttack", ability, unitNode ) )
				melee = abilities[ ability ];
			if( Config.tryGet( "RangedAttack", ability, unitNode ) )
				ranged = abilities[ ability ];
			
			unit.init( hp, sp, at, df, melee, ranged, [ melee, ranged ] );
			
			gameObjects[unit.name] = unit;
		} );
		
	}
	
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
