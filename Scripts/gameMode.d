module gameMode;
import dash;

enum GameMode
{
	Deathmatch,
	CTF // capture the flag
}

class TurnCounter
{
public:
	int turnCounter;
	
	int robotKills = 0;
	int wolfKills = 0;

	this (GameMode gameMode) {
		if (gameMode == GameMode.Deathmatch) {
			turnCounter = 20;
		} else {
			turnCounter = -1;
		}
	}
	
	void Iterate() {
		if (turnCounter > 0) turnCounter --;
		info("Turns Left: ", turnCounter);
	}
}