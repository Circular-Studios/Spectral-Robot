module ability;
import core, utility;
import game, grid, tile;

enum DamageType
{
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
	DamageType _damageType;
	StatEffected _statEffected;
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
	shared(Tile[]) highlight( uint originID, uint unitRange )
	{
		switch( _targetArea )
		{
			default:
				return null;
			case TargetArea.Single:
				return Game.grid.getInRange( originID, unitRange, range );
			case TargetArea.Radial:
				return Game.grid.getInRange( originID, unitRange, range );
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
	
	this()
	{
		ID = nextID++;
		_currentCooldown = 0;
	}
	
	/// Use the ability
	bool use( uint originID, uint targetID )
	{
		// make sure the targetID is allowed
		bool legalTile = false;
		logInfo(targetID);
		foreach( tile; _selectedTiles )
		{
			logInfo(tile.toID());
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
			logInfo("ability.use worked");
			// reset cooldown
			_currentCooldown = cooldown;
		}
		logInfo("ability.use failed");
		return false;
	}

	// apply the effects of the ability
	bool applyAbility( uint originID, uint targetID )
	{
		shared Tile originTile = Game.grid.getTileByID( originID );
		shared Tile targetTile = Game.grid.getTileByID( targetID );
		// team check
		logInfo(targetID, " ", targetTile.occupant !is null);
		logInfo(originID, " ", originTile.occupant !is null);
		if( targetTile.occupant !is null && ( targetType == TargetType.Tile ||
		  ( targetType == TargetType.EnemyUnit && targetTile.occupant.team != originTile.occupant.team ) ||
		  ( targetType == TargetType.AlliedUnit && targetTile.occupant.team == originTile.occupant.team ) ) )
		{
			switch( damageType )
			{
				default:
					originTile.occupant.applyEffect!"_hp"( damage );
					break;
				case DamageType.Buff:
					break;
				case DamageType.Debuff:
					break;
				case DamageType.Direct:
					// call the straight line function
					break;
				case DamageType.DOT:
					originTile.occupant.applyEffect!"_hp"( damage, duration );
					break;
				case DamageType.Healing:
					originTile.occupant.applyEffect!"_hp"( -damage );
					break;
			}
			logInfo( originTile.occupant.name, " used ", name, " on ", targetTile.occupant.name );
		}
		logInfo("applyAbility failed");
		return false;
	}
	
	/// Preview the ability
	void preview( uint originID, uint unitRange )
	{
		// get the tiles the ability can effect
		_selectedTiles = highlight( originID, unitRange );
		
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
		
		// remove from grid
		Game.grid.isAbilitySelected = false;
		Game.grid.selectedAbility = 0;
	}
}
