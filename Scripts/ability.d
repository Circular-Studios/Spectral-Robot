module ability;
import dash.core, dash.utility;
import game, grid, tile;
import gl3n.math;

enum DamageType
{
	Normal,
	Buff,
	Debuff,
	Healing,
	DOT, // damage over time
	Direct,
	Reduce,
	LifeSteal,
	Modifier,
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
	Radial,
	MovingRadial,
}

enum StatEffected
{
	None,
	Accuracy,
	Turn, // deplete the actions left on a unit
	Damage,
}

class Ability
{
private:
	static uint nextID = 10;
	string _name;
	TargetType _targetType;
	TargetArea _targetArea;
	DamageType _damageType;
	StatEffected _statEffected;
	int _damage;
	int _range;
	int _unitRange;
	int _cooldown;
	int _duration;
	int _accuracy;
	int _currentCooldown;
	
	// only used in this class
	//int _currentRange;
	Tile[] _selectedTiles;
	
	/// Highlight the tiles that the ability can effect
	Tile[] highlight( uint originID, uint range )
	{
		switch( _targetArea )
		{
			default:
				return null;
			case TargetArea.Single:
				return Game.grid.getInRange( originID, range );
			case TargetArea.Radial:
				return Game.grid.getInRange( originID, range );
		}
	}
	
public:
	immutable uint ID;
	mixin( Property!( _name, AccessModifier.Public ) );
	mixin( Property!( _targetType, AccessModifier.Public ) );
	mixin( Property!( _targetArea, AccessModifier.Public ) );
	mixin( Property!( _damageType, AccessModifier.Public ) );
	mixin( Property!( _statEffected, AccessModifier.Public ) );
	mixin( Property!( _damage, AccessModifier.Public ) );
	mixin( Property!( _range, AccessModifier.Public ) );
	mixin( Property!( _cooldown, AccessModifier.Public ) );
	mixin( Property!( _currentCooldown, AccessModifier.Public ) );
	mixin( Property!( _duration, AccessModifier.Public ) );
	mixin( Property!( _accuracy, AccessModifier.Public ) );

	/// Temporary function until we can modify properties as lvalue
	void decrementCooldown()
	{
		//if( _currentCooldown > 0 )
			//_currentCooldown--;
	}
	
	this()
	{
		ID = nextID++;
		_currentCooldown = 0;
	}
	
	/// Use the ability
	bool use( uint originID, uint targetID )
	{
		if( currentCooldown <= 0 )
		{
			// make sure the targetID is allowed
			bool legalTile = false;
			foreach( tile; _selectedTiles )
			{
				if( tile.toID() == targetID )
					legalTile = true;
			}

			if( legalTile )
			{
				switch( _targetArea )
				{
					default:
						break;
					case TargetArea.Single:
							return applyAbility( originID, targetID );
					case TargetArea.Radial:
						foreach( tile; _selectedTiles )
						{
							return applyAbility( originID, tile.toID() );
						}
				}
			}
		}
		logInfo( "ability.use failed" );
		return false;
	}

	// apply the effects of the ability
	bool applyAbility( uint originID, uint targetID )
	{
		Tile originTile = Game.grid.getTileByID( originID );
		Tile targetTile = Game.grid.getTileByID( targetID );
		// team check
		if( targetTile.occupant !is null && ( targetType == TargetType.Tile ||
		  ( targetType == TargetType.EnemyUnit && targetTile.occupant.team != originTile.occupant.team ) ||
		  ( targetType == TargetType.AlliedUnit && targetTile.occupant.team == originTile.occupant.team ) ) )
		{
			int attack = originTile.occupant.attack + damage;
			final switch( damageType )
			{
				case DamageType.Normal:
					targetTile.occupant.applyEffect!"hp"( attack );
					break;
				case DamageType.Buff:
					// TODO: Expand this to use the StatEffected enum
					targetTile.occupant.applyEffect!"attack"( damage, duration, true );
					break;
				case DamageType.Debuff:
					break;
				case DamageType.Direct:
					// call the straight line function
					break;
				case DamageType.DOT:
					targetTile.occupant.applyEffect!"hp"( attack, duration );
					break;
				case DamageType.Healing:
					targetTile.occupant.applyEffect!"hp"( -attack, duration );
					break;
				case DamageType.Reduce:
					break;
				case DamageType.LifeSteal:
					originTile.occupant.applyEffect!"hp"( -attack, duration );
					targetTile.occupant.applyEffect!"hp"( attack, duration );
					break;
				case DamageType.Modifier:
					break;
			}
			// reset cooldown
			currentCooldown = cooldown;

			Game.ui.callJSFunction( "setHp", [targetTile.occupant.hp, targetTile.occupant.ID] );

			logInfo( originTile.occupant.name, " used ", name, " on ", targetTile.occupant.name );
			return true;
		}
		logInfo( "applyAbility failed" );
		return false;
	}

	/// Check if a tile is within range of the ability
	bool checkRange( uint originID, uint targetID )
	{
		auto origin = Game.grid.getTileByID( originID );
		auto target = Game.grid.getTileByID( targetID );
		return range + _unitRange >= abs( ( target.x - origin.x ) ) + abs( ( target.y - origin.y ) );
	}

	unittest
	{
		Ability test = new Ability();
		test.range = 1;
		test.unitRange = 1;
		assert( test.checkRange( 0, 0 ) == true );
		assert( test.checkRange( 0, 3 ) == false );
	}

	/// Preview the ability
	void preview( uint originID, uint unitRange )
	{
		// get the tiles the ability can effect
		_unitRange = unitRange;
		_selectedTiles = highlight( originID, range + unitRange );
		
		// change the material of the tiles
		foreach( tile; _selectedTiles )
		{
			if( tile.selection != TileSelection.Blue || 
			( tile.occupant !is null && tile.occupant != Game.grid.selectedUnit ) )
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
		
		// remove from grid
		Game.grid.isAbilitySelected = false;
		Game.grid.selectedAbility = 0;
	}
}
