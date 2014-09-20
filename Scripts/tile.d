module tile;
import game, controller, grid, unit;
import dash.core, dash.utility, dash.components;
import gl3n.linalg;
import std.conv;

enum TileType
{
	Open, // Does not block
	HalfBlocked, // Blocks movement, but not vision/attacks
	FullyBlocked, // Blocks movement, vision, and attacks
	OccupantActive,
	OccupantInactive,
}

enum TileSelection
{
	None,
	Blue,
	Red,
	Green,
	Black,
}

@yamlComponent()
class Tile : Component
{
private:
	TileType _type;
	TileSelection _selection;
	Unit _occupant;
	
public:
	alias owner this;
	mixin( Property!( _occupant, AccessModifier.Public) );
	
	@property void selection( TileSelection s )
	{
		final switch( s )
		{
			case TileSelection.None:
				this.addComponent( Assets.get!Material( "BlackTile" ) );
				stateFlags.drawMesh = false;
				break;
			case TileSelection.Blue:
				this.addComponent( Assets.get!Material( "BlueTile" ) );
				stateFlags.drawMesh = true;
				break;
			case TileSelection.Red:
				this.addComponent( Assets.get!Material( "RedTile" ) );
				stateFlags.drawMesh = true;
				break;
			case TileSelection.Green:
				this.addComponent( Assets.get!Material( "GreenTile" ) );
				stateFlags.drawMesh = true;
				break;
			case TileSelection.Black:
				this.addComponent( Assets.get!Material( "BlackTile" ) );
				stateFlags.drawMesh = true;
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
				this.selection = TileSelection.None;
				break;
			case TileType.FullyBlocked:
				this.selection = TileSelection.None;
				break;
			case TileType.OccupantActive:
				if( occupant !is null && occupant.team == Game.turn.currentTeam )
					this.selection = TileSelection.Green;
				else
					this.selection = TileSelection.Black;
				break;
			case TileType.OccupantInactive:
				this.selection = TileSelection.Black;
				break;
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
		return cast(int)(this.transform.position.x / HEX_WIDTH * 1.15);
	}
	
	@property void x( float X )
	{
		this.transform.position.x = X * HEX_WIDTH * HEX_WIDTH_MOD;
	}
	
	@property int y()
	{
		return cast(int)this.transform.position.z / HEX_WIDTH;
	}
	
	@property void y( float Y )
	{
		this.transform.position.z = ( x % 2 == 1 ) ? Y * HEX_WIDTH : Y * HEX_WIDTH + ( HEX_WIDTH / 2 );
	}
	
	@property float z()
	{
		return this.transform.position.y;
	}
	
	@property void z( float Z )
	{
		this.transform.position.y = Z * TILE_SIZE / 6;
	}
	
	this()
	{
		this._type = TileType.Open;
		this._selection = TileSelection.None;
	}
	
	uint toID()
	{
		return x + ( y * Game.grid.gridX );
	}
}
