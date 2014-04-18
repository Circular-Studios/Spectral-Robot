module tile;
import game, controller, grid, unit;
import core, utility, components;
import gl3n.linalg;
import std.conv;

enum TileType
{
	Open, // Does not block
	HalfBlocked, // Blocks movement, but not vision/attacks
	FullyBlocked, // Blocks movement, vision, and attacks
}

enum TileSelection
{
	None,
	Blue,
	Red,
}

shared class Tile : GameObject
{
private:
	TileType _type;
	TileSelection _selection;
	GameObject _occupant;
	
public:
	mixin( Property!( _occupant, AccessModifier.Public) );
	
	@property void selection( TileSelection s )
	{
		final switch( s )
		{
			case TileSelection.None:
				this.material = Assets.get!Material( "TileDefault" );
				break;
			case TileSelection.Blue:
				this.material = Assets.get!Material( "HighlightBlue" );
				break;
			case TileSelection.Red:
				this.material = Assets.get!Material( "HighlightRed" );
		}
		_selection = s;
	}
	
	@property void type( TileType t )
	{
		final switch( t )
		{
			case TileType.Open:
				this.selection = TileSelection.None;
				break;
			case TileType.HalfBlocked:
				this.selection = TileSelection.Red;
				break;
			case TileType.FullyBlocked:
				this.selection = TileSelection.Red;
		}
		_type = t;
	}
	
	@property TileType type()
	{
		return _type;
	}
	
	@property TileSelection selection()
	{
		return _selection;
	}
	
	/// Revert the selection material of the tile to its TileType
	void resetSelection()
	{
		type( this.type );
	}
	
	@property int x()
	{
		return cast(int)this.transform.position.x / TILE_SIZE;
	}
	
	@property void x( int X )
	{
		this.transform.position.x = X * TILE_SIZE;
	}
	
	@property int y()
	{
		return cast(int)this.transform.position.z / TILE_SIZE;
	}
	
	@property void y( int Y )
	{
		this.transform.position.z = Y * TILE_SIZE;
	}
	
	this()
	{
		this._type = TileType.Open;
		this._selection = TileSelection.None;
		this.transform.scale = vec3( TILE_SIZE / 2 );
	}
	
	uint toID()
	{
		return x + ( y * Game.grid.gridX );
	}
}
