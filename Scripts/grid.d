module grid;
import game;
import core, utility, components;
import gl3n.linalg;
import std.conv;

const int TILE_SIZE = 10;
const int GRID_SIZE = 10;

/** Inherits from GameObject to simplify drawing/positioning
  */
class Grid : GameObject
{
	Tile[GRID_SIZE][GRID_SIZE] tiles;
	GameObject[(TileType.max + 1) * (TileSelection.max + 1)] tileObjects;

	vec2i sel;

	this()
	{
		initTiles();
	}

	override void onDraw()
	{
		for( int i = 0; i < GRID_SIZE * GRID_SIZE; i++ )
		{
			int x = i % GRID_SIZE;
			int z = i / GRID_SIZE;
			tiles[x][z].draw();
		}
	}

	override void onUpdate()
	{
		if( Input.getState( "Down", true ) )
		{
			tiles[sel.x][sel.y].selection = TileSelection.None;
			sel.y += 1;
			if( sel.y >= GRID_SIZE ) sel.y = GRID_SIZE - 1;
			tiles[sel.x][sel.y].selection = TileSelection.Select1;
		}
		else if( Input.getState( "Up", true ) )
		{
			tiles[sel.x][sel.y].selection = TileSelection.None;
			sel.y -= 1;
			if( sel.y < 0 ) sel.y = 0;
			tiles[sel.x][sel.y].selection = TileSelection.Select1;
		}

		if( Input.getState( "Right", true ) )
		{
			tiles[sel.x][sel.y].selection = TileSelection.None;
			sel.x += 1;
			if( sel.x >= GRID_SIZE ) sel.x = GRID_SIZE - 1;
			tiles[sel.x][sel.y].selection = TileSelection.Select1;
		}
		else if( Input.getState( "Left", true ) )
		{
			tiles[sel.x][sel.y].selection = TileSelection.None;
			sel.x -= 1;
			if( sel.x < 0 ) sel.x = 0;
			tiles[sel.x][sel.y].selection = TileSelection.Select1;
		}
	}

	/// Temporary method for ease of this sprint
	void initTiles()
	{
		for( int i = 0; i < GRID_SIZE * GRID_SIZE; i++ )
		{
			int x = i % GRID_SIZE;
			int z = i / GRID_SIZE;
			auto tile = cast(Tile)Prefabs["Tile"].createInstance();
			tile.x = x;
			tile.z = z;
			tiles[x][z] = tile;
		}
	}
}

class Tile : GameObject
{
private:
	TileType _type;
	TileSelection _selection;

public:

	@property void selection( TileSelection s )
	{
		final switch( s )
		{
			case TileSelection.None:
				this.material = Assets.get!Material("TileDefault");
				break;
			case TileSelection.Select1:
				this.material = Assets.get!Material("TileSelect1");
				break;
			case TileSelection.Select2:
				this.material = Assets.get!Material("TileSelect2");
		}
		_selection = s;
	}

	@property TileSelection selection()
	{
		return _selection;
	}

	@property TileType type()
	{
		return _type;
	}

	@property void x( int X )
	{
		this.transform.position.x = X * TILE_SIZE;
		this.transform.updateMatrix();
	}
	@property void z( int Z )
	{
		this.transform.position.z = Z * TILE_SIZE;
		this.transform.updateMatrix();
	}

	this()
	{
		this._type = TileType.Open;
		this._selection = TileSelection.None;
		this.transform.scale = vec3( TILE_SIZE/2 );
	}

}

enum TileType
{
	Open, /// Does not block
	HalfBlocked, /// Blocks movement, but not vision/attacks
	FullyBlocked /// Blocks movement, vision, and attacks
}

enum TileSelection
{
	None, // Unselected tile
	Select1, // First kind of highlight
	Select2 // Second kind of highlight
}