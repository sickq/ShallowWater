using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
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
    public List<Renderer> objRenderers;
    
    //边缘水面反弹的Renderer
    public List<Renderer> boundRenderers;
    
    [Header("浅水方程迭代参数")]
    [Range(0, 1.0f)]
    public float Damping = 0.99f;
    
    [Range(0, 0.5f)]
    public float TravelSpeed = 0.45f;

    [Range(0, 5)]
    public float ShallowWaterMaxDepth = 1;

    public RenderTexture ObjDepthRenderTexture;
    public RenderTexture BoundDepthRenderTexture;
    public RenderTexture ShallowWaterHeightRT;

    private Material renderDepthMaterial;

    private Transform coreCameraTrans;
    private Vector2 lastCoreCameraPosXZ;
    private Vector2 cameraMoveXZ;
    private Vector2 coreCameraPosXZ;
    
    private Camera curCamera;
    private Vector3 curCameraPos;
    
    private ComputeBuffer bufferA;
    private ComputeBuffer bufferB;
    private ComputeBuffer bufferC;
    
    private ComputeBuffer bufferA2;
    private ComputeBuffer bufferB2;
    private ComputeBuffer bufferC2;
    
    private Queue<ComputeBuffer> bufferQueue = new Queue<ComputeBuffer>();
    private Queue<ComputeBuffer> backupBufferQueue = new Queue<ComputeBuffer>();
    
    private int csMainKernel;
    private int csUpdateBufferKernal;
    private CommandBuffer cmdBuffer;

    private void OnEnable()
    {
        if (!SystemInfo.supportsComputeShaders)
        {
            this.enabled = false;
            Debug.LogError("UnSupport ComputeShaders");
            return;
        }
        
        if (cmdBuffer == null)
        {
            cmdBuffer = new CommandBuffer { name = "ShallowWater" };
        }

        ShallowWaterUtils.ReleaseMaterial(renderDepthMaterial);
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
            ShallowWaterUtils.ReleaseRT(ObjDepthRenderTexture);
            ObjDepthRenderTexture = new RenderTexture(HeightMapSize, HeightMapSize, 16, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);
            ObjDepthRenderTexture.name = "_ObjShallowDepthRT";
            ObjDepthRenderTexture.Create();

            ShallowWaterUtils.ReleaseRT(BoundDepthRenderTexture);
            BoundDepthRenderTexture = new RenderTexture(HeightMapSize, HeightMapSize, 16, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);
            BoundDepthRenderTexture.name = "_BoundShallowDepthRT";
            BoundDepthRenderTexture.Create();

            ShallowWaterUtils.ReleaseRT(ShallowWaterHeightRT);
            ShallowWaterHeightRT = new RenderTexture(HeightMapSize + 2, HeightMapSize + 2, 0, GraphicsFormat.R32_SFloat, 0);
            ShallowWaterHeightRT.enableRandomWrite = true;
            ShallowWaterHeightRT.name = "_ShallowWaterHeightRT";
            ShallowWaterHeightRT.Create();
            Shader.SetGlobalTexture("_ShallowWaterHeightRT", ShallowWaterHeightRT);

            bufferQueue.Clear();
            backupBufferQueue.Clear();
            
            ShallowWaterUtils.ReleaseComputeBuffer(bufferA);
            ShallowWaterUtils.ReleaseComputeBuffer(bufferB);
            ShallowWaterUtils.ReleaseComputeBuffer(bufferC);

            ShallowWaterUtils.ReleaseComputeBuffer(bufferA2);
            ShallowWaterUtils.ReleaseComputeBuffer(bufferB2);
            ShallowWaterUtils.ReleaseComputeBuffer(bufferC2);

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
        ShallowWaterUtils.ReleaseRT(ObjDepthRenderTexture);
        ShallowWaterUtils.ReleaseRT(BoundDepthRenderTexture);
        ShallowWaterUtils.ReleaseRT(ShallowWaterHeightRT);

        ShallowWaterUtils.ReleaseComputeBuffer(bufferA);
        ShallowWaterUtils.ReleaseComputeBuffer(bufferB);
        ShallowWaterUtils.ReleaseComputeBuffer(bufferC);

        ShallowWaterUtils.ReleaseComputeBuffer(bufferA2);
        ShallowWaterUtils.ReleaseComputeBuffer(bufferB2);
        ShallowWaterUtils.ReleaseComputeBuffer(bufferC2);

        bufferQueue.Clear();
        backupBufferQueue.Clear();
        
        coreCameraTrans = null;

        ShallowWaterUtils.ReleaseMaterial(renderDepthMaterial);
    }

    private readonly List<Renderer> outputRenderers = new List<Renderer>();
    private List<Renderer> GetObjMovedRenderers(bool force = false)
    {
        if (force)
        {
            return objRenderers;
        }
        outputRenderers.Clear();

        foreach (var item in objRenderers)
        {
            if (item.enabled && item.gameObject.activeInHierarchy && item.transform.hasChanged)
            {
                outputRenderers.Add(item);
                item.transform.hasChanged = false;
            }
        }

        return outputRenderers;
    }
    
    private List<Renderer> GetBoundRenderers(bool force = false)
    {
        if (force)
        {
            return boundRenderers;
        }
        outputRenderers.Clear();

        foreach (var item in boundRenderers)
        {
            if (item.enabled && item.gameObject.activeInHierarchy && item.transform.hasChanged)
            {
                outputRenderers.Add(item);
                item.transform.hasChanged = false;
            }
        }

        return outputRenderers;
    }

    private void LateUpdate()
    {
        Profiler.BeginSample("[ShallowWater]CPUUpdate");
        if (coreCameraTrans != null)
        {
            var orthographicSize = curCamera.orthographicSize * 2;

            bool shallowCameraMoved = UpdateCurCameraTrans();

            var position = transform.position;
            Shader.SetGlobalVector("_ShallowWaterParams", new Vector4(position.x, position.z, curCamera.farClipPlane, 1.0f / orthographicSize));
            
            cmdBuffer.Clear();
            bool force = true;
            cmdBuffer.BeginSample("[ShallowWater]DrawObjMoveDepth");
            cmdBuffer.SetRenderTarget(ObjDepthRenderTexture);
            cmdBuffer.ClearRenderTarget(true, true, Color.black);
            var movedRenderers = GetObjMovedRenderers(shallowCameraMoved);
            if (movedRenderers.Count > 0)
            {
                Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(curCamera.projectionMatrix, true);
                cmdBuffer.SetViewProjectionMatrices(curCamera.worldToCameraMatrix, projectionMatrix);
                foreach (var renderer in movedRenderers)
                {
                    cmdBuffer.DrawRenderer(renderer, renderDepthMaterial);
                }
            }
            cmdBuffer.EndSample("[ShallowWater]DrawObjMoveDepth");

            var boundRenderers = GetBoundRenderers(shallowCameraMoved);
            if (boundRenderers.Count > 0)
            {
                cmdBuffer.BeginSample("[ShallowWater]DrawBoundDepth");
                cmdBuffer.SetRenderTarget(BoundDepthRenderTexture);
                cmdBuffer.ClearRenderTarget(true, true, Color.black);
                Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(curCamera.projectionMatrix, true);
                cmdBuffer.SetViewProjectionMatrices(curCamera.worldToCameraMatrix, projectionMatrix);
                foreach (var renderer in boundRenderers)
                {
                    cmdBuffer.DrawRenderer(renderer, renderDepthMaterial);
                }
                cmdBuffer.EndSample("[ShallowWater]DrawBoundDepth");
            }

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
            
            cmdBuffer.SetComputeVectorParam(shallowWaterComputeShader, "_ShallowWaterParams1", new Vector4(curCamera.farClipPlane, -ShallowWaterMaxDepth, 0, 1.0f / orthographicSize));
            
            cmdBuffer.SetComputeTextureParam(shallowWaterComputeShader, csMainKernel, "_ShallowObjDepthTexture", ObjDepthRenderTexture);
            cmdBuffer.SetComputeTextureParam(shallowWaterComputeShader, csMainKernel, "_ShallowBoundDepthTexture", BoundDepthRenderTexture);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "CurrentBuffer", current);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "PrevBuffer", pre);
            cmdBuffer.SetComputeBufferParam(shallowWaterComputeShader, csMainKernel, "PrevPrevBuffer", prepre);
            cmdBuffer.SetComputeTextureParam(shallowWaterComputeShader, csMainKernel, "_ShallowWaterHeightRT", ShallowWaterHeightRT);

            cmdBuffer.DispatchCompute(shallowWaterComputeShader, csMainKernel, HeightMapSize / 8 + 1, HeightMapSize / 8 + 1, 1);
            cmdBuffer.EndSample("[ShallowWater]UpdateHeight");
            
            Graphics.ExecuteCommandBuffer(cmdBuffer);

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

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        var position = transform.position;
        Gizmos.DrawWireCube(new Vector3(position.x, position.y - curCamera.farClipPlane / 2, position.z), new Vector3(curCamera.orthographicSize * 2, curCamera.farClipPlane, curCamera.orthographicSize * 2));
    }
}

