module game;
import controller, grid, turn, action, ability, unit, camera;
import core, graphics, components, utility;
import speed;

// An easier way to access the game instance
@property RobotGhosts Game()
{
	return cast(RobotGhosts)DGame.instance;
}

/// The base game class
shared class RobotGhosts : DGame
{
public:
	Controller gc; // the game controller
	Scene level; // The active scene in the engine
	Grid grid; // The grid in the level
	Turn turn; // The turn controller
	Ability[ uint ] abilities; // The abilities
	Unit[] units; // The units
	Connection serverConn; // the server connection
	
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
		
		// initalize stuff
		level = new shared Scene();
		this.activeScene = level;
		grid = new shared Grid();
		turn = new shared Turn();
		
		// add the grid to the level
		Game.grid.name = "Grid";
		Game.level.addChild( grid );
		
		// get the game loaded
		gc = new shared Controller();
		
		// create a camera
		shared AdvancedCamera cam = cast(shared AdvancedCamera)level[ "Camera" ];
		cam.autoClamp();
		level.camera = cam.camera;

		
		// bind 'r' to server connect
		Input.addKeyDownEvent( Keyboard.R, kc => connect() );
		
		// create the ui
		/*ui = new shared UserInterface( Config.get!uint( "Display.Width" ),
		 Config.get!uint( "Display.Height" ), 
		 Config.get!string( "UserInterface.FilePath" ) 
		 );*/
	}
	
	/// Connect to the server
	void connect()
	{
		if( serverConn )
			serverConn.close();
		serverConn = Connection.open( Config.get!string( "Game.ServerIP" ), false, ConnectionType.TCP );
		serverConn.onReceiveData!string ~= msg => logInfo( "Server Message: ", msg );
		serverConn.onReceiveData!Action ~= action => turn.doAction( action );
		serverConn.send!string( "New connection.", ConnectionType.TCP );
	}
	
	override void onUpdate()
	{
		//ui.update();
		try
		{
			if( serverConn )
				serverConn.update();
		}
		catch( Exception e )
		{
			logInfo( "Error: ", e.msg );
		}
	}
	
	override void onDraw()
	{
		//ui.draw();
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
		if( serverConn )
			serverConn.close();
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
