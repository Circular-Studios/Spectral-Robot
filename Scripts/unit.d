module unit;
import game, ability, action, grid, effect, tile, turn;
import core, utility, components;
import gl3n.linalg, gl3n.math, gl3n.interpolate;
import std.algorithm;

enum ACTIONS_RESET = 3;

class Unit : Behavior!()
{
private:
	static uint nextID = 0;
	int _hp;
	int _speed;
	int _attack;
	int _defense;
	uint _position;
	Team _team;
	int _remainingRange;
	int _remainingActions;
	uint[] _abilities;
	Tile[] _selectedTiles;
	IEffect[] _activeEffects;

public:
	alias owner this;
	immutable uint ID;
	mixin( Property!( _position, AccessModifier.Public) );
	mixin( Property!( _team, AccessModifier.Public) );
	mixin( Property!( _remainingRange, AccessModifier.Public) );
	mixin( Property!( _remainingActions, AccessModifier.Public) );
	mixin( Property!( _selectedTiles, AccessModifier.Public) );
	mixin( Property!( _activeEffects, AccessModifier.Public) );
	mixin( Property!( _hp, AccessModifier.Public) );
	mixin( Property!( _speed, AccessModifier.Public) );
	mixin( Property!( _attack, AccessModifier.Public) );
	mixin( Property!( _defense, AccessModifier.Public) );
	mixin( Property!( _abilities, AccessModifier.Public) );
	@property int x() { return cast(int)position % Game.grid.gridX; }
	@property int y() { return cast(int)position / Game.grid.gridX; }
	
	this()
	{
		ID = nextID++;
		_remainingActions = ACTIONS_RESET;
	}
	
	/// Initialize a unit
	void init( uint position, Team team, int hp, int sp, int at, int df, uint[] abilities )
	{
		_position = position;
		_team = team;
		_hp = hp;
		_speed = sp;
		_remainingRange = _speed;
		_attack = at;
		_defense = df;
		_abilities = abilities;
		updatePosition();
	}
	
	/// Use an ability
	bool useAbility( uint abilityID, uint targetID )
	{
		if( remainingActions > 0 && _abilities.countUntil( abilityID ) > -1 )
		{
			if( Game.abilities[ abilityID ].use( position, targetID ) )
			{
				Game.turn.sendAction( Action( abilityID, ID, position, true ) );
				actionUsed();
				return true;
			}
		}
		
		return false;
	}

	/// Apply an effect to the unit
	/// 
	/// Params:
	///  prop = 	the variable you want to effect
	///  diff = 	the amount to change prop by
	///  duration = the number of turns the effect is applied
	///  reset =	true if prop should return to its original value when the effect is over
	void applyEffect( string prop )( int diff, int duration = 0, bool reset = false )
	{
		// apply the effect for a number of turns
		if( duration > 0 )
		{
			// add the ability to a list
			_activeEffects ~= new Effect!prop( diff, duration, reset, mixin( prop ) );
		}

		// apply the effect now
		mixin( prop ) -= diff;
	}

	/// Use an effect stored in the unit
	void reEffect( string prop )( int diff, int duration, bool reset, int originalValue )
	{
		mixin( prop ) -= diff;
		duration--;
		
		// check if the ability has run its course
		if( duration <= 0 )
		{
			if( reset )
				mixin( prop ) = originalValue;
		}
	}
	
