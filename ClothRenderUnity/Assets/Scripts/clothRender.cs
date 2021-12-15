using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using System;
using UnityEngine.Rendering;

public class clothRender : MonoBehaviour
{
	public float _controlpointScale = 0.1f;
	public bool _showControlPoints = true;

	Transform[] _controlPoints = new Transform[16];
	ComputeBuffer _buffer;


    string bccFileName = "C:/Users/fuxihao/Desktop/ClothRenderingUnity/ClothRenderUnity/Assets/Models/dress1.bcc";
    [DllImport("BCCFileReader", EntryPoint = "ReadBCCFile")]
	public static unsafe extern int ReadBCCFile(string fileName, Vector3* vertexBuffer, int* indexBuffer, ref int vertexNum, ref int indexNum);


	void Awake()
	{
		Mesh mesh = new Mesh();

		int vNum = 0;
		int iNum = 0;
		Vector3[] vertices = new Vector3[10000000];
		int[] indices = new int[10000000];
        unsafe
        {
            //Pin array then send to C++
            fixed (Vector3* vecPtr = vertices)
            {
                fixed (int* indPtr = indices)
                {
                    ReadBCCFile(bccFileName, vecPtr, indPtr, ref vNum, ref iNum);
                }
            }
        }

        Array.Resize<Vector3>(ref vertices, vNum);
        Array.Resize<int>(ref indices, iNum);


        mesh.indexFormat = IndexFormat.UInt32;

        mesh.vertices = vertices;
        mesh.SetIndices(indices, MeshTopology.Quads, 0);
        //mesh.SetIndices(indices, MeshTopology.Points, 0);// for debug
        mesh.bounds = new Bounds(Vector3.zero, 10000000 * Vector3.one);
		GetComponent<MeshFilter>().mesh = mesh;

        
	}

	// Start is called before the first frame update
	void Start()
    {
		//Vector3[] arr = new Vector3[16];
		//for (int i = 0; i < arr.Length; i++)
		//{
		//	_controlPoints[i].localScale = Vector3.one * _controlpointScale;
		//	_controlPoints[i].GetComponent<Renderer>().enabled = true;
		//	arr[i] = _controlPoints[i].localPosition;
		//}

		//_buffer.SetData(arr);
		//GetComponent<Renderer>().material.SetBuffer("_controlPoints", _buffer);
	}

    // Update is called once per frame
    void Update()
    {
        
    }
}
