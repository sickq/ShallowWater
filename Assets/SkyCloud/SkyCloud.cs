using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyCloud : MonoBehaviour
{
    //SunLightDir 区分主光源，计算大气+体积云的光源
    public Light SunLight;

    public Texture2DArray WorleyNoiseTex;
    public Texture2D PerlinForSkyCloudTex;
    public Texture2D PerlinToDilateWorley;
    
    private void OnEnable()
    {
        
    }

    private void OnDisable()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalTexture("_worleyNoiseTex", WorleyNoiseTex);
        Shader.SetGlobalTexture("_perlinForSkyCloudTex", PerlinForSkyCloudTex);
        Shader.SetGlobalTexture("_perlinToDilateWorley", PerlinToDilateWorley);
        
        Shader.SetGlobalVector("_CloudNoiseParam", new Vector4(0.838f, 261.33331f, 0.55f, 15.00f));
        Shader.SetGlobalVector("_FakeCloudTransmittanceParam", new Vector4(0.30f, 0.10f, 0.50f, 0.00f));
        Shader.SetGlobalVector("_PerlinOffsetAndScale", new Vector4(2.16184f, -1.9157f, 6.50f, 10.00f));
        Shader.SetGlobalVector("_WorldSpaceCameraPos", new Vector4(483.94421f, 203.22813f, 898.3457f));
        Shader.SetGlobalVector("_Worley2Param", new Vector4(0.66f, 0.61865f, 1.00f, 2.00f));
        Shader.SetGlobalVector("_WorleyOffsetAndScale", new Vector4(18.78573f, 0.00f, -5.15855f, 1.30667f));
        Shader.SetGlobalVector("_backPhaseParam", new Vector4(0.03342f, 1.16f, 0.80f, 0.00f));
        Shader.SetGlobalVector("_darkColor", new Vector4(0.13512f, 0.20625f, 0.30227f, 0.19805f));
        Shader.SetGlobalVector("_envColor", new Vector4(72.30f, 72.30f, 72.30f, 72.30f));
        Shader.SetGlobalVector("_extraParam1", new Vector4(0.24f, 0.00f, 0.00f, 0.00f));
        Shader.SetGlobalVector("_phaseParam", new Vector4(0.03815f, 1.04121f, 0.406f, 0.00f));
        Shader.SetGlobalVector("_sampleParam", new Vector4(0.03f, 1.00f, 20.00f, 190.24832f));
        Shader.SetGlobalVector("_startPosOS", new Vector4(10000.00f, -261.00f, 10000.00f, 0.00f));
        Shader.SetGlobalVector("_subRayParam", new Vector4(2.00f, 15.00f, 0.00f, 0.00f));
        Shader.SetGlobalVector("_subRayStep", new Vector4(0.0001f, -0.11125f, -0.00049f));
        Shader.SetGlobalVector("_sunColor", new Vector4(7.58063f, 7.58063f, 7.58063f, 7.58063f));
        Shader.SetGlobalVector("_sunDir", -SunLight.transform.forward);
        Shader.SetGlobalVector("invscale", new Vector4(0.00005f, 0.01f, 0.00005f));
        Shader.SetGlobalVector("scale", new Vector4(20000.00f, 100.00f, 20000.00f));
    }
    
}
