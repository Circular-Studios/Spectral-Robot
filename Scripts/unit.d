module Scripts.unit;
import Scripts.ability;

import core.properties;

class Unit
{
private:
	int _hp;
	int _speed;
	int _attack;
	int _defense;

	Ability[] _abilities;
	int[] _abilityCooldowns;

public:
	mixin( Property!_hp );
	mixin( Property!_speed );
	mixin( Property!_attack );
	mixin( Property!_defense );

	mixin( Property!_abilities );
	mixin( Property!_abilityCooldowns );

	this()
	{
		// Constructor code
	}
}

