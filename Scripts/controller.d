module Scripts.controller;
import core.gameobject, core.gameobjectcollection;

class Controller
{
private:
	MoveAction[] lastTurn; //Gets cleared after a turn
	MoveAction[] currentTurn; //Gets populated as the user makes actions
	GameObjectCollection gameObjects; //Abstract this to a GameState class or something? Idk yet

	this()
	{
		
	}
}

enum ActionType
{
	Move,
	Attack,
	Ability
}

struct Action(ActionType at)
{
	uint originUnitId;
	static const ActionType type = at;
	static if( type == ActionType.Move )
	{
		/// Location to move, using quickest path algorithm
		int[2] target;
	}
	else static if( type == ActionType.Attack )
	{
		/// ID of the unit 
		uint target;
		uint abilityID;
	}
	else static if( type == ActionType.Ability )
	{
		/// ID of the unit being targetted
		uint target;
		uint abilityID;
	}
}

alias Action!(ActionType.Move) MoveAction;
alias Action!(ActionType.Attack) AttackAction;
alias Action!(ActionType.Ability) AbilityAction;