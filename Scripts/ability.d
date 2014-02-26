module Scripts.ability;
import core.properties;

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

class Ability
{
private:
	TargetType _targetType;
	TargetArea _targetArea;
	int _range;
	int _radius; // Different uses for different Areas
	int _cooldown;
public:
	mixin( Property!_targetType );
	mixin( Property!_targetArea );
	mixin( Property!_range );
	mixin( Property!_radius );
	mixin( Property!_cooldown );

	this ()
	{
		// Constructor
	}
}
