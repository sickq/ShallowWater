using System;
using UnityEngine.Rendering;

namespace Atmosphere
{
    using UnityEngine;

    public enum AtmosphereLUTType
    {
        Optimized,
        UE,
    }
    
    [ExecuteAlways]
    public class PrecomputeAtmosphere : MonoBehaviour
    {
        private CommonConstantBufferStructure mConstantBufferCPU = new CommonConstantBufferStructure();
        private SkyAtmosphereConstantBufferStructure cb = new SkyAtmosphereConstantBufferStructure();
        private Material renderSkyMat;
        private float scale = 0.001f;

        public AtmosphereLUTType skyViewLUTType = AtmosphereLUTType.Optimized;
        
        //TODO 替换成SkySunLight
        public Light mainLight;
        public ComputeShader computeShader;
        public AtmosphereData atmosphereData;

        public float VolumeOffset = 0.1f;
        public float CameraHeightOffset = 0.15f;

        public float VolumeHeight = 9.0f;
        public float VolumeDepth = 30.0f;

        private CommandBuffer cmdBuffer;
        private LocalKeyword multiScatApproxKeyword;

        
        private void OnEnable()
        {
            multiScatApproxKeyword = new LocalKeyword(computeShader, "MULTISCATAPPROX_ENABLED");
            PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
            cmdBuffer = new CommandBuffer() { name = "Precompute Atmosphere" };
        }

        private void OnDisable()
        {
            PipelineUtils.ReleaseCommandBuffer(ref cmdBuffer);
        }

        private void LateUpdate()
        {
            cmdBuffer.Clear();
            cmdBuffer.BeginSample("Precompute Atmosphere");
            cmdBuffer.BeginSample("UpdateConstantBuffer");
            UpdateConstantBuffer(Camera.main);
            cmdBuffer.EndSample("UpdateConstantBuffer");
            
            cmdBuffer.BeginSample("PrecomputeTransmittanceLUT");
            PrecomputeTransmittanceLUT();
            cmdBuffer.EndSample("PrecomputeTransmittanceLUT");

            cmdBuffer.BeginSample("PrecomputeMuliScattLUT");
            cmdBuffer.DisableKeyword(computeShader, multiScatApproxKeyword);
            PrecomputeMuliScattLUT();
            cmdBuffer.EnableKeyword(computeShader, multiScatApproxKeyword);
            cmdBuffer.EndSample("PrecomputeMuliScattLUT");

            switch (skyViewLUTType)
            {
                case AtmosphereLUTType.Optimized:
                    cmdBuffer.BeginSample("PrecomputeSkyViewLUT");
                    PrecomputeSkyViewLUT();
                    cmdBuffer.EndSample("PrecomputeSkyViewLUT");
                    break;
                case AtmosphereLUTType.UE:
                    cmdBuffer.BeginSample("PrecomputeSkyViewLUTUE");
                    PrecomputeSkyViewLUTUE();
                    cmdBuffer.EndSample("PrecomputeSkyViewLUT");
                    break;
            }
            
            cmdBuffer.BeginSample("PrecomputeCameraVolumeWithRayMarch");
            PrecomputeCameraVolumeWithRayMarch();
            cmdBuffer.EndSample("PrecomputeCameraVolumeWithRayMarch");
            
            cmdBuffer.EndSample("Precompute Atmosphere");

            Graphics.ExecuteCommandBuffer(cmdBuffer);
            

            Shader.SetGlobalTexture("_SkyViewLutTextureL", _skyViewLUT);
            Shader.SetGlobalVector("g_AtmosphereLightDirection", new Vector4(mainLight.transform.forward.x, -mainLight.transform.forward.z, mainLight.transform.forward.z, mainLight.transform.forward.y));
        }

