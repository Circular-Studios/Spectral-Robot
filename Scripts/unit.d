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
	uint _position;
	int _team;
	int[] _abilities;
	
public:
	immutable uint ID;
	mixin( Property!( _position, AccessModifier.Public) );
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
	
	void init( uint position, int team, int hp, int sp, int at, int df, shared int[] abilities )
	{
		_position = position;
		_team = team;
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_abilities = abilities;
		updatePosition();
	}

	void move(uint tileID )
	{

	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = _posX * 10;
		this.transform.position.z = _posY * 10 - 50;
	}
}
