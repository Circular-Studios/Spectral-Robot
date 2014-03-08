module Scripts.controller;
import core, utility;
import yaml;

import Scripts.unit, Scripts.ability;

final class Controller
{
private:
	Action[] lastTurn; //Gets cleared after a turn
	Action[] currentTurn; //Gets populated as the user makes actions
	GameObjectCollection gameObjects; //Abstract this to a GameState class or something? Idk yet
	Ability[] abilities; //The instantiated units for this instance of the game

	this()
	{
		gameObjects = new GameObjectCollection();
		// So we'll first load all the objects
		gameObjects.loadObjects("Base");

		loadUnits();
		loadLevel();
	}

	void loadUnits()
	{
		// So we are going to parse the Units folder for the unit files
		// For those, we'll get the Name of the node, which will be how we call into the gameObjects

		Config.processYamlDirectory( 
			buildNormalizedPath( FilePath.Resources.Objects, "Units" ),
			( Node unitNode ) //Callback function.  See gameobjectcollection lines 34 for example
			{
				Unit unit = cast(Unit)gameObjects[ unitNode["Name"].as!string ];

				//Then for each variable, accessed by unitNode["varname"] or better off, a tryGet
				//Set the values
			} );
		
	}
	
	/// I'm thinking we'll just load one ability at a time as we find them in gameobjects
	/// Returns the ability ID
	uint loadAbility( string name )
	{
		//Add the ability to the Ability array by loading it from yaml, and then return it's ID
		return 0;
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

class Move : Action
{
public:
	int x, y;
}

class Attack : Action
{
public:
	uint targetUnitID;
}

class Ability : Action
{
public:
	uint targetUnitId;
	uint abilityID;
}