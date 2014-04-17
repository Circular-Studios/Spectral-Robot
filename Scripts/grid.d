module grid;
import game, controller, tile, unit;
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
	int gridX, gridY;
	vec2i sel;
	
	override void onDraw()
	{
		// Draw the tiles
		for( int i = 0; i < gridX * gridY; i++ )
		{
			int x = i % gridX;
			int z = i / gridY;
			
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
			if( sel.y >= gridY ) sel.y = gridY - 1;
			tiles[sel.x][sel.y].selection = TileSelection.Blue;
		}
		else if( Input.getState( "Up", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.y -= 1;
			if( sel.y < 0 ) sel.y = 0;
			tiles[sel.x][sel.y].selection = TileSelection.Blue;
		}
		
		if( Input.getState( "Right", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.x += 1;
			if( sel.x >= gridX ) sel.x = gridX - 1;
			tiles[sel.x][sel.y].selection = TileSelection.Blue;
		}
		else if( Input.getState( "Left", true ) )
		{
			tiles[sel.x][sel.y].resetSelection();
			sel.x -= 1;
			if( sel.x < 0 ) sel.x = 0;
			tiles[sel.x][sel.y].selection = TileSelection.Blue;
		}
		
		// Select a unit
		if( Input.getState( "Enter", true ) && !isUnitSelected )
		{
			foreach( obj; Game.gc.level.objects() )
			{
				auto unit = cast(shared Unit)obj;
				if ( unit !is null && unit.x == sel.x && unit.y == sel.y )
				{
					selectedUnit = unit;
					isUnitSelected = true;
					foreach( tile; getInRange( _tiles[ unit.x ][ unit.y ], unit.speed ) )
					{
						tile.selection = TileSelection.Red;
					}
				}
			}
		}
		
		// Place a selected unit
		else if( Input.getState( "Enter", true ) && isUnitSelected  && tiles[ sel.x ][ sel.y ].type == TileType.Open )
		{
			// change the tile types
			tiles[ selectedUnit.x ][ selectedUnit.y ].type = TileType.Open;
			tiles[ sel.x ][ sel.y ].type = TileType.HalfBlocked;
			
			// move the unit to the new location
			selectedUnit.position = sel.x + sel.y * gridX;
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
		auto visited = new bool[][]( gridX, gridY );
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
					if( coord.x < gridX && coord.x >= 0 && coord.y < gridY && coord.y >= 0 && !visited[ coord.x ][ coord.y ] )
						states ~= searchState( tiles[ coord.x ][ coord.y ], state.depth + 1 );
		}

		return foundTiles;
	}
	
	/// Create an ( n x m ) grid of tiles
	void initTiles( int n, int m )
	{
		//initialize tiles
		_tiles = new shared Tile[][]( n, m );
		gridX = n;
		gridY = m;
		
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
			tile.gridX = gridX;

			this.addChild( tile );
			tiles[ x ][ y ] = tile;
		}
	}
}
