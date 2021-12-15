using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Movement : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }
    private float xRotation = 0.0f;
    private float yRotation = 0.0f;
    // Update is called once per frame
    public int yRotationMinLimit = -20;
    public int yRotationMaxLimit = 80;
    float ClampValue(float value, float min, float max)//控制旋转的角度
    {
        if (value < -360)
            value += 360;
        if (value > 360)
            value -= 360;
        return Mathf.Clamp(value, min, max);//限制value的值在min和max之间， 如果value小于min，返回min。 如果value大于max，返回max，否则返回value
    }

    void Update()
    {
        float scale = 0.2f;
        if (Input.GetKey(KeyCode.D))
        {
            gameObject.transform.Translate(scale, 0, 0);
        }

        if (Input.GetKey(KeyCode.A))
        {
            gameObject.transform.Translate(-scale, 0, 0);
        }
        if (Input.GetKey(KeyCode.W))
        {
            gameObject.transform.Translate(0, 0, scale);
        }

        if (Input.GetKey(KeyCode.S))
        {
            gameObject.transform.Translate(0, 0, -scale);
        }

        if (Input.GetKey(KeyCode.Q))
        {
            gameObject.transform.Translate(0, scale, 0);
        }

        if (Input.GetKey(KeyCode.E))
        {
            gameObject.transform.Translate(0, -scale, 0);
        }

        //Input.GetAxis("MouseX")获取鼠标移动的X轴的距离
        var xRotationSpeed = 250.0f;
        var yRotationSpeed = 120.0f;
        xRotation -= Input.GetAxis("Mouse X") * xRotationSpeed * 0.02f;
        yRotation += Input.GetAxis("Mouse Y") * yRotationSpeed * 0.02f;

        yRotation = ClampValue(yRotation, yRotationMinLimit, yRotationMaxLimit);//这个函数在结尾
                                                                                //欧拉角转化为四元数
        Quaternion rotation = Quaternion.Euler(-yRotation, -xRotation, 0);
        gameObject.transform.rotation = rotation;


        //Debug.Log(Input.GetAxis("Mouse X")*100000);
        //Debug.Log(Input.GetAxis("Mouse Y") * 100000);
    }
}
