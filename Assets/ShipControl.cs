using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class ShipControl : MonoBehaviour {

	// Use this for initialization
    public float throttle = 3.0f;
    public float handling = 3.0f;
    public float hoverHeight = 10.0f;
    public float hoverForce = 2.0f;
    public float stabilizationFactor = 0.4f;
    public float verticalStabilizationFactor = 10.0f;
    public float maxVelocity = 30.0f;
    public float maxPitch = 15.0f;
    private Rigidbody _rb;

    public ParticleSystem[] thrusters;
    public ParticleSystem DustKickupParticleSystem;
    private ParticleSystem.EmissionModule dustValues;
    private ParticleSystem.EmissionModule thrustValues;

	void Start () {
        _rb = GetComponent<Rigidbody>();
        if (DustKickupParticleSystem != null) dustValues = DustKickupParticleSystem.emission;
	}

	// Update is called once per frame
    RaycastHit hitResult;

    [SerializeField]
    private float _angleWGround;

    void Update()
    {
        if (Input.GetButtonDown("Cancel")) UnityEngine.SceneManagement.SceneManager.LoadSceneAsync(UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex);

        float thrustPSFactor = (Vector3.Dot(transform.forward, _rb.velocity) / maxVelocity) * 30.0f;
        _angleWGround = thrustPSFactor;
        for(int i = 0; i < thrusters.Length; ++i)
        {
            if (thrusters[i] == null) continue;
            thrustValues = thrusters[i].emission;
            thrustValues.rateOverTimeMultiplier = thrustPSFactor;
        }
    }
	void FixedUpdate () {
        //_rb.AddForce(transform.up * 6.0f * Time.deltaTime);
        _rb.AddForce(transform.forward * Input.GetAxis("LeftStickVertical") * throttle * _rb.mass * Time.deltaTime);
        _rb.AddTorque(transform.up * Input.GetAxis("LeftStickHorizontal") * handling * 0.5f * _rb.mass * Time.deltaTime);
        _rb.AddTorque(transform.forward * -Input.GetAxis("LeftStickHorizontal") * handling * 0.8f * _rb.mass * Time.deltaTime);


        _rb.AddForce(Camera.main.transform.right * Input.GetAxis("RightStickHorizontal") * throttle * 0.25f * _rb.mass * Time.deltaTime);

        if (Physics.Raycast(transform.position, -transform.up, out hitResult, hoverHeight * 4.0f))
        {

            if (Vector3.Angle(transform.up, hitResult.normal) >= maxPitch)
                _rb.AddTorque(transform.forward * Input.GetAxis("Horizontal") * handling * 0.8f * _rb.mass * Time.deltaTime);

            float distanceMagnifiedForce = ((hoverHeight / 1.0f) / hitResult.distance);

            //stabilizers
            _rb.AddTorque(transform.right * Vector3.SignedAngle(transform.up, hitResult.normal, transform.right) * hitResult.distance * stabilizationFactor * Time.deltaTime);
            _rb.AddTorque(transform.forward * Vector3.SignedAngle(transform.up, hitResult.normal, transform.forward) * hitResult.distance * stabilizationFactor * Time.deltaTime);
            //hovering force w stabilization

            _rb.AddForce((transform.up * distanceMagnifiedForce * hoverForce * Time.deltaTime)
                - (transform.up * Vector3.Dot(_rb.velocity.normalized, transform.up) * verticalStabilizationFactor * Time.deltaTime));


            if (DustKickupParticleSystem != null)
            {
                DustKickupParticleSystem.transform.position = hitResult.point;
                dustValues.rateOverTimeMultiplier = 100.0f * distanceMagnifiedForce * (_rb.velocity.magnitude / maxVelocity);
            }
        }
        else dustValues.rateOverTimeMultiplier = 0.0f;

        if (Vector3.Dot(transform.forward, _rb.velocity) > maxVelocity) _rb.AddForce(-transform.forward * Vector3.Dot(transform.forward, _rb.velocity));
        //Debug.Log(_rb.velocity.magnitude);
	}
}
