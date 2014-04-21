module grid;
import game, controller, tile, unit, turn, action;
import core, utility, components;
import gl3n.linalg;
import std.conv;

const int TILE_SIZE = 10;

/// A grid that contains tiles
shared class Grid : GameObject
{
private:
	Tile[][] _tiles;
	bool _isUnitSelected = false;
	Unit _selectedUnit;
	int _gridX, _gridY;
	vec2i sel;
	
public:
	mixin( Property!( _tiles, AccessModifier.Public ) );
	mixin( Property!( _isUnitSelected, AccessModifier.Public ) );
	mixin( Property!( _selectedUnit, AccessModifier.Public ) );
	mixin( Property!( _gridX, AccessModifier.Public ) );
	mixin( Property!( _gridY, AccessModifier.Public ) );

	// Setup left mouse click
	this()
	{
		Input.addKeyDownEvent( Keyboard.MouseLeft, ( kc )
		{
			if( auto obj = Input.mouseObject )
			{
				logInfo( "Clicked on ", obj.name );

				// If unit is selected and a tile is clicked, move if possible
				if( auto tile = cast(shared Tile)obj )
				{
					if( isUnitSelected && selectedUnit.checkMove( tile.toID() ) )
					{
						// move the unit to the new location
						Game.turn.sendAction( Action( 0, selectedUnit.ID, tile.toID(), true ) );
						selectedUnit.move( tile.toID() );
					}
					else if( !isUnitSelected && tile.occupant !is null )
					{
						selectedUnit = tile.occupant;
						isUnitSelected = true;
						selectedUnit.previewMove();
						Game.turn.sendAction( Action( 1, selectedUnit.ID, selectedUnit.position, false ) );
					}
				}
				else
				{
					// Deselect a unit if not a tile
					if( isUnitSelected )
						selectedUnit.deselect();

					// Select a unit
					if( auto unit = cast(shared Unit)obj )
					{
						selectedUnit = unit;
						isUnitSelected = true;
						unit.previewMove();
						Game.turn.sendAction( Action( 1, unit.ID, unit.position, false ) );
					}
				}
			}
		} );

		Input.addKeyDownEvent( Keyboard.Keyboard1, ( uint kc ) { if( _selectedUnit) _selectedUnit.useAbility( 1, 1 ); } );
	}
	
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

	}
	
	
	/// Get a tile by ID
	shared(Tile) getTileByID( uint tileID )
	{
		return tiles[ tileID % gridX ][ tileID / gridX ];
	}
	
	/// Find all tiles in a range
	shared(Tile[]) getInRange( shared Tile startingTile, uint range )
	{
		// Create temp tuples to store stuff in.
		import std.typecons;
		alias Tuple!( shared Tile, "tile", uint, "depth" ) searchState;
		alias Tuple!( int, "x", int, "y" ) point;

		auto visited = new bool[][]( gridX, gridY ); // Keeps track of what tiles have been added already.
		searchState[] states; // Queue of states to sort through.
		shared Tile[] foundTiles; // Tiles inside the range.
		
		// Start with initial tile.
		states ~= searchState( startingTile, 0 );
		
		while( states.length )
		{
			auto state = states[ 0 ];
			states = states[ 1..$ ];
			
			if( visited[ state.tile.x ][ state.tile.y ] )
				continue;

			visited[ state.tile.x ][ state.tile.y ] = true;
			
			if( state.depth < range && ( cast()state.tile == cast()startingTile || state.tile.type == TileType.Open ) )
			{
				foundTiles ~= state.tile;
				foreach( coord; [ point( state.tile.x, state.tile.y - 1 ), point( state.tile.x, state.tile.y + 1 ), point( state.tile.x - 1, state.tile.y ), point( state.tile.x + 1, state.tile.y ) ] )
					if( coord.x < gridX && coord.x >= 0 && coord.y < gridY && coord.y >= 0 && !visited[ coord.x ][ coord.y ] )
						states ~= searchState( tiles[ coord.x ][ coord.y ], state.depth + 1 );
			}
		}
		
		return foundTiles;
	}
	
	/// Create an ( n x m ) grid of tiles
	void initTiles( int n, int m )
	{
		logInfo("Grid size: ( ", n, ", ", m, " )" );
		
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
			tile.transform.scale = vec3( TILE_SIZE / 3 );

			// hide the tile
			tile.stateFlags.drawMesh = false;

			// make the name unique
			tile.name = "Tile ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";
			
			this.addChild( tile );
			tiles[ x ][ y ] = tile;
		}

		// Create the floor from a prefab and add it to the scene
		// TODO: I'm so sorry I hardcoded, future programmer, it needed to be done at the time.
		for( int i = 0; i < 9; i++ )
		{
			int x = i % 3;
			int y = i / 3;
			
			string[ shared GameObject ] parents;
			string[][ shared GameObject ] children;
			auto floor = Prefabs[ "MarbleFloor" ].createInstance( parents, children );

			floor.transform.position.x = x * TILE_SIZE * 8 + 35;
			floor.transform.position.y = -0.3;
			floor.transform.position.z = y * TILE_SIZE * 8 + 35;
			floor.transform.scale = vec3( TILE_SIZE * 4 );
			
			// make the name unique
			floor.name = "Floor ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";
			
			this.addChild( floor );
		}
	}
}
