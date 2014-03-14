module ability;
import core;


enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Ground
}

enum TargetArea
{
	Point,
	Line,
	Square,
	Circle,
}

shared class Ability
{
private:
	static uint nextID;

	TargetType _targetType;
	TargetArea _targetArea;
	int _range;
	int _radius; // Different uses for different Areas
	int _cooldown;
public:
	immutable uint ID;

	mixin( Property!_targetType );
	mixin( Property!_targetArea );
	mixin( Property!_range );
	mixin( Property!_radius );
	mixin( Property!_cooldown );

	this ()
	{
		// Constructor
		ID = nextID;
		nextID++;
	}
}
