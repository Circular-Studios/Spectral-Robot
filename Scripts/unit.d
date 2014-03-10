module unit;
import ability;

import core, utility, components;

class Unit : GameObject
{
private:
	static uint nextID = 0;
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

	void init(int hp, int sp, int at, int df, Ability melee, Ability ranged, Ability[] abilities )
	{
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_meleeAttack = melee;
		_rangedAttack = ranged;
		_abilities = abilities;
	}
}

