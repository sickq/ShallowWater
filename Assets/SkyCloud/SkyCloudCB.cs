using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class SkyCloudCB : MonoBehaviour
{
    public RenderTexture _SkyCloudLowRes;

    public Shader SkyCloudShader;

    [Range(0, 10)] public int SkyCloudDownScale = 4;
    
    //SunLightDir 区分主光源，计算大气+体积云的光源
    public Light SunLight;
    public Camera camera;


    [Header("天空云的高度"), Range(0, 2000)]public float SkyCloudHeight = 250;
    public Vector3 SkyCloudScale = new Vector3(20000, 100, 20000);

    public Texture2DArray WorleyNoiseTex;
    public Texture2D PerlinForSkyCloudTex;
    public Texture2D PerlinToDilateWorley;
    
    [ColorUsage(false, true)] public Color SunColor = new Color(7.5f, 7.5f, 7.5f, 7.5f);
    [ColorUsage(false, true)] public Color EnvColor = new Color(72.3f, 72.3f, 72.3f, 72.3f);
    [ColorUsage(false, true)] public Color DarkColor = new Color(0.13512f, 0.20625f, 0.30227f, 0.19805f);

    [Range(0, 20)] public float perlinForSkyCloudNoiseScale = 6.5f;
    [Range(0, 20)] public float perlinToDilateWorleyNoiseScale = 10.0f;
    
    [Range(-20, 20)] public float perlinNoiseSpeedX = 0.01f;
    [Range(-20, 20)] public float perlinNoiseSpeedZ = 0.01f;
    [Range(-2, 2)] public float perlinToDilateWorleyWeight = 0.66f;
    [Range(-2, 2)] public float perlinNoiseWeight = 0.61865f;
    [Range(-2, 2)] public float perlinNoiseYWeight = 1.0f;
    [Range(-10, 10)] public float perlinNoiseYParam = 2.0f;

    [Range(0.001f, 2)] public float perlinNoisePow = 0.838f;
    
    [Range(-5, 5)] public float WorleyNoiseYScale = 1.30667f;
    [Range(-5, 5)] public float WorleyNoiseXSpeed = 0.01f;
    [Range(-5, 5)] public float WorleyNoiseYSpeed = 0.01f;
    [Range(-5, 5)] public float WorleyNoiseZSpeed = 0.01f;
    
    [Range(0.001f, 2)] public float WorleyNoiseWeight = 0.55f;


    [Header("最大步进次数"), Range(0, 50)] public int maxRayStep = 20;
    [Header("步进偏移"), Range(0, 2)] public float rayOffset = 1.0f;
    [Range(0.0001f, 1)] public float rayScale = 0.03f;

    [Header("光照步进次数"), Range(0, 10)] public int SubRayStepCount = 2;
    [Header("光照步进距离"), Range(0, 20)] public int SubRayStepLength = 14;
    [Header("光照传输"), Range(0, 20)] public int SubRayLightTrans = 15;
    
    [Header("光照噪声Param"), Range(-1, 1)] public float lightNoiseParam = 0.24f;
    
    [Header("云透射Pow,伪造"), Range(0, 10)] public float _FakeCloudTransmittancePow = 0.10f;
    [Header("云透射权重,伪造"), Range(0, 10)] public float _FakeCloudTransmittanceWeight = 0.30f;
    [Header("云透射权重,伪造"), Range(0, 2)] public float _FakeCloudTransmittanceOffset = 0.50f;

    private CommandBuffer cmdBuffer;
    private Material SkyCloudMat;

    #region  Generate UnitCubeMesh

    private Mesh unitCubeMesh;
    private Mesh UnitCubeMesh
    {
        get
        {
            if (unitCubeMesh == null)
            {
                unitCubeMesh = new Mesh();
                Vector3[] vertices = 
                {
                    new Vector3(-0.5f, -0.5f, -0.5f),
                    new Vector3(0.5f, -0.5f, -0.5f),
                    new Vector3(0.5f, 0.5f, -0.5f),
                    new Vector3(-0.5f, 0.5f, -0.5f),
                    new Vector3(-0.5f, 0.5f, 0.5f),
                    new Vector3(0.5f, 0.5f, 0.5f),
                    new Vector3(0.5f, -0.5f, 0.5f),
                    new Vector3(-0.5f, -0.5f, 0.5f)
                };
                
                int[] triangles = {
                    0, 2, 1, //face front
                    0, 3, 2,
                    2, 3, 4, //face top
                    2, 4, 5,
                    1, 2, 5, //face right
                    1, 5, 6,
                    0, 7, 4, //face left
                    0, 4, 3,
                    5, 4, 7, //face back
                    5, 7, 6,
                    0, 6, 7, //face bottom
                    0, 1, 6
                };
                
                unitCubeMesh.vertices = vertices;
                unitCubeMesh.triangles = triangles;
                unitCubeMesh.RecalculateNormals();
                unitCubeMesh.RecalculateBounds();
                unitCubeMesh.UploadMeshData(false);
            }

            return unitCubeMesh;
        }
    }

    #endregion
    
    
    private void OnEnable()
    {
        PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
        cmdBuffer = new CommandBuffer(){name = "SkyCloud"};

        PipelineUtils.ReleaseMaterial(ref SkyCloudMat);
        SkyCloudMat = new Material(SkyCloudShader);
    }

    private void OnDisable()
    {
        PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
        PipelineUtils.ReleaseRT(ref _SkyCloudLowRes);
        PipelineUtils.ReleaseMaterial(ref SkyCloudMat);
        Shader.DisableKeyword("SKY_CLOUD_ENABLED");
    }

    private Vector3 unitCubePosition;
    private Vector4 perlinOffsetAndScaleVec;
    private Vector4 worleyOffsetAndScaleVec;
    private Vector4 worley2Param;
    private Vector4 cloudNoiseParam;
    private Vector3 skyCloudInvScale;
    private Vector3 startPosOS;
    private Vector4 sampleParam;
    private Vector4 subRayParam;
    private Vector4 subRayStep;
    private Vector4 extraParam1;

    private Vector4 fakeCloudTransmittanceParam;

    private Vector4 skyCloudViewportScale;
    private Vector4 blendCloudFogParam;
    
    private float currentTime = 0;
    void LateUpdate()
    {
        int width = camera.pixelWidth / SkyCloudDownScale;
        int height = camera.pixelHeight / SkyCloudDownScale;
        PipelineUtils.CheckOrCreateRT(ref _SkyCloudLowRes, new Vector2Int(width, height), RenderTextureFormat.ARGBHalf);
        
        currentTime += Time.deltaTime;
        
        unitCubePosition.Set(camera.transform.position.x, camera.transform.position.y + SkyCloudHeight, camera.transform.position.z);
        Matrix4x4 matrix = Matrix4x4.TRS(unitCubePosition, Quaternion.identity, SkyCloudScale);
        //TODO renderIntoTexture
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);

        float perlinOffsetX = perlinNoiseSpeedX * currentTime;
        float perlinOffsetZ = perlinNoiseSpeedZ * currentTime;
        perlinOffsetAndScaleVec.Set(perlinOffsetX, perlinOffsetZ, perlinForSkyCloudNoiseScale, perlinToDilateWorleyNoiseScale);
        
        float worleyOffsetX = WorleyNoiseXSpeed * currentTime;
        float worleyOffsetY = WorleyNoiseYSpeed * currentTime;
        float worleyOffsetZ = WorleyNoiseZSpeed * currentTime;
        worleyOffsetAndScaleVec.Set(worleyOffsetX, worleyOffsetY, worleyOffsetZ, WorleyNoiseYScale);
        
        cmdBuffer.Clear();
        cmdBuffer.BeginSample("SkyCloud");
        cmdBuffer.SetRenderTarget(_SkyCloudLowRes);
        cmdBuffer.ClearRenderTarget(true, true, Color.black);
        cmdBuffer.SetViewProjectionMatrices(camera.worldToCameraMatrix, projectionMatrix);
        
        cmdBuffer.SetGlobalTexture("_worleyNoiseTex", WorleyNoiseTex);
        cmdBuffer.SetGlobalTexture("_perlinForSkyCloudTex", PerlinForSkyCloudTex);
        cmdBuffer.SetGlobalTexture("_perlinToDilateWorley", PerlinToDilateWorley);
        
        cloudNoiseParam.Set(perlinNoisePow, SkyCloudHeight, WorleyNoiseWeight, 15.00f);
        cmdBuffer.SetGlobalVector("_CloudNoiseParam", cloudNoiseParam);
        fakeCloudTransmittanceParam.Set(_FakeCloudTransmittanceWeight, _FakeCloudTransmittancePow, _FakeCloudTransmittanceOffset, 0.00f);
        cmdBuffer.SetGlobalVector("_FakeCloudTransmittanceParam", fakeCloudTransmittanceParam);
        cmdBuffer.SetGlobalVector("_PerlinOffsetAndScale", perlinOffsetAndScaleVec);
        worley2Param.Set(perlinToDilateWorleyWeight, perlinNoiseWeight, perlinNoiseYWeight, perlinNoiseYParam);
        cmdBuffer.SetGlobalVector("_Worley2Param", worley2Param);
        cmdBuffer.SetGlobalVector("_WorleyOffsetAndScale", worleyOffsetAndScaleVec);
        cmdBuffer.SetGlobalVector("_darkColor", DarkColor);
        cmdBuffer.SetGlobalVector("_envColor", EnvColor);
        cmdBuffer.SetGlobalVector("_sunColor", SunColor);

        
        cmdBuffer.SetGlobalVector("scale", SkyCloudScale);
        skyCloudInvScale.Set(1 / SkyCloudScale.x, 1 / SkyCloudScale.y, 1 / SkyCloudScale.z);
        cmdBuffer.SetGlobalVector("invscale", skyCloudInvScale);
        cmdBuffer.SetGlobalVector("_sunDir", SunLight.transform.forward);
        
        float startPosYOS = -SkyCloudHeight - SkyCloudScale.y / 2;
        float startPosXOS = SkyCloudScale.x / 2;
        float startPosZOS = SkyCloudScale.z / 2;
        startPosOS.Set(startPosXOS, startPosYOS, startPosZOS);
        cmdBuffer.SetGlobalVector("_startPosOS", startPosOS);

        float maxDis = Mathf.Sqrt(startPosXOS * startPosXOS + startPosYOS * startPosYOS);
        float maxFarDisCount = Mathf.Log(maxDis * rayScale + rayOffset) / rayScale;
        sampleParam.Set(rayScale, rayOffset, maxRayStep, maxFarDisCount);
        
        cmdBuffer.SetGlobalVector("_sampleParam", sampleParam);
        subRayParam.Set(SubRayStepCount, SubRayLightTrans, 0.00f, 0.00f);
        cmdBuffer.SetGlobalVector("_subRayParam", subRayParam);

        subRayStep.Set(-SunLight.transform.forward.x * SubRayStepLength * skyCloudInvScale.x,
            -SunLight.transform.forward.y * SubRayStepLength * skyCloudInvScale.y,
            -SunLight.transform.forward.z * SubRayStepLength * skyCloudInvScale.z, 0.0f);
        cmdBuffer.SetGlobalVector("_subRayStep", subRayStep);
        
        extraParam1.Set(lightNoiseParam, 0.00f, 0.00f, 0.00f);
        cmdBuffer.SetGlobalVector("_extraParam1", extraParam1);

        cmdBuffer.SetGlobalVector("_phaseParam", new Vector4(0.03815f, 1.04121f, 0.406f, 0.00f));
        cmdBuffer.SetGlobalVector("_backPhaseParam", new Vector4(0.03342f, 1.16f, 0.80f, 0.00f));
        
        cmdBuffer.DrawMesh(UnitCubeMesh, matrix, SkyCloudMat);
        cmdBuffer.EndSample("SkyCloud");

        Graphics.ExecuteCommandBuffer(cmdBuffer);
        
        Shader.EnableKeyword("SKY_CLOUD_ENABLED");
        Shader.SetGlobalTexture("_SkyCloudLowRes", _SkyCloudLowRes);
        
        skyCloudViewportScale.Set(1.00f, 1.00f, 0.99896f, 0.99815f);
        Shader.SetGlobalVector("_SkyCloudViewportScale", skyCloudViewportScale);
        
        blendCloudFogParam.Set(0.00f, 0.065f, 0.00f, 0.00f);
        Shader.SetGlobalVector("_blendCloudFogParam", blendCloudFogParam);
    }
}
