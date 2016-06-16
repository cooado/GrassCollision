using UnityEngine;
using System.Collections.Generic;

[RequireComponent(typeof(MeshFilter))]
public class GrassCollision : MonoBehaviour {
	public float radiusInObjSpace;	// collision radius

	MeshFilter	mFilter;

	MeshCollisionControl	collisionCtrl;

	bool isCollisionEnabled = true;

	// Use this for initialization
	void Awake() {
		mFilter = this.GetComponent<MeshFilter> ();
		collisionCtrl = new MeshCollisionControl (mFilter.mesh, radiusInObjSpace);
	}

	void LateUpdate() {
		if (isCollisionEnabled) {
			collisionCtrl.updateMesh ();
		}
	}
		
	public void addCollistion(Vector3 wPos_){
		if (!isCollisionEnabled)
			return;
		
		float start = Time.realtimeSinceStartup;
		// convert to obj space
		Vector3 objPos = this.transform.InverseTransformPoint(wPos_);
		collisionCtrl.addCollision (objPos);

		Debug.Log ("cost time: " + (Time.realtimeSinceStartup - start));
	}

	void OnTriggerEnter(Collider other) {
		GrassCollisionGenerator generator = other.gameObject.GetComponent<GrassCollisionGenerator> ();
		if (generator == null)
			return;

		generator.setGrassCollision (this);
	}

	void OnTriggerExit(Collider other) {
		GrassCollisionGenerator generator = other.gameObject.GetComponent<GrassCollisionGenerator> ();
		if (generator == null)
			return;

		generator.setGrassCollision (null);
	}

	void OnBecameVisible(){
		isCollisionEnabled = true;
	}

	void OnBecameInvisible(){
		isCollisionEnabled = false;
	}
}

class MeshCollisionControl{
	Mesh mesh;

	float radiusInObjSpace;
	float radiusInObjSpaceSquare;

	float attenuationTime = 2;	// seconds to attenuate

	Vector3[] pos;		// readonly, not changed over time
	Vector3[] normals;	// [bulge, timeSinceLevelLoad]

	bool dirty = false;

	public MeshCollisionControl(Mesh m_, float radiusInObjSpace_){
		mesh = m_;
		radiusInObjSpace = radiusInObjSpace_;
		radiusInObjSpaceSquare = radiusInObjSpace * radiusInObjSpace;

		normals = mesh.normals;
		pos = mesh.vertices;
		for (int i = 0; i < normals.Length; ++i) {
			normals [i] = Vector3.zero;
//			Debug.Log (pos [i]);
		}
	}
		
	public void addCollision(Vector3 objPos_){
		float now = Time.timeSinceLevelLoad;
		for (int i = 0; i < normals.Length; ++i) {
			float x = pos [i].x;
			float z = pos [i].z;
			float distSpuare = (x - objPos_.x) * (x - objPos_.x) + (z - objPos_.z) * (z - objPos_.z);
			if (distSpuare <= radiusInObjSpaceSquare) {
				float bulge = normals [i].x;

				// update old bulge
				if (bulge > 0) {
					float elapsed = now - normals [i].y;
					if (elapsed >= attenuationTime || elapsed < 0) {
						bulge = 0;
					} else {
						bulge = bulge * (1 - elapsed / attenuationTime);
					}
				}

				// add collision bulge
				bulge += 5 * (1 - distSpuare / radiusInObjSpaceSquare);
				if (bulge > 5)
					bulge = 5;

				normals [i].x = bulge;

				// update time
				normals[i].y = now;

				dirty = true;
			}
		}
	}
		
	public void updateMesh(){
		if (dirty) {
			mesh.normals = normals;

			dirty = false;
		}
	}
}