	/// Move the unit to a tile
	void move( uint targetTileID )
	{
		if( checkMove( targetTileID ) )
		{
			// easy names for the tiles
			auto curTile = Game.grid.getTileByID( position );
			auto targetTile = Game.grid.getTileByID( targetTileID );
			
			// change the tile types
			curTile.type = TileType.Open;
			targetTile.type = TileType.OccupantActive;

			// Rotate the unit to face the direction he moved
			//Down
			transform.rotation = quat.euler_rotation( 0, 0, 0 );
			// Up
			if( curTile.y > targetTile.y )
				transform.rotation = quat.euler_rotation( 180.radians, 0, 0 );
			// Left
			else if( curTile.x > targetTile.x )
				transform.rotation = quat.euler_rotation( 270.radians, 0, 0 );
			// Right
			else if( curTile.x < targetTile.x )
				transform.rotation = quat.euler_rotation( 90.radians, 0, 0 );
		
			// scale the tile back down
			curTile.transform.scale = vec3( TILE_SIZE / 2 );
			
			// change the tile occupants
			curTile.occupant = null;
			targetTile.occupant = this;
			
			// move the unit to the new location
			position = targetTileID;
			updatePosition();
			deselect();
			Game.grid.isUnitSelected = false;

			// decrement remaining actions and distance
			actionUsed();
			_remainingRange -= abs( ( targetTile.x - curTile.x ) ) + abs ( ( targetTile.y - curTile.y ) );
			
			// update fog of war
			Game.grid.updateFogOfWar();
			
			// check if the turn is over
			Game.turn.checkTurnOver();

			Game.turn.sendAction( Action( 0, ID, position, true ) );
		}
	}
	
	/// Check if the move is allowed
	bool checkMove( uint targetTileID )
	{
		auto tile = Game.grid.getTileByID( targetTileID );
		
		// get the distance away from the unit's current position
		uint distance = abs( ( tile.x - x ) ) + abs ( ( tile.y - y ) );
		
		// Check speed, actions, and tileType
		return remainingRange >= distance && remainingActions > 0 && tile.type == TileType.Open;
	}
	
	/// Highlight the tiles the unit can move to
	void previewMove()
	{
		selectedTiles = Game.grid.getInRange( position, _remainingRange );
		
		// change the material of the tiles
		foreach( tile; selectedTiles )
		{
			tile.selection = TileSelection.Blue;
			/*auto startTime = Time.totalTime;
			auto dur = 100.msecs;
			scheduleTimedTask( dur,
			{
				tile.transform.scale = 
					interp( vec3( 0 ), vec3( TILE_SIZE / 2 ), 
								 ( Time.totalTime - startTime ) / dur.toSeconds );
			} );*/
		}

		// only run this if a unit isn't already selected
		if( !Game.grid.isUnitSelected )
		{
			// update the grid
			Game.grid.isUnitSelected = true;
			Game.grid.selectedUnit = this;

			// automatically select the first ability
			Game.grid.selectAbility( 0 );
			Game.turn.sendAction( Action( 1, ID, position, false ) );
		}
	}
	
	/// Remove focus from the unit and any highlighted tiles
	void deselect()
	{
		// change the material of the tiles
		foreach( tile; selectedTiles )
		{
			tile.resetSelection();
		}
		
		// scale the tile back down
		Game.grid.getTileByID( position ).transform.scale = vec3( TILE_SIZE / 2 );
		
		// Modify grid variables
		Game.grid.selectedUnit = null;
		Game.grid.isUnitSelected = false;
		
		// deselect the ability if there was one
		if ( Game.grid.isAbilitySelected )
			Game.abilities[ Game.grid.selectedAbility ].unpreview();

		logInfo( "Deselected ", name, ", ", remainingActions, " action(s) remaining." );
	}

	/// Decrement remaining actions 
	void actionUsed( int numActions = 1 )
	{
		_remainingActions -= numActions;
		if( remainingActions <= 0 )
		{
			Game.grid.getTileByID( position ).type = TileType.OccupantInactive;
			Game.turn.checkTurnOver();
		}
		deselect();
	}
	
	/// Prep the unit to begin a turn anew
	void newTurn()
	{
		// reset action and range
		_remainingActions = ACTIONS_RESET;
		_remainingRange = speed;
		Game.grid.getTileByID( position ).type = TileType.OccupantActive;

		// apply active effects (reversed to allow for deletions)
		foreach_reverse( effect; _activeEffects )
		{
			effect.use( this );
		}
	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = this.x * TILE_SIZE;
		this.transform.position.z = this.y * TILE_SIZE;
	}
}
