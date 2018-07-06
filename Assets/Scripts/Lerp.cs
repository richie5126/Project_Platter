using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Lerp : MonoBehaviour {

	// Use this for initialization
    public Transform thing;
    public Vector4 SmoothOffset;
    public Vector3 FixedOffset;
    public bool mouseControl = false;
	void Start () {
	}
	
	// Update is called once per frame
    private Vector3 _pos = new Vector3();
    void Update()
    {
        if (thing == null) thing = GameObject.Find("CRSplineTarget").transform;
    }
	void FixedUpdate () {
        if (thing == null) return;
        transform.rotation = Quaternion.Lerp(transform.rotation, thing.rotation, SmoothOffset.w * Time.deltaTime);

        _pos.x = Mathf.Lerp(transform.position.x, thing.position.x + FixedOffset.x, SmoothOffset.x * Time.deltaTime);
        _pos.y = Mathf.Lerp(transform.position.y, thing.position.y + FixedOffset.y, SmoothOffset.y * Time.deltaTime);
        _pos.z = Mathf.Lerp(transform.position.z, thing.position.z + FixedOffset.z, SmoothOffset.z * Time.deltaTime);
        transform.position = _pos;

        if (mouseControl)
        {
        }
	}
}
