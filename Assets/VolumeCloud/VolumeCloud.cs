using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ImageEffectAllowedInSceneView]
public class VolumeCloud : MonoBehaviour
{
    public Transform VolumeTrans;
    
    public Texture2D fragmentTexture0;
    public Texture2D fragmentTexture2;

    [Range(0.1f, 1f)]public float VolumeCloudRTScale = 1.0f;
    
    public Texture2D noiseTexture;
    public Texture2D ditherNoiseTexture;
    [Range(0, 5)] public int VolumeSampleNoiseIter = 4;
    [Range(0, 5)] public int LightSampleNoiseIter = 2;

    [Range(0, 200)] public float VolumeColorLerpHeight = 25;
    
    [Range(0, 50)] public float RayCameraLength = 8.0f;
    [Header("云内部的步进Size，默认值2")]
    [Range(0, 50)] public float RayCameraInCloudLength = 2.0f;
    [Range(0, 50)] public float RayLightLength = 8.0f;
    
    //超出边界，停止Marching
    [Range(0, 1)] public float RayEdgeStop = 0.06f;

    [Range(-20, 20)]public float RayStartHeightOffset = 5.0f;
    [Range(0, 1)]public float RayHeightScale = 0.02f;
    [Range(0, 2)]public float RayScale = 0.4995f;

    [Range(0, 1024)] public float DitherNoiseUVScaleX = 256;
    [Range(0, 1024)] public float DitherNoiseUVScaleY = 256;
    [Range(0, 1000)] public int DitherNoiseOffset = 494;
    
    [Range(-1, 1)] public float NoiseWeight = 0.06f;
    [Range(-5, 5)] public float NoiseSpeed = 0.4f;
    [Range(0, 1)] public float NoiseScale = 0.0773f;
    [Range(0, 2)] public float NoiseScaleY = 1.0f;

    [ColorUsage(false, true)] public Color colorFar;
    [ColorUsage(false, true)] public Color colorNear;
    [Range(0, 2)] public float colorNearWeight = 1.0f;
    [Range(0, 2)] public float lightColorIntensity = 0.66f;

    public float DistanceFar = 600;
    public float DistanceNear = 50;
    public float DistanceBase = -2;

    
    [Header("体积云颜色与原有相机颜色的混合参数，影响最终混合")]
    [Range(0, 5)] public float FinalColorBlendPow = 1.50f;
    [Range(0, 5)] public float FinalColorBlendWeight = 1.10f;

    [Header("体积云最终颜色的参数，一般不需要调")]
    [Range(0, 5)] public float FinalColorPow = 1;
    [Range(0, 5)] public float FinalColorRemapLeft = 0;
    [Range(0, 5)] public float FinalColorRemapRight = 1;
    
    [Range(0, 5)] public float FinalAlphaDistance = 2.0f;


    public Shader VolumeCloudShader;
    
    //CameraPos 以及 Camera相关矩阵
    private static readonly Vector4[] fragmentGlobals =
    {
        new Vector4(601.33655f, 1646.8042f, 72.98492f, 0.00f),
        new Vector4(0.00f, 0.23989f, -601.23633f, 602.24615f),
        new Vector4(1.02498f, 6.72653E-14f, -1646.52979f, 1646.8042f),
        new Vector4(0.00f, 0.52515f, -72.97276f, 72.56947f),
        new Vector4(0.00f, 0.00f, -0.99983f, 1.00f),
    };
    
    private static readonly Vector4[] fragmentParams =
    {
        new Vector4(0.89906f, 0.74114f, 0.48176f, 698.00f ),        //0
        new Vector4( 2000.00f, 2000.00f, -2.00f, 71.40f    ),       //1
        new Vector4( 2.00f, 8.00f, 5.00f, 0.66f            ),       //2
        new Vector4( 0.81176f, 0.70588f, 0.59608f, 1.00f   ),       //3
        new Vector4( 0.67059f, 0.48235f, 0.36471f, 4.00f   ),       //4
        new Vector4( 2.00f, 8.00f, 0.02f, 25.00f           ),       //5
        new Vector4(0.4995f, 0.06f, 0.00f, 1.00f          ),        //6
        new Vector4(1.00f, 1.10f, 1.50f, 2.00f            ),        //7
        new Vector4(1.00f, -0.37279f, -0.73165f, -0.57071f),        //8
        new Vector4(494.00f, 256.00f, 256.00f, 1.30f      ),        //9
        new Vector4(35.4924f, 1280.00f, 721.00f, 0.0773f  ),        //10
        new Vector4(0.06f, 0.40f, 2.00f, 3.00f            ),        //11
        new Vector4(4.00f, 7.00f, 1.00f, 1.00f            ),        //12
    };

    private static Vector4 VolumeCloudParamsOffset = new Vector4(2.0f, 3.0f, 4.0f, 7.0f);
    
    private CommandBuffer cmdBuffer;

    private Camera curCamera;

    private Material VolumeCloudMaterial;

    private Light mainLight;

    private void OnEnable()
    {
        PipelineUtils.ReleaseMaterial(ref VolumeCloudMaterial);
        VolumeCloudMaterial = new Material(VolumeCloudShader);

        if (cmdBuffer == null)
        {
            cmdBuffer = new CommandBuffer { name = "VolumeCloud" };
        }

        curCamera = GetComponent<Camera>();
        curCamera.RemoveCommandBuffers(CameraEvent.BeforeImageEffects);
        curCamera.AddCommandBuffer(CameraEvent.BeforeImageEffects, cmdBuffer);
        curCamera.depthTextureMode = DepthTextureMode.Depth;

        mainLight = GameObject.FindObjectOfType<Light>();
    }
    
