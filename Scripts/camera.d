module camera;
import core, utility;
import std.algorithm;

/// Camera movement around the scene
shared class Camera : GameObject
{
	float moveSpeed = 50;
	
	override void onUpdate()
	{	
		// 4-directional movement
		if( Input.getState( "LookUp" ) )
		{
			this.transform.position.z -= moveSpeed * Time.deltaTime;
		}
		else if( Input.getState( "LookDown" ) )
		{
			this.transform.position.z += moveSpeed * Time.deltaTime;
		}
		
		if( Input.getState( "LookLeft" ) )
		{
			this.transform.position.x -= moveSpeed * Time.deltaTime;
		}
		else if( Input.getState( "LookRight" ) )
		{
			this.transform.position.x += moveSpeed * Time.deltaTime;
		}
		
		// change distance from floor
		if( Input.getState( "ZoomUp" ) )
		{
			this.transform.position.y -= moveSpeed * Time.deltaTime;
		}
		else if( Input.getState( "ZoomDown" ) )
		{
			this.transform.position.y += moveSpeed * Time.deltaTime;
		}
	}
}
