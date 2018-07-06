using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CRSplineFollower : MonoBehaviour {

	// Use this for initialization
    public float speed = 0.2f;
    public CatmullRomSpline spline;
    private int currentP = 0;
    private float currentU = 0;
    private Vector3 TargetPosition;
	void Start () {
        if (spline != null) TargetPosition = spline.GetNextCatmullRomPosition(ref currentP, ref currentU);
	}
	
	// Update is called once per frame
    Vector3 moveDelta;
	void Update () {
        if ((TargetPosition - transform.position).sqrMagnitude < 0.04f) TargetPosition = spline.GetNextCatmullRomPosition(ref currentP, ref currentU);
        moveDelta = Vector3.MoveTowards(transform.position, TargetPosition, speed * Time.deltaTime);
        transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(TargetPosition - transform.position), 0.5f * Time.deltaTime);
        transform.position = moveDelta;
	}
}
