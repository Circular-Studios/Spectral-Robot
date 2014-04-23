module unit;
import game, ability, grid, tile, turn;
import core, utility, components;
import gl3n.linalg, gl3n.interpolate;
import std.math;

enum ACTIONS_RESET = 3;

shared class Unit : GameObject
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
	Tile[] selectedTiles;
	
public:
	immutable uint ID;
	mixin( Property!( _position, AccessModifier.Public) );
	mixin( Property!( _team, AccessModifier.Public) );
	mixin( Property!( _remainingActions, AccessModifier.Public) );
	mixin( Property!( _hp, AccessModifier.Public) );
	mixin( Property!( _speed, AccessModifier.Public) );
	mixin( Property!( _attack, AccessModifier.Public) );
	mixin( Property!( _defense, AccessModifier.Public) );
	mixin( Property!( _abilities, AccessModifier.Public) );
	
	@property int x()
	{
		return cast(int)position % Game.grid.gridX;
	}
	
	@property int y()
	{
		return cast(int)position / Game.grid.gridX;
	}
	
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
		_abilities = cast(shared uint[])abilities;
		updatePosition();
	}
	
	/// Use an ability
	bool useAbility( uint abilityID, uint targetID )
	{
		if( remainingActions > 0 && abilities[ abilityID ] )
		{
			if( Game.abilities[ abilityID ].use( this.ID, targetID ) )
			{
				_remainingActions--;
				
				// if out of actions, check if the turn is over
				Game.turn.checkTurnOver();
				return true;
			}
		}
		
		return false;
	}
	
	/// Move the unit to a tile
	void move( uint targetTileID )
	{
		if ( checkMove( targetTileID ) )
		{
			// easy names for the tiles
			auto curTile = Game.grid.getTileByID( position );
			auto targetTile = Game.grid.getTileByID( targetTileID );
			
			// change the tile types
			curTile.type = TileType.Open;
			targetTile.type = TileType.HalfBlocked;
			
			// scale the tile back down
			curTile.transform.scale = vec3( TILE_SIZE / 3 );
			
			// change the tile occupants
			curTile.occupant = null;
			targetTile.occupant = this;
			
			// decrement remaining actions and distance
			_remainingActions--;
			_remainingRange -= abs( ( targetTile.x - x ) ) + abs ( ( targetTile.y - y ) );
			
			// move the unit to the new location
			position = targetTileID;
			updatePosition();
			deselect();
			Game.grid.isUnitSelected = false;
			
			// update fog of war
			Game.grid.updateFogOfWar();
			
			// check if the turn is over
			Game.turn.checkTurnOver();
		}
	}
	
	/// Check if the move is allowed
	bool checkMove( uint targetTileID )
	{
		auto tile = Game.grid.getTileByID( targetTileID );
		
		// get the distance away from the unit's current position
		uint distance = abs( ( tile.x - x ) ) + abs ( ( tile.y - y ) );
		
		// Check speed, actions, and tileType
		return speed > distance && remainingActions > 0 && tile.type == TileType.Open;
	}
	
	/// Highlight the tiles the unit can move to
	void previewMove()
	{
		selectedTiles = Game.grid.getInRange( Game.grid.tiles[ x ][ y ], _remainingRange );
		
		// change the material of the tiles
		foreach( tile; selectedTiles )
		{
			tile.selection = TileSelection.Blue;
		}
		
		// scale the selected unit's tile
		auto startTime = Time.totalTime;
		auto dur = 100.msecs;
		scheduleTimedTask(
			{
			Game.grid.getTileByID( position ).transform.scale = 
				interp( shared vec3( TILE_SIZE / 3 ), shared vec3( TILE_SIZE / 2 ), 
				       ( Time.totalTime - startTime ) / dur.toSeconds );
		}, dur );
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
		Game.grid.getTileByID( position ).transform.scale = vec3( TILE_SIZE / 3 );
		
		// Modify grid variables
		Game.grid.selectedUnit = null;
		Game.grid.isUnitSelected = false;
	}
	
	/// Prep the unit to begin a turn anew
	void newTurn()
	{
		_remainingActions = ACTIONS_RESET;
		_remainingRange = speed;
	}
	
	/// Fill the number row with hotkeys to select abilities
	void setHotkeys()
	{
		/*
		 foreach( i, abilityID; _abilities )
		 Input.addKeyDownEvent( mixin( "Keyboard.Keyboard" ~ ( i + 1 ).to!string ), ( uint kc ) 
		 {
		 Grid.abilities[ _abilities[ i ] ].preview( _selectedUnit.abilities[ i ], 1 );
		 } );*/
	}
	
	/// Free up the hotkeys for another unit to use
	void removeHotkeys()
	{
		/*
		 foreach( i, abilityID; _abilities )
		 Input.removeKeyDownEvent( mixin( "Keyboard.Keyboard" ~ ( i + 1 ).to!string ), ( uint kc ) 
		 {
		 Grid.abilities[ _abilities[ i ] ].preview( _selectedUnit.abilities[ i ], 1 );
		 } );*/
	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = this.x * 10;
		this.transform.position.z = this.y * 10;
	}
}
