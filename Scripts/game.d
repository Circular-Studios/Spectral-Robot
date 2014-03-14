module game;
import controller;

import core, graphics, components, utility;

@property RobotGhosts Game()
{
	return cast(RobotGhosts)DGame.instance;
}

class RobotGhosts : DGame
{
	public Controller gc;

	// Name that game
	@property override string title()
	{
		return "Spectral Robot Task Force";
	}

	override void onInitialize()
	{
		logInfo( "Initializing..." );
		
		Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = GameState.Quit; } );
		Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = GameState.Reset; } );

		gc = new Controller();

		auto cam = gc.gameObjects["Camera"];
		Graphics.setCamera( cam.camera );
	}
	
	override void onUpdate()
	{
		gc.gameObjects.apply( go => go.update() );
	}
	
	override void onDraw()
	{
		gc.gameObjects.draw();
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
		gc.gameObjects.apply( go => go.shutdown() );
		gc.gameObjects.clearObjects();
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
