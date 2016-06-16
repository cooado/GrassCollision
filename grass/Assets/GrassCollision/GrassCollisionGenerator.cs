using UnityEngine;
using System.Collections;

public class GrassCollisionGenerator : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}

	float lastGrassCollisionTime = 0;
	Vector3 lastGrassCollisionPos = Vector3.zero;

	void Update () {
		float grassCollisionCD = 0.1f;

		// do grass interaction only when grass collision exists
		if (grassCollision != null) {
			// check cd time
			float now = Time.timeSinceLevelLoad;
			if (now - lastGrassCollisionTime > grassCollisionCD) {
				// check if player moved
				Vector3 pos = this.transform.position;
				float dist = Vector3.Distance (pos, lastGrassCollisionPos);
				if (dist > 0.1) {
					grassCollision.addCollistion (pos);
					lastGrassCollisionTime = now;
					lastGrassCollisionPos = pos;
				}
			}
		}
	}

	GrassCollision grassCollision;
	public void setGrassCollision(GrassCollision grass_){
		grassCollision = grass_;
	}
}