    private void OnDisable()
    {
        PipelineUtils.ReleaseMaterial(ref VolumeCloudMaterial);
        if (curCamera != null)
        {
            curCamera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, cmdBuffer);
        }
        cmdBuffer.Clear();
        cmdBuffer.Release();
        cmdBuffer = null;
        curCamera.depthTextureMode = DepthTextureMode.None;
    }

    private static int _VolumeCloudTempRT = Shader.PropertyToID("_VolumeCloudTempRT");
    private static int _VolumeCloudTempRT1 = Shader.PropertyToID("_VolumeCloudTempRT1");
    private static int _VolumeCloudOutputRT = Shader.PropertyToID("_VolumeCloudOutputRT");
    
    private void OnPreRender()
    {
        if (cmdBuffer == null) return;
        cmdBuffer.Clear();

        int width = (int)(curCamera.pixelWidth * VolumeCloudRTScale);
        int height = (int)(curCamera.pixelHeight * VolumeCloudRTScale);
        
        cmdBuffer.SetGlobalTexture("fragmentTextures0", fragmentTexture0);
        cmdBuffer.SetGlobalTexture("fragmentTextures2", fragmentTexture2);
        
        VolumeCloudMaterial.SetTexture("_VolumeNoiseTexture", noiseTexture);
        VolumeCloudMaterial.SetTexture("_VolumeDitherNoiseTexture", ditherNoiseTexture);
        
        VolumeCloudMaterial.SetVector("_LightDir", mainLight.transform.forward);
        VolumeCloudMaterial.SetVector("_LightColor", mainLight.color.linear * mainLight.intensity);
        VolumeCloudMaterial.SetVector("_VolumeCloudParamsOffset", VolumeCloudParamsOffset);
        VolumeCloudMaterial.SetVector("_VolumeCloudNoiseIterParams", new Vector4(VolumeSampleNoiseIter, LightSampleNoiseIter));
        VolumeCloudMaterial.SetVector("_VolumeDistanceParams", new Vector4(DistanceFar, DistanceNear, DistanceBase));
        VolumeCloudMaterial.SetVector("fragmentParamsColorFar", new Vector4(colorFar.r, colorFar.g, colorFar.b, 1));
        VolumeCloudMaterial.SetVector("fragmentParamsColorNear", new Vector4(colorNear.r, colorNear.g, colorNear.b, colorNearWeight));
        VolumeCloudMaterial.SetVector("fragmentParamsRay", new Vector4(RayLightLength, RayCameraLength, RayEdgeStop, RayCameraInCloudLength));
        VolumeCloudMaterial.SetVector("fragmentParamsNoise", new Vector4(NoiseWeight, NoiseSpeed, NoiseScale, NoiseScaleY));
        VolumeCloudMaterial.SetVector("fragmentParamsRayData", new Vector4(RayStartHeightOffset, RayHeightScale, RayScale));
        VolumeCloudMaterial.SetVector("fragmentParamsDitherNoise", new Vector4(DitherNoiseUVScaleX, DitherNoiseUVScaleY, DitherNoiseOffset));
        VolumeCloudMaterial.SetVector("fragmentParamsRenderResolution", new Vector4(width, height));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeColorLerp", new Vector4(VolumeColorLerpHeight, 1));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeFinalColorBlend", new Vector4(FinalColorBlendPow, FinalColorBlendWeight));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeFinalColor", new Vector4(FinalColorPow, FinalColorRemapLeft, FinalColorRemapRight));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeFinalAlpha", new Vector4(FinalAlphaDistance, 1));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeLight", new Vector4(lightColorIntensity, 1));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeBoundPivot", (VolumeTrans.position - VolumeTrans.lossyScale / 2));
        VolumeCloudMaterial.SetVector("fragmentParamsVolumeBoundSize", VolumeTrans.lossyScale);

        VolumeCloudMaterial.SetVectorArray("fragmentParams", fragmentParams);
        
        cmdBuffer.GetTemporaryRT(_VolumeCloudTempRT, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        cmdBuffer.GetTemporaryRT(_VolumeCloudTempRT1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        cmdBuffer.Blit(BuiltinRenderTextureType.CameraTarget, _VolumeCloudTempRT, VolumeCloudMaterial, 0);
        cmdBuffer.Blit(_VolumeCloudTempRT, _VolumeCloudTempRT1, VolumeCloudMaterial, 1);
        cmdBuffer.Blit(_VolumeCloudTempRT1, _VolumeCloudTempRT, VolumeCloudMaterial, 2);

        cmdBuffer.GetTemporaryRT(_VolumeCloudOutputRT, curCamera.pixelWidth, curCamera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        cmdBuffer.Blit(BuiltinRenderTextureType.CameraTarget, _VolumeCloudOutputRT);
        cmdBuffer.SetGlobalTexture("_VolumeCloudTempRT", _VolumeCloudTempRT);
        cmdBuffer.Blit(_VolumeCloudOutputRT, BuiltinRenderTextureType.CameraTarget, VolumeCloudMaterial, 3);
    }
}
