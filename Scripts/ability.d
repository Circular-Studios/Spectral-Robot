module ability;
import core, grid, utility;


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
	int _currentCooldown;
	
	/// Highlight the tiles that the ability can effect
	void highlight( int x, int y, bool preview )
	{
		switch(_targetArea)
		{
			default:
				break;
			case TargetArea.Single:
				break;
			case TargetArea.Radial:
				Grid.tiles[ x + 1 ][ y ].selection = preview ? TileSelection.HighlightRed : TileSelection.None;
				Grid.tiles[ x - 1 ][ y ].selection = preview ? TileSelection.HighlightRed : TileSelection.None;
				Grid.tiles[ x ][ y + 1 ].selection = preview ? TileSelection.HighlightRed : TileSelection.None;
				Grid.tiles[ x ][ y - 1 ].selection = preview ? TileSelection.HighlightRed : TileSelection.None;
				break;
		}
	}
	
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
