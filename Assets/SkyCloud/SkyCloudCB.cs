using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class SkyCloudCB : MonoBehaviour
{
    public SkyCloudData skyCloudData;
    public RenderTexture _SkyCloudLowRes;

    //SunLightDir 区分主光源，计算大气+体积云的光源
    public Light SunLight;
    public Camera camera;
    
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
        if (skyCloudData != null)
        {
            SkyCloudMat = new Material(skyCloudData.SkyCloudShader);
        }
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
    
    private Vector4 phaseParam;
    private Vector4 backPhaseParam;
    
    private float currentTime = 0;
    void LateUpdate()
    {
        if(skyCloudData == null || camera == null || SunLight == null) return;
        
        int width = camera.pixelWidth / skyCloudData.SkyCloudDownScale;
        int height = camera.pixelHeight / skyCloudData.SkyCloudDownScale;
        PipelineUtils.CheckOrCreateRT(ref _SkyCloudLowRes, new Vector2Int(width, height), RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        
        currentTime += Time.deltaTime;
        
        unitCubePosition.Set(camera.transform.position.x, camera.transform.position.y + skyCloudData.SkyCloudHeight, camera.transform.position.z);
        Matrix4x4 matrix = Matrix4x4.TRS(unitCubePosition, Quaternion.identity, skyCloudData.SkyCloudScale);
        //TODO renderIntoTexture
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);

        var perlinOffset = skyCloudData.perlinNoiseDir * skyCloudData.perlinNoiseSpeed * currentTime;
        perlinOffsetAndScaleVec.Set(perlinOffset.x, perlinOffset.y, skyCloudData.perlinForSkyCloudNoiseScale, skyCloudData.perlinToDilateWorleyNoiseScale);
        
        var worleyOffset = skyCloudData.worleyNoiseDir * skyCloudData.worleyNoiseSpeed * currentTime;
        worleyOffsetAndScaleVec.Set(worleyOffset.x, worleyOffset.y, worleyOffset.z, skyCloudData.WorleyNoiseYScale);
        
        float startPosYOS = -skyCloudData.SkyCloudHeight - skyCloudData.SkyCloudScale.y / 2;
        float startPosXOS = skyCloudData.SkyCloudScale.x / 2;
        float startPosZOS = skyCloudData.SkyCloudScale.z / 2;
        startPosOS.Set(startPosXOS, startPosYOS, startPosZOS);

        skyCloudInvScale.Set(1 / skyCloudData.SkyCloudScale.x, 1 / skyCloudData.SkyCloudScale.y, 1 / skyCloudData.SkyCloudScale.z);

        subRayStep = SunLight.transform.forward * skyCloudData.SubRayStepLength;
        subRayStep.Scale(skyCloudInvScale);
        // subRayStep.Set(SunLight.transform.forward.x * SubRayStepLength * skyCloudInvScale.x,
        //     SunLight.transform.forward.y * SubRayStepLength * skyCloudInvScale.y,
        //     SunLight.transform.forward.z * SubRayStepLength * skyCloudInvScale.z, 0.0f);
        
        cmdBuffer.Clear();
        cmdBuffer.BeginSample("SkyCloud");
        cmdBuffer.SetRenderTarget(_SkyCloudLowRes);
        cmdBuffer.ClearRenderTarget(true, true, Color.black);
        cmdBuffer.SetViewProjectionMatrices(camera.worldToCameraMatrix, projectionMatrix);
        
        cmdBuffer.SetGlobalTexture("_worleyNoiseTex", skyCloudData.WorleyNoiseTex);
        cmdBuffer.SetGlobalTexture("_perlinForSkyCloudTex", skyCloudData.PerlinForSkyCloudTex);
        cmdBuffer.SetGlobalTexture("_perlinToDilateWorley", skyCloudData.PerlinToDilateWorley);
        
        cloudNoiseParam.Set(skyCloudData.perlinNoisePow, skyCloudData.SkyCloudHeight + skyCloudData.SkyCloudScale.y / 2, skyCloudData.WorleyNoiseWeight, 15.00f);
        cmdBuffer.SetGlobalVector("_CloudNoiseParam", cloudNoiseParam);
        fakeCloudTransmittanceParam.Set(skyCloudData._FakeCloudTransmittanceWeight, skyCloudData._FakeCloudTransmittancePow, skyCloudData._FakeCloudTransmittanceOffset, 0.00f);
        cmdBuffer.SetGlobalVector("_FakeCloudTransmittanceParam", fakeCloudTransmittanceParam);
        cmdBuffer.SetGlobalVector("_PerlinOffsetAndScale", perlinOffsetAndScaleVec);
        worley2Param.Set(skyCloudData.perlinToDilateWorleyWeight, skyCloudData.perlinNoiseWeight, skyCloudData.perlinNoiseYWeight, skyCloudData.perlinNoiseYParam);
        cmdBuffer.SetGlobalVector("_Worley2Param", worley2Param);
        cmdBuffer.SetGlobalVector("_WorleyOffsetAndScale", worleyOffsetAndScaleVec);
        cmdBuffer.SetGlobalVector("_darkColor", skyCloudData.DarkColor);
        cmdBuffer.SetGlobalVector("_envColor", skyCloudData.EnvColor);
        cmdBuffer.SetGlobalVector("_sunColor", skyCloudData.SunColor);

        
        cmdBuffer.SetGlobalVector("scale", skyCloudData.SkyCloudScale);
        cmdBuffer.SetGlobalVector("invscale", skyCloudInvScale);
        cmdBuffer.SetGlobalVector("_sunDir", SunLight.transform.forward);

        cmdBuffer.SetGlobalVector("_startPosOS", startPosOS);

        float maxDis = Mathf.Sqrt(startPosXOS * startPosXOS + startPosYOS * startPosYOS);
        float maxFarDisCount = Mathf.Log(maxDis * skyCloudData.rayScale + skyCloudData.rayOffset) / skyCloudData.rayScale;
        sampleParam.Set(skyCloudData.rayScale, skyCloudData.rayOffset, skyCloudData.maxRayStep, maxFarDisCount);
        
        cmdBuffer.SetGlobalVector("_sampleParam", sampleParam);
        subRayParam.Set(skyCloudData.SubRayStepCount, skyCloudData.SubRayLightTrans, 0.00f, 0.00f);
        cmdBuffer.SetGlobalVector("_subRayParam", subRayParam);

        cmdBuffer.SetGlobalVector("_subRayStep", subRayStep);
        
        extraParam1.Set(skyCloudData.lightNoiseParam, 0.00f, 0.00f, 0.00f);
        cmdBuffer.SetGlobalVector("_extraParam1", extraParam1);

        phaseParam.Set(skyCloudData.PhaseInvParam, skyCloudData.PhaseOffset, skyCloudData.PhaseScale, 0.0f);
        backPhaseParam.Set(skyCloudData.BackPhaseInvParam, skyCloudData.BackPhaseOffset, skyCloudData.BackPhaseScale, 0.0f);
        cmdBuffer.SetGlobalVector("_phaseParam", phaseParam);
        cmdBuffer.SetGlobalVector("_backPhaseParam", backPhaseParam);
        
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
