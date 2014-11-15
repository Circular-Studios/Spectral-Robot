module grid;
import game, controller, tile, unit, turn, action;
import dash.core, dash.utility, dash.components;
import gl3n.linalg;
import std.conv, std.algorithm, std.range, std.array;

/// A grid that contains tiles
class Grid : Component
{
private:
	vec2i sel;

public:
	alias owner this;
    Tile[][] tiles;
	bool isUnitSelected = false;
	bool isAbilitySelected = false;
	bool fogOfWar;
	Unit selectedUnit;
	uint selectedAbility;
	int gridX, gridY;

	// Setup key events
	this()
	{
		// Deselect selected unit
		Input.addButtonDownEvent( "Back", ( kc )
		{
			if( isUnitSelected && Game.turn.currentTeam == Game.turn.activeTeam )
			{
				Game.turn.sendAction( Action( 2, selectedUnit.ID, 0, false ) );
				selectedUnit.deselect();
			}
		} );

		// Left mouse click
		Input.addButtonDownEvent( "Select", ( kc )
		{
			if( auto obj = Input.mouseObject )
			{
				info( "Clicked on ", obj.name );

				// only allow interaction on your turn
				if( Game.turn.currentTeam == Game.turn.activeTeam )
				{
					// If unit is selected and a tile is clicked, move if possible
					if( auto tile = obj.getComponent!Tile )
					{
						if( isUnitSelected && selectedUnit.checkMove( tile.toID() ) )
						{
							// move the unit to the new location
							Game.turn.sendAction( Action( 0, selectedUnit.ID, tile.toID(), true ) );
							selectedUnit.move( tile.toID() );
						}
						// select a unit if the tile has an occupying unit
						else if( !isUnitSelected && tile.occupant !is null && tile.occupant.remainingActions > 0 && tile.occupant.team == Game.turn.currentTeam )
						{
							tile.occupant.previewMove();
							Game.turn.sendAction( Action( 1, selectedUnit.ID, 0, false ) );
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
									Game.turn.sendAction( Action( 2, selectedUnit.ID, 0, false ) );
									selectedUnit.deselect();
								}
								Game.turn.sendAction( Action( 1, unit.ID, 0, false ) );
								unit.previewMove();
							}
						}
						// Deselect a unit if not a tile
						else if( isUnitSelected )
						{
							Game.turn.sendAction( Action( 2, selectedUnit.ID, 0, false ) );
							selectedUnit.deselect();
						}
					}
				}
			}
		} );

		// ability hotkeys
		foreach( action; 0..10 )
		{
			Input.addButtonDownEvent( "Action" ~ action.to!string, ( kc )
			{
				Game.turn.sendAction( Action( 3, action, 0, false ) );
				selectAbility( action );
			} );
		}
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

			info( "Selected ability: ", Game.abilities[ selectedAbility ].name, ", ",
				Game.abilities[ selectedAbility ].currentCooldown, " turn(s) to use." );
		}
	}

	/// Get a tile by ID
	Tile getTileByID( uint tileID )
	{
		return tiles[ tileID % gridX ][ tileID / gridX ];
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
		alias Tuple!( Tile, "tile", uint, "depth" ) searchState;
		alias Tuple!( int, "x", int, "y" ) point;

		auto visited = new bool[][]( gridX, gridY ); // Keeps track of what tiles have been added already.
		searchState[] states; // Queue of states to sort through.
		Tile[] foundTiles; // Tiles inside the range.

		// Start with initial tile.
		Tile startingTile = Game.grid.getTileByID( originID );
		states ~= searchState( startingTile, 0 );

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
			 || state.tile.toID == startingTile.toID 							// or this is the starting tile
			 || ( passThroughUnits && state.tile.occupant !is null ) ) )		// or there is a unit that we want to bypass
			{
				// reconfirm search depth and add to final tile set
				if( range2 == 0 ) foundTiles ~= state.tile;
				else if( state.depth > range && state.depth <= range2 + range ) foundTiles ~= state.tile;

				// find more tiles to search (get the 4 tiles nearby)
				foreach( coord; [
					point( state.tile.x, state.tile.y - 1 ),
					point( state.tile.x, state.tile.y + 1 ),
					point( state.tile.x - 1, state.tile.y ),
					point( state.tile.x + 1, state.tile.y ) ] )
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
		info("Grid size: ( ", n, ", ", m, " )" );

		//initialize tiles
		tiles = new Tile[][]( n, m );
		gridX = n;
		gridY = m;

		// Create tiles from a prefab and add them to the scene
		for( int i = 0; i < n * m; i++ )
		{
			int x = i % n;
			int y = i / n;

			auto t = Prefabs[ "SquareFilled" ].createInstance();
			auto tile = t.getComponent!Tile;

			tile.x = x;
			tile.y = y;
			tile.z = 0;
			tile.transform.scale = vec3( TILE_SIZE / 2 );

			// hide the tile
			tile.stateFlags.drawMesh = false;

			// make the name unique for debugging
			tile.changeName( "Tile ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )" );

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
			floor.changeName( "Floor ( " ~ x.to!string ~ ", " ~ y.to!string ~ " )" );

			this.addChild( floor );
		}
	}
}
