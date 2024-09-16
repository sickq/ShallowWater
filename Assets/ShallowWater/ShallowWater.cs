using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

[ExecuteInEditMode]
public class ShallowWater : MonoBehaviour
{
    [Header("移动多远更新HeightMap的相机")]
    public float Distance2Render = 10;

    [Header("记录深度的Shader")]
    public Shader renderDepthShader;
    
    [Header("深度图的精度")]
    public int HeightMapSize = 512;

    [Header("浅水方程更新深度使用的CS")]
    public ComputeShader shallowWaterComputeShader;
    
    //水面Target
    public Transform WaterTarget;
    
    //需要计算深度的Renderer
    public List<Renderer> renderers;
    
    [Header("浅水方程迭代参数")]
    [Range(0, 1.0f)]
    public float Damping = 0.99f;
    
    [Range(0, 0.5f)]
    public float TravelSpeed = 0.45f;

    public RenderTexture DepthRenderTexture;

    private Material renderDepthMaterial;

    private Transform coreCameraTrans;
    private Vector2 lastCoreCameraPosXZ;
    private Vector2 cameraMoveXZ;
    private Vector2 coreCameraPosXZ;
    
    private Camera curCamera;
    private Vector3 curCameraPos;

    private RenderTexture heightMapRT;
    
    
    private ComputeBuffer bufferA;
    private ComputeBuffer bufferB;
    private ComputeBuffer bufferC;
    
    private ComputeBuffer bufferA2;
    private ComputeBuffer bufferB2;
    private ComputeBuffer bufferC2;
    
    private Queue<ComputeBuffer> bufferQueue = new Queue<ComputeBuffer>();
    private int csMainKernel;
    private int csUpdateBufferKernal;
    private CommandBuffer cmdBuffer;

    private Queue<ComputeBuffer> backupBufferQueue = new Queue<ComputeBuffer>();

