module unit;
import game, ability, grid, tile;
import core, utility, components;
import std.math;

shared class Unit : GameObject
{
private:
	static uint nextID = 0;
	int _hp;
	int _speed;
	int _attack;
	int _defense;
	uint _position;
	int _team;
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
	}
	
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
	
	/// Move the unit to a tile
	void move( uint targetTileID )
	{
		if ( checkMove( targetTileID ) )
		{
			// move the unit to the new location
			position = targetTileID;
			updatePosition();
			deselect();
			Game.grid.isUnitSelected = false;
		}
	}
	
	/// Check if unit is within range of the target tile
	bool checkMove( uint targetTileID )
	{
		auto tile = Game.grid.getTileByID( targetTileID );
		return speed >= abs( ( tile.x - x ) + ( tile.y - y ) );
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
	}
	
	/// Remove focus from the unit and any highlighted tiles
	void deselect()
	{
		// change the material of the tiles
		foreach( tile; selectedTiles )
		{
			tile.resetSelection();
		}
	}
	
	/// Convert grid coordinates to 3D space
	void updatePosition()
	{
		this.transform.position.x = this.x * 10;
		this.transform.position.z = this.y * 10;
	}
}