        void UpdateConstantBuffer(Camera camera)
        {
            cb.BottomRadius = atmosphereData.EarthBottomRadius;
            cb.TopRadius = atmosphereData.EarthTopRadius;
            cb.RayleighDensityExpScale = atmosphereData.RayleighDensityExpScale;
            cb.MieDensityExpScale = atmosphereData.MieDensityExpScale;
            cb.MieFadeBegin = atmosphereData.MieFadeBegin;
            cb.RayleighScattering = atmosphereData.RayleighScattering;
            cb.MieScattering = atmosphereData.MieScattering;
            cb.MieExtinction = atmosphereData.MieExtinction;
            cb.MieAbsorption = atmosphereData.MieAbsorption;
            cb.MiePhaseG = atmosphereData.MiePhaseG;
            cb.AbsorptionDensity0LayerWidth = atmosphereData.AbsorptionDensity0LayerWidth;
            cb.AbsorptionDensity0ConstantTerm = atmosphereData.AbsorptionDensity0ConstantTerm;
            cb.AbsorptionDensity0LinearTerm = atmosphereData.AbsorptionDensity0LinearTerm;
            cb.AbsorptionDensity1ConstantTerm = atmosphereData.AbsorptionDensity1ConstantTerm;
            cb.AbsorptionDensity1LinearTerm = atmosphereData.AbsorptionDensity1LinearTerm;
            cb.GroundAlbedo = atmosphereData.GroundAlbedo;

            cb.AbsorptionExtinction = atmosphereData.AbsorptionExtinction;

            cb.MultipleScatteringFactor = atmosphereData.currentMultipleScatteringFactor;
            cb.MultiScatteringLUTRes = atmosphereData.MultiScatteringLUTRes;

            cb.TRANSMITTANCE_TEXTURE_WIDTH = LookUpTablesInfo.TRANSMITTANCE_TEXTURE_WIDTH;
            cb.TRANSMITTANCE_TEXTURE_HEIGHT = LookUpTablesInfo.TRANSMITTANCE_TEXTURE_HEIGHT;
            cb.IRRADIANCE_TEXTURE_WIDTH = LookUpTablesInfo.IRRADIANCE_TEXTURE_WIDTH;
            cb.IRRADIANCE_TEXTURE_HEIGHT = LookUpTablesInfo.IRRADIANCE_TEXTURE_HEIGHT;
            cb.SCATTERING_TEXTURE_R_SIZE = LookUpTablesInfo.SCATTERING_TEXTURE_R_SIZE;
            cb.SCATTERING_TEXTURE_MU_SIZE = LookUpTablesInfo.SCATTERING_TEXTURE_MU_SIZE;
            cb.SCATTERING_TEXTURE_MU_S_SIZE = LookUpTablesInfo.SCATTERING_TEXTURE_MU_S_SIZE;
            cb.SCATTERING_TEXTURE_NU_SIZE = LookUpTablesInfo.SCATTERING_TEXTURE_NU_SIZE;

            cb.CameraAerialPerspectiveVolumeParam = new Vector4(VolumeHeight, VolumeDepth, 1.0f, CameraHeightOffset);
            GameObject go = new GameObject();
            go.transform.forward = -mainLight.transform.forward;
            float rotateRad = -mainLight.transform.rotation.eulerAngles.y * Mathf.Deg2Rad - (3.14f / 2.0f);
            PipelineUtils.DestroyObject(go);

            cb.CameraAerialPerspectiveVolumeParam2 = new Vector4(LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, rotateRad, 0.0f);
            cb.CameraAerialPerspectiveVolumeParam3 = new Vector4(VolumeOffset, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_Y, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_Z);

            cb.AtmosParam = new Vector4(0.0f, atmosphereData.AtmosphereColorOffsetWeight, AtmosphereUtils.GetHgPhaseK(atmosphereData.mie_phase_function_g), 0.0f);
            cb.AtmosParam1 = atmosphereData.AtmosphereColor1;
            cb.AtmosParam2 = atmosphereData.AtmosphereColor2;
            
            //深度值，渲染到纹理。Y要翻转
            var projectionMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true);
            Matrix4x4 viewProjMat = projectionMatrix * camera.worldToCameraMatrix;

            cb.gSkyViewProjMat = viewProjMat;
            cb.gSkyInvViewProjMat = viewProjMat.inverse;
            cb.gSkyInvProjMat = projectionMatrix.inverse;
            cb.gSkyInvViewMat = camera.worldToCameraMatrix.inverse;
            cb.gShadowmapViewProjMat = viewProjMat;
            // cb.camera = camera.transform.position * scale;
            //兼容Unreal的代码，需要转换坐标系
            cb.camera = new Vector3(camera.transform.position.x, camera.transform.position.z, camera.transform.position.y) * scale;
            // cb.sun_direction = -mainLight.transform.forward;
            cb.sun_direction = new Vector3(-mainLight.transform.forward.x, -mainLight.transform.forward.z, -mainLight.transform.forward.y);

