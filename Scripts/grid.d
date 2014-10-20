module grid;
import game, controller, tile, unit, turn, action;
import dash.core, dash.utility, dash.components;
import gl3n.linalg, gl3n.math;
import std.conv, std.algorithm, std.range, std.array;

const int TILE_SIZE = 24;
const int HEX_SIZE = 12;
const int HEX_WIDTH = HEX_SIZE * 2;
const int HEX_OFFSET = 1; // this corresponds to an odd-q grid
const float HEX_WIDTH_MOD = 0.86;
const float HEX_HEIGHT = sqrt( 3.0 ) / 2 * HEX_WIDTH;

// taken from http://forum.dlang.org/post/vqfvihyezbmwcjkmpzin@forum.dlang.org
template Unroll( alias CODE, alias N, alias SEP = "" )
{
	enum t = replace( CODE, "%", "%1$d" );
	enum Unroll = iota( N ).map!( i => format( t, i ) ).join( SEP );
}

/// A grid that contains tiles
@yamlComponent()
class Grid : Component
{
private:
	Tile[][] _tiles;
	bool _isUnitSelected = false;
	bool _isAbilitySelected = false;
	bool _fogOfWar;
	Unit _selectedUnit;
	uint _selectedAbility;
	int _gridX, _gridY;
	vec2i sel;

	vec3i cubeNeighbors = 
		[
			vec3i( state.tile.x + 1, state.tile.y - 1, state.tile.z     ),
			vec3i( state.tile.x + 1, state.tile.y    , state.tile.z - 1 ),
			vec3i( state.tile.x    , state.tile.y + 1, state.tile.z - 1 ),
			vec3i( state.tile.x - 1, state.tile.y + 1, state.tile.z     ),
			vec3i( state.tile.x - 1, state.tile.y    , state.tile.z + 1 ),
			vec3i( state.tile.x    , state.tile.y - 1, state.tile.z + 1 )
		];
	
public:
	alias owner this;
	mixin( Property!( _tiles, AccessModifier.Public ) );
	mixin( Property!( _isUnitSelected, AccessModifier.Public ) );
	mixin( Property!( _isAbilitySelected, AccessModifier.Public ) );
	mixin( Property!( _selectedUnit, AccessModifier.Public ) );
	mixin( Property!( _selectedAbility, AccessModifier.Public ) );
	mixin( Property!( _fogOfWar, AccessModifier.Public ) );
	mixin( Property!( _gridX, AccessModifier.Public ) );
	mixin( Property!( _gridY, AccessModifier.Public ) );
	
	// Setup key events
	this()
	{
		// Deselect selected unit
		Input.addButtonDownEvent( "Back", ( uint kc ) 
		{ 
			if( isUnitSelected && Game.turn.currentTeam == Game.turn.activeTeam )
			{
				Game.turn.sendAction( Action( NetworkAction.deselect, selectedUnit.ID, 0, false ) );
				selectedUnit.deselect();
			}
		} );

		// Left mouse click
		Mouse.addButtonDownEvent( Mouse.Buttons.Left, ( kc )
		{
			if( auto obj = Input.mouseObject )
			{
				logInfo( "Clicked on ", obj.name );

				// only allow interaction on your turn
				if( Game.turn.currentTeam == Game.turn.activeTeam )
				{
					// If unit is selected and a tile is clicked, move if possible
					if( auto tile = obj.getComponent!Tile )
					{
						if( isUnitSelected && selectedUnit.checkMove( tile.toID() ) )
						{
							// move the unit to the new location
							Game.turn.sendAction( Action( NetworkAction.move, selectedUnit.ID, tile.toID(), true ) );
							selectedUnit.move( tile.toID() );
						}
						// select a unit if the tile has an occupying unit
						else if( !isUnitSelected && tile.occupant !is null && tile.occupant.remainingActions > 0 && tile.occupant.team == Game.turn.currentTeam )
						{
							tile.occupant.previewMove();
							Game.turn.sendAction( Action( NetworkAction.select, selectedUnit.ID, 0, false ) );
						}
						// use the selected ability on the tile
						else if( isAbilitySelected )
						{
							uint originID = selectedUnit.ID;
							uint abilityID = selectedAbility;
							if( selectedUnit.useAbility( selectedAbility, tile.toID() ) )
								Game.turn.sendAction( Action( abilityID, originID, tile.toID(), true ) );
						}
					}
					else
					{
						if( auto unit = obj.getComponent!Unit )
						{
							// Use the selected ability on the unit if in range
							if( isAbilitySelected && Game.abilities[ selectedAbility ].checkRange( selectedUnit.position, unit.position ) )
							{
								uint originID = selectedUnit.ID;
								uint abilityID = selectedAbility;
								if( selectedUnit.useAbility( selectedAbility, unit.position ) )
									Game.turn.sendAction( Action( abilityID, originID, unit.position, true ) );
							}
							// Select a unit
							else if( unit.remainingActions > 0 && unit.team == Game.turn.currentTeam )
							{
								if( selectedUnit )
								{
									Game.turn.sendAction( Action( NetworkAction.select, selectedUnit.ID, 0, false ) );
									selectedUnit.deselect();
								}
								Game.turn.sendAction( Action( NetworkAction.preview, unit.ID, 0, false ) );
								unit.previewMove();
							}
						}
						// Deselect a unit if not a tile
						else if( isUnitSelected )
						{
							Game.turn.sendAction( Action( NetworkAction.deselect, selectedUnit.ID, 0, false ) );
							selectedUnit.deselect();
						}
					}
				}
			}
		} );
		
		// ability hotkeys
		enum keyboard = "Keyboard.Buttons.Keyboard";
		mixin( Unroll!(q{ 
			Keyboard.addButtonDownEvent( mixin( keyboard ~ ( % + 1 ).to!string ), ( kc )
			{
				Game.turn.sendAction( Action( NetworkAction.select, %, 0, false ) );
				selectAbility( % );
			} );}, 9, "" ));
	}
	
