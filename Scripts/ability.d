module ability;
import core, utility;


enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Ground,
}

enum TargetArea
{
	Single,
	Line,
	Square,
	Radial,
}

shared class Ability
{
private:
	static uint nextID = 0;
	string _name;
	TargetType _targetType;
	TargetArea _targetArea;
	int _damage;
	int _range;
	int _cooldown;
	
public:
	immutable uint ID;
	mixin( Property!_name );
	mixin( Property!_targetType );
	mixin( Property!_targetArea );
	mixin( Property!_damage );
	mixin( Property!_range );
	mixin( Property!_cooldown );
	
	this ()
	{
		ID = nextID;
		nextID++;
	}
	
	void init( string name, TargetType ttype, TargetArea tarea, int damage, int range, int cooldown )
	{
		_name = name;
		_targetType = ttype;
		_targetArea = tarea;
		_damage = damage;
		_range = range;
		_cooldown = cooldown;
	}
}
