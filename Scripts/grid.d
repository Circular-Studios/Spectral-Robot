module grid;
import core.gameobject, core.gameobjectcollection, utility, components;
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
	Open, /// Can walk & see through
	HalfBlocked, /// Cannot walk, but can see/attack past
	FullyBlocked /// Can neither walk nor see/attack past
}