	/// Select an ability from a unit
	void selectAbility( int ability )
	{
		// deselect current ability
		if( isAbilitySelected )
			Game.abilities[ selectedAbility ].unpreview();

		if( isUnitSelected && ability < selectedUnit.abilities.length )
		{
			isAbilitySelected = true;
			selectedAbility = selectedUnit.abilities[ ability ];
			selectedUnit.previewMove();
			Game.abilities[ selectedAbility ].preview( selectedUnit.position, selectedUnit.remainingRange );

			logInfo( "Selected ability: ", Game.abilities[ selectedAbility ].name, ", ",
				Game.abilities[ selectedAbility ].currentCooldown, " turn(s) to use." );
		}
	}

	/// Get a tile by ID
	Tile getTileByID( uint tileID )
	{
		return tiles[ tileID % gridX ][ tileID / gridX ];
	}

	// Convert cube to odd-q offset
	uint cubeToGrid( vec3i cube )
	{
		return cube.x * gridX + cube.z + ( cube.x - ( cube.x % 2 ) ) / 2;
	}

	// Convert odd-q offset to cube
	vec3i gridToCube( uint tileID )
	{
		Tile tile = getTileByID( tileID );
		vec3i cube;
		cube.x = tile.x;
		cube.z = tile.y - ( tile.x - ( tile.x % 2 ) ) / 2;
		cube.y = -cube.x - cube.z;
		return cube;
	}

	vec3i cubeDirection( uint dir )
	{
		return cubeNeighbors[ dir ];
	}

	unittest
	{
		assert( cubeToGrid( gridToCube( 0 ) ) == 0 );
		assert( cubeToGrid( gridToCube( 1 ) ) == 1 );
		assert( cubeToGrid( gridToCube( 100 ) ) == 100 );
	}

	/// Get the distance between two tiles
	uint hexDistance( vec3i orig, vec3i target )
	{
		logInfo( target.x, " - ", orig.x, " + ", target.z, " - ", orig.z );
		logInfo( orig.x, " - ", target.x, ", ", orig.y, " - ", target.y, ", ", orig.z, " - ", target.z );
		return max( abs( orig.x - target.x ), abs( orig.y - target.y ), abs( orig.z - target.z ) );
	}
	
	/// Find all tiles in a range
	/// 
	/// Params:
	/// originID =			the original tile ID
	/// range =				how far away from the original tile to spread
	/// stopOnUnits =		true to return tiles with units on them, but no further
	/// passThroughUnits =	true to ignore units when searching tiles
	/// range2 =			If a non-zero value is given, the function will return tiles starting at range and ending at range2.
	Tile[] getInRange( uint originID, uint range, bool stopOnUnits = false, bool passThroughUnits = true, uint range2 = 0 )
	{
		// Create temp tuples to store stuff in.
		import std.typecons;
		//alias Tuple!( vec3i, "tile", uint, "depth" ) searchState;
		
		auto visited = new vec3i[]( gridX * gridY ); // Keeps track of what cubes have been added already.
		auto fringes new vec3i[]( gridX * gridY ); // Keeps track of what cubes have been added already.
		//searchState[] states; // Queue of states to sort through.
		//Tile[] foundTiles; // Tiles inside the range.
		
		// Start with initial tile.
		vec3i start = gridToCube( originID );
		visited ~= start;
		fringes ~= start;

		foreach( depth; 1..range + 1 )
		{
			fringes[ depth ] = [];

			foreach( cube; fringes[ depth - 1 ] )
			{
				foreach( dir; 0..6 )
				{
					auto neighbor = cubeDirection( dir ) );

					//	if neighbor not in visited, not blocked
					if( visited[ neighbor ] == null )
					{
						//add neighbor to visited
						visited ~= neighbor;
						fringes[ depth ] ~= neighbor;
					}
				}
			}
		}
		
