module unit;
import game, ability, grid, tile, turn;
import core, utility, components;
import gl3n.linalg, gl3n.interpolate;
import std.math;

shared class Unit : GameObject
{
private:
	static uint nextID = 0;
	const int ACTIONS_RESET = 3;
	int _hp;
	int _speed;
	int _attack;
	int _defense;
	uint _position;
	int _team;
	int _remainingActions;
	uint[] _abilities;
	Tile[] selectedTiles;
	
public:
	immutable uint ID;
	mixin( Property!( _position, AccessModifier.Public) );
	mixin( Property!( _team, AccessModifier.Public) );
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
	void init( uint position, int team, int hp, int sp, int at, int df, uint[] abilities )
	{
		_position = position;
		_team = team;
		_hp = hp;
		_speed = sp;
		_attack = at;
		_defense = df;
		_abilities = cast(shared uint[])abilities;
		updatePosition();
	}
	
	/// Use an ability
	bool useAbility( uint abilityID, uint targetID )
	{
		if( _remainingActions > 0 && abilities[ abilityID ] )
		{
			if( Game.abilities[ abilityID ].use( this.ID, targetID ) )
			{
				_remainingActions--;
				return true;
			}
			return false;
		}
		else
			return false;
	}
	
	/// Move the unit to a tile
	void move( uint targetTileID )
	{
		if ( checkMove( targetTileID ) )
		{
			// change the tile types
			Game.grid.getTileByID( position ).type = TileType.Open;
			Game.grid.getTileByID( targetTileID ).type = TileType.HalfBlocked;
			
			// scale the tile back down
			Game.grid.getTileByID( position ).transform.scale = vec3( TILE_SIZE / 3 );
			
			// change the tile occupants
			Game.grid.getTileByID( position ).occupant = null;
			Game.grid.getTileByID( targetTileID ).occupant = this;
			
			// move the unit to the new location
			position = targetTileID;
			updatePosition();
			deselect();
			Game.grid.isUnitSelected = false;
		}
	}
	
	/// Check if unit is within range of the target tile and if tile is Open
	bool checkMove( uint targetTileID )
	{
		auto tile = Game.grid.getTileByID( targetTileID );
		return tile.type == TileType.Open && speed > abs( ( tile.x - x ) ) + abs ( ( tile.y - y ) );
	}
	
	/// Highlight the tiles the unit can move to
	void previewMove()
	{
		selectedTiles = Game.grid.getInRange( Game.grid.tiles[ x ][ y ], speed );
		
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
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = this.x * 10;
		this.transform.position.z = this.y * 10;
	}
}
