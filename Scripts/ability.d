module ability;
import core, utility;
import game, grid, tile;

enum DamageType
{
	Buff,
	Debuff,
	Healing,
	DOT, // damage over time
	Modifier,
	LifeSteal,
}

enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Tile,
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
	
	// only used in this class
	int _currentCooldown;
	//int _currentRange;
	Tile[] _selectedTiles;
	
	/// Highlight the tiles that the ability can effect
	shared(Tile[]) highlight( uint originID, uint unitRange, bool preview )
	{
		switch( _targetArea )
		{
			default:
				return null;
			case TargetArea.Single:
				return Game.grid.getTileByID( originID ) ~ cast(shared Tile[])[];
			case TargetArea.Radial:
				return Game.grid.getInRange( originID, unitRange, range );
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
	void preview( uint originID, uint unitRange )
	{
		// get the tiles the ability can effect
		_selectedTiles = highlight( originID, unitRange, true );
		
		// change the material of the tiles
		foreach( tile; _selectedTiles )
		{
			tile.selection = TileSelection.Red;
		}
	}
	
	// Unpreview the ability
	void unpreview()
	{
		// reset the tiles that were highlighted
		foreach( tile; _selectedTiles )
		{
			tile.resetSelection();
		}
		
		// remove from the grid
		Game.grid.selectedAbility = 0;
	}
}