    private void OnEnable() 
    {
        if (cmdBuffer == null)
        {
            cmdBuffer = new CommandBuffer { name = "ShallowWater" };
        }

        if (renderDepthMaterial != null)
        {
            DestroyObject(renderDepthMaterial);
        }
        renderDepthMaterial = new Material(renderDepthShader);
        
        csMainKernel = shallowWaterComputeShader.FindKernel("CSMain");
        csUpdateBufferKernal = shallowWaterComputeShader.FindKernel("UpdateBufferCS");

        curCamera = GetComponent<Camera>();
        curCamera.orthographic = true;
        curCamera.enabled = false;
        curCamera.aspect = 1;
        Camera coreCamera = Camera.main;
        if (coreCamera != null)
        {
            coreCameraTrans = coreCamera.transform;
        }

        if (coreCameraTrans != null)
        {
            if (DepthRenderTexture == null) 
            {
                DepthRenderTexture = new RenderTexture(HeightMapSize, HeightMapSize, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                DepthRenderTexture.enableRandomWrite = true;
                DepthRenderTexture.name = "ShallowDepthRT";
                Shader.SetGlobalTexture("_ShallowHeightMap", DepthRenderTexture);
            }

            bufferQueue.Clear();
            
            if (bufferA != null) bufferA.Release();
            if (bufferB != null) bufferB.Release();
            if (bufferC != null) bufferC.Release();
            
            if (bufferA2 != null) bufferA2.Release();
            if (bufferB2 != null) bufferB2.Release();
            if (bufferC2 != null) bufferC2.Release();

            int bufferDataCount = HeightMapSize * HeightMapSize;
            bufferA = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            bufferB = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            bufferC = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            
            bufferA2 = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            bufferB2 = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            bufferC2 = new ComputeBuffer(bufferDataCount, Marshal.SizeOf<float>());
            
            bufferQueue.Enqueue(bufferA);
            bufferQueue.Enqueue(bufferB);
            bufferQueue.Enqueue(bufferC);
            
            backupBufferQueue.Enqueue(bufferA2);
            backupBufferQueue.Enqueue(bufferB2);
            backupBufferQueue.Enqueue(bufferC2);
        }
    }

    private void OnDisable() 
    {
        cmdBuffer.Release();
        cmdBuffer = null;
        if (DepthRenderTexture != null)
        {
            DestroyObject(DepthRenderTexture);
            DepthRenderTexture = null;
        }

        if (bufferA != null) bufferA.Release();
        if (bufferB != null) bufferB.Release();
        if (bufferC != null) bufferC.Release();
        
        bufferQueue.Clear();
            
        if (bufferA2 != null) bufferA2.Release();
        if (bufferB2 != null) bufferB2.Release();
        if (bufferC2 != null) bufferC2.Release();
        
        backupBufferQueue.Clear();
        
        coreCameraTrans = null;
        
        if (renderDepthMaterial != null)
        {
            DestroyObject(renderDepthMaterial);
            renderDepthMaterial = null;
        }
    }
    
    private void Update()
    {
        Profiler.BeginSample("[ShallowWater]CPUUpdate");
        if (coreCameraTrans != null)
        {
            var orthographicSize = curCamera.orthographicSize * 2;

            bool shallowCameraMoved = UpdateCurCameraTrans();

            var position = transform.position;
            Shader.SetGlobalVector("_ShallowWaterParams", new Vector4(position.x, position.z, curCamera.farClipPlane, 1.0f / orthographicSize));
            
            cmdBuffer.Clear();
            cmdBuffer.BeginSample("[ShallowWater]DrawDepth");
            cmdBuffer.SetRenderTarget(DepthRenderTexture);
            cmdBuffer.ClearRenderTarget(true, true, Color.black);
            Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(curCamera.projectionMatrix, true);
            cmdBuffer.SetViewProjectionMatrices(curCamera.worldToCameraMatrix, projectionMatrix);
            foreach (var renderer in renderers)
            {
                cmdBuffer.DrawRenderer(renderer, renderDepthMaterial);
            }
            cmdBuffer.EndSample("[ShallowWater]DrawDepth");

            var current = bufferQueue.Dequeue();
            var pre = bufferQueue.Dequeue();
            var prepre = bufferQueue.Dequeue();
            
            cmdBuffer.SetComputeIntParam(shallowWaterComputeShader, "_ShallowWaterSize", HeightMapSize);

            //如果区域固定，可以考虑关掉这部分更新Buffer的CS消耗
            if (shallowCameraMoved)
            {
                cmdBuffer.BeginSample("[ShallowWater]UpdateBuffer");
                
                cmdBuffer.SetComputeVectorParam(shallowWaterComputeShader, "_ShallowBufferUpdateParams", new Vector4(cameraMoveXZ.x / orthographicSize, cameraMoveXZ.y / orthographicSize, 0, 0));
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "CurrentBuffer", current);
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "PrevBuffer", pre);
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "PrevPrevBuffer", prepre);

                backupBufferQueue.Enqueue(current);
                backupBufferQueue.Enqueue(pre);
                backupBufferQueue.Enqueue(prepre);

                current = backupBufferQueue.Dequeue();
                pre = backupBufferQueue.Dequeue();
                prepre = backupBufferQueue.Dequeue();
                
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "NewCurrentBuffer", current);
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "NewPrevBuffer", pre);
                cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csUpdateBufferKernal, "NewPrevPrevBuffer", prepre);
                
                cmdBuffer.DispatchCompute(shallowWaterComputeShader, csUpdateBufferKernal, HeightMapSize / 8 + 1, HeightMapSize / 8 + 1, 1);
                cmdBuffer.EndSample("[ShallowWater]UpdateBuffer");
            }
            
            bufferQueue.Enqueue(prepre);
            bufferQueue.Enqueue(current);
            bufferQueue.Enqueue(pre);
            
            cmdBuffer.BeginSample("[ShallowWater]UpdateHeight");
            cmdBuffer.SetComputeFloatParam(shallowWaterComputeShader, "Damping", Damping);
            cmdBuffer.SetComputeFloatParam(shallowWaterComputeShader, "TravelSpeed", TravelSpeed);
            
            cmdBuffer.SetComputeVectorParam(shallowWaterComputeShader, "_ShallowWaterParams", new Vector4(transform.position.x, transform.position.z, curCamera.farClipPlane, 1.0f / orthographicSize));
            
            cmdBuffer.SetComputeTextureParam(shallowWaterComputeShader, csMainKernel, "_ShallowHeightMap", DepthRenderTexture);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "CurrentBuffer", current);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "PrevBuffer", pre);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "PrevPrevBuffer", prepre);
            
            cmdBuffer.DispatchCompute(shallowWaterComputeShader, csMainKernel, HeightMapSize / 8 + 1, HeightMapSize / 8 + 1, 1);
            cmdBuffer.EndSample("[ShallowWater]UpdateHeight");
            
            Graphics.ExecuteCommandBuffer(cmdBuffer);

            WaterTarget.GetComponent<Renderer>().sharedMaterial.SetBuffer("_ShallowWaterBuffer", current);
            WaterTarget.GetComponent<Renderer>().sharedMaterial.SetInt("_ShallowWaterSize", HeightMapSize);
        }
        Profiler.EndSample();
    }

    //更新相机位置
    private bool UpdateCurCameraTrans()
    {
        coreCameraPosXZ.Set(coreCameraTrans.position.x, coreCameraTrans.position.z);
        float distance = Vector2.Distance(lastCoreCameraPosXZ, coreCameraPosXZ);
        
        bool curCameraMoved = false;
        
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            curCameraMoved = true;
        }
#endif
        if (Application.isPlaying && distance >= Distance2Render)
        {
            curCameraMoved = true;
        }

        if (curCameraMoved)
        {
            var position = coreCameraTrans.position;
            cameraMoveXZ.Set(position.x - lastCoreCameraPosXZ.x, position.z - lastCoreCameraPosXZ.y);
            curCameraPos.Set(position.x, WaterTarget.position.y, position.z);
            transform.position = curCameraPos;
            transform.rotation = Quaternion.Euler(90, 0, 0);
            lastCoreCameraPosXZ = coreCameraPosXZ;
        }

        return curCameraMoved;
    }
    
    public static void DestroyObject(Object obj)
    {
#if UNITY_EDITOR
        if (Application.isPlaying)
        {
            Object.Destroy(obj);
        }
        else
        {
            Object.DestroyImmediate(obj);
        }
#else
            Object.Destroy(obj);
#endif
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        var position = transform.position;
        Gizmos.DrawWireCube(new Vector3(position.x, position.y - curCamera.farClipPlane / 2, position.z), new Vector3(curCamera.orthographicSize * 2, curCamera.farClipPlane, curCamera.orthographicSize * 2));
    }
}