public class ShallowWaterUtils
{
    public static void ReleaseRT(RenderTexture rt)
    {
        if (rt != null)
        {
            rt.Release();
        }
    }

    public static void ReleaseComputeBuffer(ComputeBuffer buffer)
    {
        if (buffer != null)
        {
            buffer.Release();
        }
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
    
    public static void ReleaseMaterial(Material material)
    {
        if (material != null)
        {
            DestroyObject(material);
            material = null;
        }
    }
}

public class RTPingPongBuffer
{
    private RenderTexture rt1;
    private RenderTexture rt2;

    private bool rt1IsFront = true;
    public RenderTexture frontRT => rt1IsFront ? rt1 : rt2;
    public RenderTexture backRT => rt1IsFront ? rt2 : rt1;

    public RTPingPongBuffer(string name, int width, int height, int depth, GraphicsFormat format, bool randomWrite = false, int mipmap = 0)
    {
        rt1 = new RenderTexture(width, height, depth, format, mipmap);
        rt1.enableRandomWrite = randomWrite;
        rt1.name = name + "_Buffer1";
        rt1.Create();
        rt2 = new RenderTexture(width, height, depth, format, mipmap);
        rt2.name = name + "_Buffer2";
        rt2.enableRandomWrite = randomWrite;
        rt2.Create();
    }

    public void Dispose()
    {
        rt1.Release();
        rt1 = null;
        
        rt2.Release();
        rt2 = null;
    }
    
    public void SwapBuffer()
    {
        rt1IsFront = !rt1IsFront;
    }
}