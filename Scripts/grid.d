module grid;
import core, utility, components;
import game;
import std.conv;

const int TILE_SIZE = 50;
const int GRID_SIZE = 10;

/** Inherits from GameObject to simplify drawing/positioning
  */
class Grid : GameObject
{
	Tile[GRID_SIZE][GRID_SIZE] tiles;
	GameObject[(TileType.max + 1) * (TileSelection.max + 1)] tileObjects;

	this()
	{
		initTiles();
	}

	override void onDraw()
	{

	}

	/// Temporary method for ease of this sprint
	void initTiles()
	{



	}
}

class Tile : GameObject
{
private:
	TileType _type;
	TileSelection _selection;

public:

	this(TileType type, TileSelection select)
	{
		this._type = type;
		this._selection = select;
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