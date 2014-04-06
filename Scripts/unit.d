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
	int _team;
	int[] _abilities;
	
public:
	immutable uint ID;
	mixin( Property!( _posX, AccessModifier.Public) );
	mixin( Property!( _posY, AccessModifier.Public) );
	mixin( Property!( _team, AccessModifier.Public) );
	mixin( Property!( _hp, AccessModifier.Public) );
	mixin( Property!( _speed, AccessModifier.Public) );
	mixin( Property!( _attack, AccessModifier.Public) );
	mixin( Property!( _defense, AccessModifier.Public) );
	mixin( Property!( _abilities, AccessModifier.Public) );
	
	this()
	{
		ID = nextID;
		nextID++;
	}
	
	void init( int posX, int posY, int team, int hp, int sp, int at, int df, shared int[] abilities )
	{
		_posX = posX;
		_posY = posY;
		_team = team;
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_abilities = abilities;
		updatePosition();
	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = _posX * 10;
		this.transform.position.z = _posY * 10 - 50;
	}
}
