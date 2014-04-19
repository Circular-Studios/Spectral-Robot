module ability;
import core, grid, utility;

enum DamageType
{
	Buff,
	Debuff,
	Healing,
	DOT, // damage over time
	Modifier,
}

enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Tile,
	Space,
	UndeadUnit,
	Self,
	TurretUnit,
}

enum TargetArea
{
	Single,
	Line,
	Square,
	Radial,
	MovingRadial,
}

enum statEffected
{
	Accuracy,
	Turn, // deplete the actions left on a unit
}

shared class Ability
{
private:
	static uint nextID = 10;
	string _name;
	TargetType _targetType;
	TargetArea _targetArea;
	int _damage;
	int _range;
	int _cooldown;
	int _duration;
	int _accuracy;
	int _currentCooldown;
	
	/// Highlight the tiles that the ability can effect
	void highlight( int x, int y, bool preview )
	{
		switch( _targetArea )
		{
			default:
				break;
			case TargetArea.Single:
				break;
			case TargetArea.Radial:
				//highlight( 1, 1, 3, 3, true );
				break;
		}
	}
	
public:
	immutable uint ID;
	mixin( Property!( _name, AccessModifier.Public ) );
	mixin( Property!( _targetType, AccessModifier.Public ) );
	mixin( Property!( _targetArea, AccessModifier.Public ) );
	mixin( Property!( _damage, AccessModifier.Public ) );
	mixin( Property!( _range, AccessModifier.Public ) );
	mixin( Property!( _cooldown, AccessModifier.Public ) );
	mixin( Property!( _duration, AccessModifier.Public ) );
	mixin( Property!( _accuracy, AccessModifier.Public ) );
	
	this()
	{
		ID = nextID++;
		_currentCooldown = 0;
	}

	/// Use the ability
	bool use( uint originID, uint targetID )
	{
		_currentCooldown = cooldown;
		return true;
	}

	/// Preview the ability
	void preview( int x, int y )
	{
		highlight( x, y, true );
	}
	
	void unpreview()
	{
		
	}
}
