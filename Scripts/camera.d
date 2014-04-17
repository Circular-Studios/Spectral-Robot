module camera;
import core, graphics, utility;
import std.algorithm;
import gl3n.linalg, gl3n.math;

/// Camera movement around the scene
shared class Camera : GameObject
{
	float moveSpeed = 150;
	float rotateSpeed = 45.radians;
	float edgeDistance = 50;
	
	override void onUpdate()
	{	
		if( Input.getState("LookLeft"))
		{
			this.transform.rotation.rotatey( rotateSpeed * Time.deltaTime );
		}
		if( Input.getState("LookRight"))
		{
			this.transform.rotation.rotatey( -rotateSpeed * Time.deltaTime );
		}

		shared vec2 mouse = Input.mousePos;
		if( mouse.x < edgeDistance )
		{
			auto moveVec = -this.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		}
		if( mouse.y < edgeDistance )
		{
			auto moveVec = this.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		}
		if( mouse.x > Graphics.width - edgeDistance )
		{
			auto moveVec = this.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		}
		if( mouse.y > Graphics.height - edgeDistance )
		{
			auto moveVec = -this.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		}

	}
}