            mConstantBufferCPU.gSunIlluminance = Vector3.one * atmosphereData.mSunIlluminanceScale;
            mConstantBufferCPU.gScatteringMaxPathDepth = NumScatteringOrder;
            uiViewRayMarchMaxSPP = uiViewRayMarchMinSPP >= uiViewRayMarchMaxSPP
                ? uiViewRayMarchMinSPP + 1
                : uiViewRayMarchMaxSPP;
            mConstantBufferCPU.RayMarchMinMaxSPP = new Vector3(uiViewRayMarchMinSPP, uiViewRayMarchMaxSPP);

            AtmosphereUtils.SetConstant(cmdBuffer, computeShader, typeof(CommonConstantBufferStructure), mConstantBufferCPU);
            AtmosphereUtils.SetConstant(cmdBuffer, computeShader, typeof(SkyAtmosphereConstantBufferStructure), cb);
        }
        
        int NumScatteringOrder = 4;
        int uiViewRayMarchMinSPP = 4;
        int uiViewRayMarchMaxSPP = 14;
        [System.NonSerialized] public RenderTexture _transmittanceLUT;
        [System.NonSerialized] public RenderTexture _newMuliScattLUT;
        [System.NonSerialized] public RenderTexture _skyViewLUT;
        [System.NonSerialized] public RenderTexture _cameraVolumeLUT;
        
        private void PrecomputeTransmittanceLUT()
        {
            Vector2Int size = new Vector2Int(LookUpTablesInfo.TRANSMITTANCE_TEXTURE_WIDTH,
                LookUpTablesInfo.TRANSMITTANCE_TEXTURE_HEIGHT);
            AtmosphereUtils.CheckOrCreateLUT(ref _transmittanceLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("IntergalTransmittanceLUT");
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("_TransmittanceLUT"), _transmittanceLUT);
            // computeShader.SetTexture(index, Shader.PropertyToID("_TransmittanceLUT"), _transmittanceLUT);
            AtmosphereUtils.Dispatch(cmdBuffer, computeShader, index, size);
        }

        private void PrecomputeMuliScattLUT()
        {
            Vector2Int size = new Vector2Int(atmosphereData.MultiScatteringLUTRes, atmosphereData.MultiScatteringLUTRes);
            AtmosphereUtils.CheckOrCreateLUT(ref _newMuliScattLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("NewMultiScattCS");
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("OutputTexture"), _newMuliScattLUT);
            AtmosphereUtils.Dispatch(cmdBuffer, computeShader, index, size);
        }

        private void PrecomputeSkyViewLUT()
        {
            Vector2Int size = new Vector2Int(96, 104);
            AtmosphereUtils.CheckOrCreateLUT(ref _skyViewLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("IntergalSkyViewLutPS");
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("MultiScatTexture"), _newMuliScattLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("_SkyViewLUT"), _skyViewLUT);
            AtmosphereUtils.Dispatch(cmdBuffer, computeShader, index, size);
        }
        
        private void PrecomputeSkyViewLUTUE()
        {
            // Vector2Int size = new Vector2Int(192, 108);
            Vector2Int size = new Vector2Int(96, 104);
            AtmosphereUtils.CheckOrCreateLUT(ref _skyViewLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("IntergalSkyViewLutPSUE");
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("MultiScatTexture"), _newMuliScattLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("_SkyViewLUT"), _skyViewLUT);
            AtmosphereUtils.Dispatch(cmdBuffer, computeShader, index, size);
        }

        void PrecomputeCameraVolumeWithRayMarch()
        {
            Vector2Int size = new Vector2Int(LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, LookUpTablesInfo.CAMERA_VOLUME_SIZE_Y);
            AtmosphereUtils.CheckOrCreateLUT(ref _cameraVolumeLUT, size, RenderTextureFormat.ARGBHalf, LookUpTablesInfo.CAMERA_VOLUME_SIZE_Z);
            int index = computeShader.FindKernel("IntergalCameraVolumeLUT");
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("MultiScatTexture"), _newMuliScattLUT);
            cmdBuffer.SetComputeTextureParam(computeShader, index, Shader.PropertyToID("_CameraVolumeLUT"), _cameraVolumeLUT);
            AtmosphereUtils.Dispatch(cmdBuffer, computeShader, index, size, size.x);
        }
    }
}