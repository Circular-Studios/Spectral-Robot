module Scripts.unit;
import Scripts.ability;

import core;

class Unit : GameObject
{
private:
	static uint nextID;
	int _hp;
	int _speed;
	int _attack;
	int _defense;

	Ability _meleeAttack;
	Ability _rangedAttack;
	Ability[] _abilities;
	int[] _abilityCooldowns;

public:
	immutable uint ID;

	mixin( Property!_hp );
	mixin( Property!_speed );
	mixin( Property!_attack );
	mixin( Property!_defense );

	mixin( Property!_abilities );
	mixin( Property!_abilityCooldowns );

	this()
	{
		// Constructor code
		ID = nextID;
		nextID++;
	}
}

