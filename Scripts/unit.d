module unit;
import ability, grid;

import core, utility, components;

shared class Unit : GameObject
{
private:
	static uint nextID = 0;
	int _hp;
	int _speed;
	int _attack;
	int _defense;
	int _gridX;
	uint _position;
	int _team;
	uint[] _abilities;
	
public:
	immutable uint ID;
	mixin( Property!( _position, AccessModifier.Public) );
	mixin( Property!( _gridX, AccessModifier.Public) );
	mixin( Property!( _team, AccessModifier.Public) );
	mixin( Property!( _hp, AccessModifier.Public) );
	mixin( Property!( _speed, AccessModifier.Public) );
	mixin( Property!( _attack, AccessModifier.Public) );
	mixin( Property!( _defense, AccessModifier.Public) );
	mixin( Property!( _abilities, AccessModifier.Public) );

	@property int x()
	{
		return cast(int)position % gridX;
	}

	@property int y()
	{
		return cast(int)position / gridX;
	}

	this()
	{
		ID = nextID;
		nextID++;
	}

	void init( uint position, int gridX, int team, int hp, int sp, int at, int df, uint[] abilities )
	{
		_position = position;
		_gridX = gridX;
		_team = team;
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_abilities = cast(shared uint[])abilities;
		updatePosition();
	}

	void move( uint tileID )
	{

	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = this.x * 10;
		this.transform.position.z = this.y * 10;
	}
}
