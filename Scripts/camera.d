module camera;
import core, utility;
import std.algorithm;

/// Camera movement around the scene
shared class Camera : GameObject
{
	float moveSpeed = 0.15;
	
	override void onUpdate()
	{	
		// 4-directional movement
		if( Input.getState( "LookUp" ) )
		{
			this.transform.position.z -= moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
		else if( Input.getState( "LookDown" ) )
		{
			this.transform.position.z += moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
		
		if( Input.getState( "LookLeft" ) )
		{
			this.transform.position.x -= moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
		else if( Input.getState( "LookRight" ) )
		{
			this.transform.position.x += moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
		
		// change distance from floor
		if( Input.getState( "ZoomUp" ) )
		{
			this.transform.position.y -= moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
		else if( Input.getState( "ZoomDown" ) )
		{
			this.transform.position.y += moveSpeed * max( Time.deltaTime.total!"msecs"(), 1 );
		}
	}
}