		while( states.length )
		{
			auto state = states[ 0 ];
			states = states[ 1..$ ];
			
			if( visited[ state.tile.x ][ state.tile.y ] )
				continue;
			
			visited[ state.tile.x ][ state.tile.y ] = true;

			// check search depth and if this tile is legal
			if( ( state.depth <= range 
			 || ( state.depth > range && state.depth <= range2 + range ) ) && 	// tile must be in range
				( state.tile.type == TileType.Open 								// and the tile is open
			 || state.tile.toID == startingPoint.toID 							// or this is the starting tile
			 || ( passThroughUnits && state.tile.occupant !is null ) ) )		// or there is a unit that we want to bypass
			{
				// reconfirm search depth and add to final tile set
				if( range2 == 0 ) foundTiles ~= getTileByID( cubeToGrid( state.tile ) );
				else if( state.depth > range && state.depth <= range2 + range ) foundTiles ~= getTileByID( cubeToGrid( state.tile ) );

				// find more tiles to search (get the 6 tiles nearby)
				auto nearbyTiles = 
				[
					point( state.tile.x + 1, state.tile.y - 1, state.tile.z     ),
					point( state.tile.x + 1, state.tile.y    , state.tile.z - 1 ),
					point( state.tile.x    , state.tile.y + 1, state.tile.z - 1 ),
					point( state.tile.x - 1, state.tile.y + 1, state.tile.z     ),
					point( state.tile.x - 1, state.tile.y    , state.tile.z + 1 ),
					point( state.tile.x    , state.tile.y - 1, state.tile.z + 1 )
				];

				// cube pseudo-code
				//visited = set()
				//add start to visited
				//fringes = [[start]]
				//for each 1 < k ≤ movement:
				//	fringes[k] = []
				//	for each cube in fringes[k-1]:
				//		for each 0 ≤ dir < 6:
				//			neighbor = cube.add(Cube.direction(dir))
				//			if neighbor not in visited, not blocked:
				//				add neighbor to visited
				//				fringes[k].append(neighbor)

				// this code is for a grid, not a cube
				foreach( coord; nearbyTiles )
					if( coord.x < gridX && coord.x >= 0 	// legal tile on x-axis
						&& coord.y < gridY && coord.y >= 0 	// legal tile on y-axis
						&& !visited[ coord.x ][ coord.y ] 	// the tile hasn't been visited
						&& ( !stopOnUnits 					// and don't stop on units
						|| ( stopOnUnits && state.tile.occupant !is null ) ) ) // or the tile has no unit in it
						states ~= searchState( tiles[ coord.x ][ coord.y ], state.depth + 1 );
			}
		}
		
		return foundTiles;
	}

	/// Update the fog of war
	void updateFogOfWar()
	{
		if( fogOfWar )
		{
			Tile[] visibleTiles;
			
			// get the tiles visible to the current team
			foreach( unit; Game.units )
			{
				// hide the unit until we determine who to show
				unit.stateFlags.drawMesh = false;
				getTileByID( unit.position ).stateFlags.drawMesh = false;

				// add the current team to the fog removal list
				if( unit.team == Game.turn.currentTeam )
					visibleTiles ~= getInRange( unit.position, unit.speed );
			}
			
			// show all units on visible tiles
			foreach( tile; visibleTiles )
			{
				if( tile.occupant !is null )
				{
					tile.stateFlags.drawMesh = true;
					tile.occupant.stateFlags.drawMesh = true;
				}
			}
		}
	}
	
	/// Create an ( n x m ) grid of tiles
	void initTiles( int n, int m )
	{
		logInfo( "Grid size: ( ", n, ", ", m, " )" );
		
		//initialize tiles
		_tiles = new Tile[][]( n, m );
		gridX = n;
		gridY = m;
		
		// Create tiles from a prefab and add them to the scene
		for( int i = 0; i < n * m; i++ )
		{
			int x = i % n;
			int y = i / n;
			
			auto t = Prefabs[ "GridHex" ].createInstance();
			auto tile = t.getComponent!Tile;
			
			tile.x = x;
			tile.y = y;
			tile.z = 0;
			
			// hide the tile
			//tile.stateFlags.drawMesh = false;
			
			// make the name unique for debugging
			tile.name = "Tile ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";

			this.addChild( t );
			tiles[ x ][ y ] = tile;
		}
		
		// Create the floor from a prefab and add it to the scene
		// TODO: Move floor creation to the map YAML.
		for( int i = 0; i < 16; i++ )
		{
			int x = i % 4;
			int y = i / 4;
			
			auto floor = Prefabs[ "MarbleFloor" ].createInstance();
			
			floor.transform.position.x = x * TILE_SIZE * 6 + ( TILE_SIZE * 2.5 );
			floor.transform.position.y = -0.3;
			floor.transform.position.z = y * TILE_SIZE * 6 + ( TILE_SIZE * 2.5 );
			floor.transform.scale = vec3( TILE_SIZE * 3 );
			
			// make the name unique
			floor.name = "Floor ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )";
			
			this.addChild( floor );
		}
	}
}
