module unit;
import ability;

import core, utility, components;

shared class Unit : GameObject
{
private:
	static uint nextID = 0;
	int _hp;
	int _speed;
	int _attack;
	int _defense;
	int _posX;
	int _posY;

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
	mixin( Property!(_posX, AccessModifier.Public) );
	mixin( Property!(_posY, AccessModifier.Public) );

	mixin( Property!_abilities );
	mixin( Property!_abilityCooldowns );

	this()
	{
		// Constructor code
		ID = nextID;
		nextID++;
	}

	void init(int posX, int posY, int hp, int sp, int at, int df, shared Ability melee, shared Ability ranged, shared Ability[] abilities )
	{
		_posX = posX;
		_posY = posY;
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_meleeAttack = melee;
		_rangedAttack = ranged;
		_abilities = abilities;
	}

	bool updatePosition()
	{
		this.transform.position.x = _posX * 10;
		this.transform.position.z = _posY * 10 - 50;
		this.transform.updateMatrix();
		return true;
	}
}

