module unit;
import game, ability, grid, tile, turn;
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

	bool useAbility( uint abilityID, uint targetID )
	{
		if ( abilities[ abilityID ] )
			return Game.abilities[ abilityID ].use( this.ID, targetID );
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
	}
	
	/// Remove focus from the unit and any highlighted tiles
	void deselect()
	{
		// change the material of the tiles
		foreach( tile; selectedTiles )
		{
			tile.resetSelection();
		}

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
