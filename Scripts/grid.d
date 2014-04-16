module grid;
import game, controller, unit;
import core, utility, components;
import gl3n.linalg;
import std.conv;

const int TILE_SIZE = 10;

/** Inherits from GameObject to simplify drawing/positioning
 */
shared class Grid : GameObject
{
	Tile[][] _tiles;
	mixin( Property!( _tiles, AccessModifier.Public ) );
	GameObject[ ( TileType.max + 1 ) * ( TileSelection.max + 1 ) ] tileObjects;
	bool isUnitSelected = false;
	Unit selectedUnit;
	int gridSizeX, gridSizeY;
	vec2i sel;
	
	override void onDraw()
	{
		// Draw the tiles
		for( int i = 0; i < gridSizeX * gridSizeY; i++ )
		{
			int x = i % gridSizeX;
			int z = i / gridSizeY;
			
			tiles[ x ][ z ].draw();
		}
	}
	
	override void onUpdate()
	{
		// move the selector around the grid
		if( Input.getState( "Down", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.y += 1;
			if( sel.y >= gridSizeY ) sel.y = gridSizeY - 1;
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
			if( sel.x >= gridSizeX ) sel.x = gridSizeX - 1;
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
				if ( unit !is null && unit.x == sel.x && unit.y == sel.y )
				{
					selectedUnit = unit;
					isUnitSelected = true;
					foreach( tile; getInRange( _tiles[ unit.x ][ unit.y ], unit.speed ) )
					{
						tile.selection = TileSelection.HighlightRed;
					}
				}
			}
		}
		
		// Place a selected unit
		else if( Input.getState( "Enter", true ) && isUnitSelected  && tiles[ sel.x ][ sel.y ].type == TileType.Open )
		{
			// change the tile types
			tiles[selectedUnit.x][selectedUnit.y].type = TileType.Open;
			tiles[sel.x][sel.y].type = TileType.HalfBlocked;
			
			// move the unit to the new location
			//selectedUnit.x = sel.x;
			//selectedUnit.y = sel.y;
			selectedUnit.position = sel.x + sel.y * gridSizeX;
			selectedUnit.updatePosition();
			isUnitSelected = false;
		}
		
		// Deselect a unit
		if( Input.getState( "Back", true ) && isUnitSelected )
		{
			foreach( tile; getInRange( _tiles[ selectedUnit.x ][ selectedUnit.y ], selectedUnit.speed ) )
			{
				tile.selection = TileSelection.None;
			}

			selectedUnit = null;
			isUnitSelected = false;
		}
	}
	
	/// Highlight tiles
	shared(Tile[]) getInRange( shared Tile startingTile, uint range )
	{
		// Create temp tuples to store stuff in.
		import std.typecons;
		alias Tuple!( shared Tile, "tile", uint, "depth" ) searchState;
		alias Tuple!( int, "x", int, "y" ) point;

		// Keeps track of what tiles have been added already.
		auto visited = new bool[][]( gridSizeX, gridSizeY );
		// Queue of states to sort through.
		searchState[] states;
		// Tiles inside the range.
		shared Tile[] foundTiles;

		// Start with initial tile.
		states ~= searchState( startingTile, 0 );

		while( states.length )
		{
			auto state = states[ 0 ];
			states = states[ 1..$ ];

			if( visited[ state.tile.x ][ state.tile.y ] )
				continue;

			foundTiles ~= state.tile;
			visited[ state.tile.x ][ state.tile.y ] = true;

			if( state.depth < range && ( cast()state.tile == cast()startingTile || state.tile.type == TileType.Open ) )
				foreach( coord; [ point( state.tile.x, state.tile.y - 1 ), point( state.tile.x, state.tile.y + 1 ), point( state.tile.x - 1, state.tile.y ), point( state.tile.x + 1, state.tile.y ) ] )
					if( coord.x < gridSizeX && coord.x >= 0 && coord.y < gridSizeY && coord.y >= 0 && !visited[ coord.x ][ coord.y ] )
						states ~= searchState( tiles[ coord.x ][ coord.y ], state.depth + 1 );
		}

		return foundTiles;
	}
	
	/// Create an ( n x m ) grid of tiles
	void initTiles( int n, int m )
	{
		//initialize tiles
		_tiles = new shared Tile[][]( n, m );
		gridSizeX = n;
		gridSizeY = m;
		
		// Create tiles from a prefab and add them to the scene
		for( int i = 0; i < n * m; i++ )
		{
			int x = i % n;
			int y = i / n;
			
			string[ shared GameObject ] parents;
			string[][ shared GameObject ] children;
			auto tile = cast( shared Tile )Prefabs[ "Tile" ].createInstance( parents, children );
			
			tile.x = x;
			tile.y = y;
			tile.gridX = gridSizeX;

			this.addChild( tile );
			Game.activeScene[ "Tile" ~ x.to!string ~ y.to!string ] = tile;
			tiles[ x ][ y ] = tile;
		}
	}
}

shared class Tile : GameObject
{
private:
	TileType _type;
	TileSelection _selection;
	GameObject _occupant;
	int _gridX;
	
public:
	mixin( Property!( _occupant, AccessModifier.Public) );
	mixin( Property!( _gridX, AccessModifier.Public) );

	@property void selection( TileSelection s )
	{
		final switch( s )
		{
			case TileSelection.None:
				this.material = Assets.get!Material( "TileDefault" );
				break;
			case TileSelection.HighlightBlue:
				this.material = Assets.get!Material( "HighlightBlue" );
				break;
			case TileSelection.HighlightRed:
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
		return x + ( y * gridX );
	}
}

enum TileType
{
	Open, // Does not block
	HalfBlocked, // Blocks movement, but not vision/attacks
	FullyBlocked, // Blocks movement, vision, and attacks
}

enum TileSelection
{
	None,
	HighlightBlue,
	HighlightRed,
	//HighlightGreen
}
