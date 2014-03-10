module grid;
import core, utility, components;
import game;
import std.conv;

class Tile : GameObject
{
	GameObjectCollection goc;
	TileType[][] grid;
	int curX = 0;
	int curY = 0;
	
	this()
	{
		// get the GameObjectCollection from the main script
		//this.goc = (cast(RobotGhosts)DGame.instance).goc;
	}

}

enum TileType
{
	Open, /// Does not block
	HalfBlocked, /// Blocks movement, but not vision/attacks
	FullyBlocked /// Blocks movement, vision, and attacks
}