module grid;
import core.gameobject, core.gameobjectcollection, utility, components;
import game;
import std.conv;

class Tile : GameObject
{
	GameObjectCollection goc;
	int[][] grid;
	int curX = 0;
	int curY = 0;
	
	this()
	{
		// get the GameObjectCollection from the main script
		this.goc = (cast(RobotGhosts)DGame.instance).goc;
	}
	
	override void onUpdate()
	{
		//demo grid movement
		if ( Input.getState!bool( "Up" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curY < 2)
				curY++;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}
		
		if ( Input.getState!bool( "Down" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curY > 0)
				curY--;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}
		
		if ( Input.getState!bool( "Left" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curX > 0)
				curX--;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}
		
		if ( Input.getState!bool( "Right" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curX < 2)
				curX++;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}
	}
	
	/// Called on the draw cycle.
	override void onDraw() { }
	/// Called on shutdown.
	override void onShutdown() { }
	/// Called when the object collides with another object.
	override void onCollision( GameObject other ) { }
}
