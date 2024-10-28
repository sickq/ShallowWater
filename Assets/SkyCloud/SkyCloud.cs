using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class SkyCloud : MonoBehaviour
{
    //SunLightDir 区分主光源，计算大气+体积云的光源
    public Light SunLight;

    [Header("天空云的高度"), Range(0, 2000)]public float SkyCloudHeight = 250;


    public Texture2DArray WorleyNoiseTex;
    public Texture2D PerlinForSkyCloudTex;
    public Texture2D PerlinToDilateWorley;
    
    [ColorUsage(false, true)] public Color SunColor = Color.white;
    [ColorUsage(false, true)] public Color EnvColor = Color.white;

    [Range(0, 20)] public float perlinForSkyCloudNoiseScale = 6.5f;
    [Range(0, 20)] public float perlinToDilateWorleyNoiseScale = 10.0f;
    
    [Range(-20, 20)] public float perlinNoiseSpeedX = 0.01f;
    [Range(-20, 20)] public float perlinNoiseSpeedZ = 0.01f;
    [Range(-2, 2)] public float perlinToDilateWorleyWeight = 0.66f;
    [Range(-2, 2)] public float perlinNoiseWeight = 0.61865f;
    [Range(-2, 2)] public float perlinNoiseYWeight = 1.0f;
    [Range(-10, 10)] public float perlinNoiseYParam = 2.0f;
    
    [Range(-5, 5)] public float WorleyNoiseYScale = 1.30667f;
    [Range(-5, 5)] public float WorleyNoiseXSpeed = 0.01f;
    [Range(-5, 5)] public float WorleyNoiseYSpeed = 0.01f;
    [Range(-5, 5)] public float WorleyNoiseZSpeed = 0.01f;

    
    [Header("光照步进次数"), Range(0, 10)] public int SubRayStepCount = 2;
    [Header("光照步进距离"), Range(0, 20)] public int SubRayStepLength = 14;
    [Header("光照传输"), Range(0, 20)] public int SubRayLightTrans = 15;
    
    [Header("云透射Pow,伪造"), Range(0, 10)] public float _FakeCloudTransmittancePow = 0.10f;
    [Header("云透射权重,伪造"), Range(0, 10)] public float _FakeCloudTransmittanceWeight = 0.30f;

    [Header("最大步进次数"), Range(0, 50)] public int maxRayStep = 20;
    [Header("步进偏移"), Range(0, 2)] public float rayOffset = 1.0f;

    [Range(0.0001f, 1)] public float rayScale = 0.03f;



    private CommandBuffer cmdBuffer;

    private void OnEnable()
    {
        PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
        cmdBuffer = new CommandBuffer(){name = "SkyCloud"};
    }

    private void OnDisable()
    {
        PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
    }

    private float currentTime = 0;
    // Update is called once per frame
    void Update()
    {
        currentTime += Time.deltaTime;
        // cmdBuffer.Clear();
        // Matrix4x4 matrix = Matrix4x4.TRS(new Vector3(camera.transform.position.x,. ), transform.rotation, transform.lossyScale);
        // cmdBuffer.DrawMesh(PrimitiveType.Cube, );
        
        Shader.SetGlobalTexture("_worleyNoiseTex", WorleyNoiseTex);
        Shader.SetGlobalTexture("_perlinForSkyCloudTex", PerlinForSkyCloudTex);
        Shader.SetGlobalTexture("_perlinToDilateWorley", PerlinToDilateWorley);
        
        Shader.SetGlobalVector("_CloudNoiseParam", new Vector4(0.838f, SkyCloudHeight, 0.55f, 15.00f));
        Shader.SetGlobalVector("_FakeCloudTransmittanceParam", new Vector4(_FakeCloudTransmittanceWeight, _FakeCloudTransmittancePow, 0.50f, 0.00f));
        float offsetX = perlinNoiseSpeedX * currentTime;
        float offsetZ = perlinNoiseSpeedZ * currentTime;
        Shader.SetGlobalVector("_PerlinOffsetAndScale", new Vector4(offsetX, offsetZ, perlinForSkyCloudNoiseScale, perlinToDilateWorleyNoiseScale));
        // Shader.SetGlobalVector("_WorldSpaceCameraPos", new Vector4(483.94421f, 203.22813f, 898.3457f));
        Shader.SetGlobalVector("_Worley2Param", new Vector4(perlinToDilateWorleyWeight, perlinNoiseWeight, perlinNoiseYWeight, perlinNoiseYParam));
        
        float worleyOffsetX = WorleyNoiseXSpeed * currentTime;
        float worleyOffsetY = WorleyNoiseYSpeed * currentTime;
        float worleyOffsetZ = WorleyNoiseZSpeed * currentTime;
        
        
        Shader.SetGlobalVector("_WorleyOffsetAndScale", new Vector4(worleyOffsetX, worleyOffsetY, worleyOffsetZ, WorleyNoiseYScale));
        // Shader.SetGlobalVector("_WorleyOffsetAndScale", new Vector4(18.78573f, 0.00f, -5.15855f, 1.30667f));
        Shader.SetGlobalVector("_phaseParam", new Vector4(0.03815f, 1.04121f, 0.406f, 0.00f));
        Shader.SetGlobalVector("_backPhaseParam", new Vector4(0.03342f, 1.16f, 0.80f, 0.00f));
        Shader.SetGlobalVector("_darkColor", new Vector4(0.13512f, 0.20625f, 0.30227f, 0.19805f));
        Shader.SetGlobalVector("_envColor", EnvColor);
        Shader.SetGlobalVector("_extraParam1", new Vector4(0.24f, 0.00f, 0.00f, 0.00f));
        float startPosYOS = -SkyCloudHeight - transform.lossyScale.y / 2;
        float startPosXOS = transform.lossyScale.x / 2;
        float startPosZOS = transform.lossyScale.z / 2;

        float maxDis = Mathf.Sqrt(startPosXOS * startPosXOS + startPosYOS * startPosYOS);
        float maxFarDisCount = Mathf.Log(maxDis * rayScale + rayOffset) / rayScale;

        Shader.SetGlobalVector("_sampleParam", new Vector4(rayScale, rayOffset, maxRayStep, maxFarDisCount));

        Shader.SetGlobalVector("_startPosOS", new Vector4(startPosXOS, startPosYOS, startPosZOS, 0.00f));
        Shader.SetGlobalVector("_subRayParam", new Vector4(SubRayStepCount, SubRayLightTrans, 0.00f, 0.00f));
        
        Shader.SetGlobalVector("_sunColor", SunColor);
        Shader.SetGlobalVector("_sunDir", -SunLight.transform.forward);
        
        // Shader.SetGlobalVector("_sunColor", new Vector4(7.58063f, 7.58063f, 7.58063f, 7.58063f));
        // Shader.SetGlobalVector("invscale", new Vector4(0.00005f, 0.01f, 0.00005f));
        // Shader.SetGlobalVector("scale", new Vector4(20000.00f, 100.00f, 20000.00f));

        Vector3 invScale = new Vector3(1 / transform.lossyScale.x, 1 / transform.lossyScale.y, 1 / transform.lossyScale.z);
        Shader.SetGlobalVector("scale", transform.lossyScale);
        Shader.SetGlobalVector("invscale", invScale);

        Vector3 subRayStep = new Vector3(-SunLight.transform.forward.x * SubRayStepLength * invScale.x,
                                        -SunLight.transform.forward.y * SubRayStepLength * invScale.y,
                                        -SunLight.transform.forward.z * SubRayStepLength * invScale.z);
        Shader.SetGlobalVector("_subRayStep", subRayStep);

    }

    private void OnDrawGizmos()
    {
        Vector3 abc = new Vector3(2, -11.125f, -9.8f);
        Vector3 nabc = abc.normalized;
        
        Gizmos.color = Color.red;
        Gizmos.DrawLine(Vector3.zero, abc);
        
        Debug.LogError(abc.magnitude);
        Debug.LogError(nabc);
        
    }
}
