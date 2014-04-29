module camera;
import game, grid;
import core, components.behavior, graphics, utility;
import std.algorithm;
import gl3n.linalg, gl3n.math, gl3n.interpolate;

class AdvancedCameraFields
{
	float MoveSpeed;
	uint RotateTime;
	float ZoomSpeed;
	float EdgeDistance;
	float MinHeight;
	float MaxHeight;
}

/// Camera movement around the scene
shared class AdvancedCamera : Behavior!AdvancedCameraFields
{
	float moveSpeed;
	Duration rotateTime;
	float zoomSpeed;
	float edgeDistance;
	float minHeight;
	float maxHeight;
	float minX;
	float maxX;
	float minZ;
	float maxZ;
	bool clamped = false;

	override void onInitialize()
	{
		owner.transform.position.y = (( maxHeight - minHeight ) / 2) + minHeight;
		startPos = owner.transform.position;
		startRot = owner.transform.rotation;
	}
	
	override void onUpdate()
	{	
		if( Input.getState("LookLeft") && !turning )
		{
			turning = true;
			auto startTime = Time.totalTime;

			auto prevFace = owner.transform.forward;
			prevFace *= -owner.transform.position.y / prevFace.y;

			auto lookPos = owner.transform.position + prevFace;
			auto nextFace = prevFace * quat.identity.rotatey( -90.radians );
			auto prevRot = owner.transform.rotation;
			auto nextRot = prevRot.rotatey( -90.radians );
			prevRot = owner.transform.rotation;
			
			scheduleTimedTask( rotateTime, 
			{
				auto curFaceXZ = slerp( prevFace.xz, nextFace.xz, 
				       	min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

				auto curFace = shared vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
				owner.transform.position = lookPos - curFace;

				owner.transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
				if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
			} );
		}
		if( Input.getState("LookRight") && !turning )
		{
						turning = true;
			auto startTime = Time.totalTime;

			auto prevFace = owner.transform.forward;
			prevFace *= -owner.transform.position.y / prevFace.y;
			
			auto lookPos = owner.transform.position + prevFace;
			auto nextFace = prevFace * quat.identity.rotatey( 90.radians );
			auto prevRot = owner.transform.rotation;
			auto nextRot = prevRot.rotatey( 90.radians );
			prevRot = owner.transform.rotation;
			scheduleTimedTask( rotateTime, 
			{
				auto curFaceXZ = slerp( prevFace.xz, nextFace.xz, 
				       	min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

				auto curFace = shared vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
				owner.transform.position = lookPos - curFace;

				owner.transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
				if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
			} );
		}

		shared vec2 mouse = Input.mousePos;
		// Left of the screen
		if( mouse.x < edgeDistance )
		{
			auto moveVec = -owner.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			owner.transform.position += moveVec;
		} // Bottom of the screen
		if( mouse.y < edgeDistance )
		{
			auto moveVec = -owner.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			owner.transform.position += moveVec;
		} // Right
		if( mouse.x > Graphics.width - edgeDistance )
		{
			auto moveVec = owner.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			owner.transform.position += moveVec;
		} // Top
		if( mouse.y > Graphics.height - edgeDistance )
		{
			auto moveVec = owner.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			owner.transform.position += moveVec;
		}

		if( clamped )
			clampLookPos();

		if( Input.getState( "ZoomIn" ) )
		{
			owner.transform.position += owner.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( minHeight - owner.transform.position.y ) / owner.transform.forward.y );
		}
		else if( Input.getState( "ZoomOut" ) )
		{
			owner.transform.position += -owner.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( maxHeight - owner.transform.position.y ) / -owner.transform.forward.y );
		}

		if( Input.getState( "ResetCamera" ) )
		{
			owner.transform.position = startPos;
			owner.transform.rotation = startRot;
		}
	}

	void autoClamp()
	{
		minX = Game.grid.transform.position.x;
		minZ = Game.grid.transform.position.z;
		maxX = minX + ( Game.grid.gridX * TILE_SIZE );
		maxZ = minZ + ( Game.grid.gridY * TILE_SIZE );
		clamped = true;
	}

	shared(vec3) lookatPos()
	{
		return owner.transform.position + ( owner.transform.forward * ( -owner.transform.position.y  / owner.transform.forward.y ) );
	}

	void clampLookPos()
	{
		if( lookatPos.x < minX )
		{
			logDebug("Clamping at minX");
			owner.transform.position.x += minX - lookatPos.x;
		}
		if( lookatPos.x > maxX )
		{
			logDebug("Clamping at maxX");
			owner.transform.position.x -= lookatPos.x - maxX;
		}
		if( lookatPos.z < minZ )
		{
			logDebug("Clamping at minZ");
			owner.transform.position.z += minZ - lookatPos.z;
		}
		if( lookatPos.z > maxZ )
		{
			logDebug("Clamping at maxZ");
			owner.transform.position.z -= lookatPos.z - maxZ;
		}
	}

private:
	bool turning;

	vec3 startPos;
	quat startRot;
}
