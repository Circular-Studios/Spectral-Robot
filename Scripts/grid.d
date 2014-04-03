module grid;
import game, controller, unit;
import core, utility, components;
import gl3n.linalg;
import std.conv;

const int TILE_SIZE = 10;
const int GRID_SIZE = 10;

/** Inherits from GameObject to simplify drawing/positioning
 */
shared class Grid : GameObject
{
	static shared Tile[GRID_SIZE][GRID_SIZE] tiles;
	GameObject[ ( TileType.max + 1 ) * ( TileSelection.max + 1 ) ] tileObjects;
	bool isUnitSelected = false;
	Unit selectedUnit;
	
	vec2i sel;
	
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
		// move the selector around the grid
		if( Input.getState( "Down", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.y += 1;
			if( sel.y >= GRID_SIZE ) sel.y = GRID_SIZE - 1;
			tiles[sel.x][sel.y].selection = TileSelection.HighlightBlue;
		}
		else if( Input.getState( "Up", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.y -= 1;
			if( sel.y < 0 ) sel.y = 0;
			tiles[sel.x][sel.y].selection = TileSelection.HighlightBlue;
		}
		
		if( Input.getState( "Right", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.x += 1;
			if( sel.x >= GRID_SIZE ) sel.x = GRID_SIZE - 1;
			tiles[sel.x][sel.y].selection = TileSelection.HighlightBlue;
		}
		else if( Input.getState( "Left", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.x -= 1;
			if( sel.x < 0 ) sel.x = 0;
			tiles[sel.x][sel.y].selection = TileSelection.HighlightBlue;
		}
		
		// Select a unit
		if( Input.getState( "Enter", true ) && !isUnitSelected )
		{
			foreach( obj; Game.gc.level )
			{
				auto unit = cast(shared Unit)obj;
				if ( unit !is null && unit.posX == sel.x && unit.posY == sel.y )
				{
					selectedUnit = unit;
					isUnitSelected = true;
				}
			}
		}
		
		// Place a selected unit
		else if( Input.getState( "Enter", true ) && isUnitSelected  && tiles[sel.x][sel.y].type == TileType.Open )
		{
			// change the tile types
			tiles[selectedUnit.posX][selectedUnit.posY].type = TileType.Open;
			tiles[sel.x][sel.y].type = TileType.HalfBlocked;
			
			// move the unit to the new location
			selectedUnit.posX = sel.x;
			selectedUnit.posY = sel.y;
			selectedUnit.updatePosition();
			isUnitSelected = false;
		}
		
		// Deselect a unit
		if( Input.getState( "Back", true ) && isUnitSelected )
		{
			selectedUnit = null;
			isUnitSelected = false;
		}
	}
	
	/// Temporary method for ease of this sprint
	void initTiles()
	{
		for( int i = 0; i < GRID_SIZE * GRID_SIZE; i++ )
		{
			int x = i % GRID_SIZE;
			int z = i / GRID_SIZE;
			
			string[shared GameObject] parents;
			string[][shared GameObject] children;
			auto tile = cast(shared Tile)Prefabs["Tile"].createInstance(parents, children);
			
			tile.x = x;
			tile.z = z;
			
			this.addChild(tile);
			Game.activeScene[ "Tile" ~ x.to!string ~ z.to!string ] = tile;
			tiles[x][z] = tile;
		}
	}
}

shared class Tile : GameObject
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
			case TileSelection.HighlightBlue:
				this.material = Assets.get!Material("HighlightBlue");
				break;
			case TileSelection.HighlightRed:
				this.material = Assets.get!Material("HighlightRed");
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
				this.selection = TileSelection.HighlightRed;
				break;
			case TileType.FullyBlocked:
				this.selection = TileSelection.HighlightRed;
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
		this.transform.scale = vec3( TILE_SIZE / 2 );
	}
}

enum TileType
{
	Open, // Does not block
	HalfBlocked, // Blocks movement, but not vision/attacks
	FullyBlocked // Blocks movement, vision, and attacks
}

enum TileSelection
{
	None,
	HighlightBlue,
	HighlightRed
	//HighlightGreen
}
