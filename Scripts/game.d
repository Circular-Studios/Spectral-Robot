module game;
import controller;

import core, graphics, components, utility;

// An easier way to access the game instance
@property RobotGhosts Game()
{
	return cast(RobotGhosts)DGame.instance;
}

shared class RobotGhosts : DGame
{
	public Controller gc;
	
	// Name that game
	@property override string title()
	{
		return "Spectral Robot Task Force";
	}
	
	override void onInitialize()
	{
		logInfo( "Initializing ", title, "..." );
		
		// setup a couple helper keys
		Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = EngineState.Quit; } );
		Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = EngineState.Reset; } );

		// initalize the controller
		gc = new shared Controller();
		
		// create a camera
		gc.level.camera = gc.level[ "Camera" ].camera;

		// create the ui
		/*ui = new shared UserInterface( Config.get!uint( "Display.Width" ),
		                               Config.get!uint( "Display.Height" ), 
		                               Config.get!string( "UserInterface.FilePath" ) 
		                             );*/
	}
	
	override void onUpdate()
	{
		//ui.update();
	}
	
	override void onDraw()
	{
		//ui.draw();
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
