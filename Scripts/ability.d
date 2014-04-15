module ability;
import core, grid, utility;


enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Ground,
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
	
	this ()
	{
		ID = nextID++;
		
		// REMOVE: this is a highlighting test
		if( ID == 0 )
		{
			Input.addKeyDownEvent( Keyboard.F9, ( uint kc ) { preview( 2, 2 ); } );
		}
	}

	void init( string name, TargetType ttype, TargetArea tarea, int damage, int range, int cooldown )
	{
		_currentCooldown = 0;
		_name = name;
		_targetType = ttype;
		_targetArea = tarea;
		_damage = damage;
		_range = range;
		_cooldown = cooldown;
	}
	
	void preview( int x, int y )
	{
		highlight( x, y, true );
	}
	
	void unpreview()
	{
		
	}
	
	/// Use the ability
	void use()
	{
		_currentCooldown = _cooldown;
	}
}
