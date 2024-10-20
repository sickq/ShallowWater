using System;

namespace Atmosphere
{
    using UnityEngine;

    public class PrecomputeAtmosphere : MonoBehaviour
    {
        private CommonConstantBufferStructure mConstantBufferCPU = new CommonConstantBufferStructure();
        private SkyAtmosphereConstantBufferStructure cb = new SkyAtmosphereConstantBufferStructure();
        private Material renderSkyMat;
        private float scale = 0.001f;
        public bool currentMultiscatapprox = true;

        //TODO 替换成SkySunLight
        public Light mainLight;
        public ComputeShader computeShader;
        public AtmosphereData atmosphereData;

        public float VolumeOffset = 0.1f;
        public float CameraHeightOffset = 0.15f;

        public float VolumeHeight = 9.0f;
        public float VolumeDepth = 30.0f;

        private ComputeBuffer constantBuffer;

        private void OnEnable()
        {
            
        }

        private void OnDisable()
        {
            
        }

        private void LateUpdate()
        {
            UpdateConstantBuffer(Camera.main);
            PrecomputeTransmittanceLUT();
            if (currentMultiscatapprox)
            {
                computeShader.DisableKeyword("MULTISCATAPPROX_ENABLED");
                PrecomputeMuliScattLUT();
                computeShader.EnableKeyword("MULTISCATAPPROX_ENABLED");
            }
            else
            {
                computeShader.DisableKeyword("MULTISCATAPPROX_ENABLED");
            }

            PrecomputeSkyViewLUT();
            PrecomputeCameraVolumeWithRayMarch();
            
            Shader.SetGlobalTexture("_SkyViewLutTextureL", _skyViewLUT);
            
            Shader.SetGlobalVector("g_AtmosphereLightDirection", new Vector4(mainLight.transform.forward.x, -mainLight.transform.forward.z, 0, 0));
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
            // cb.SKY_SPECTRAL_RADIANCE_TO_LUMINANCE = new Vector3(114974.916437f, 71305.954816f, 65310.548555f);
            // cb.SUN_SPECTRAL_RADIANCE_TO_LUMINANCE = new Vector3(98242.786222f, 69954.398112f, 66475.012354f);

            // cb.CameraAerialPerspectiveVolumeParam = LookUpTablesInfo.SCATTERING_TEXTURE_NU_SIZE;
            cb.CameraAerialPerspectiveVolumeParam = new Vector4(VolumeHeight, VolumeDepth, 1.0f, CameraHeightOffset);
            GameObject go = new GameObject();
            go.transform.forward = -mainLight.transform.forward;
            float rotateRad = -mainLight.transform.rotation.eulerAngles.y * Mathf.Deg2Rad - (3.14f / 2.0f);
            GameObject.Destroy(go);
            cb.CameraAerialPerspectiveVolumeParam2 = new Vector4(LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, rotateRad, 0.0f);
            cb.CameraAerialPerspectiveVolumeParam3 = new Vector4(VolumeOffset, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_Y, 1.0f / LookUpTablesInfo.CAMERA_VOLUME_SIZE_Z);
            
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
            // cb.view_ray = -camera.transform.forward;
            cb.view_ray = new Vector3(-camera.transform.forward.x, -camera.transform.forward.z, -camera.transform.forward.y);

            // cb.sun_direction = -mainLight.transform.forward;
            cb.sun_direction = new Vector3(-mainLight.transform.forward.x, -mainLight.transform.forward.z, -mainLight.transform.forward.y);

            mConstantBufferCPU.gViewProjMat = viewProjMat;
            mConstantBufferCPU.gColor = new Vector4(0.0f, 1.0f, 1.0f, 1.0f);
            mConstantBufferCPU.gResolution = new Vector3(camera.pixelWidth, camera.pixelHeight);
            mConstantBufferCPU.gSunIlluminance = Vector3.one * atmosphereData.mSunIlluminanceScale;
            mConstantBufferCPU.gScatteringMaxPathDepth = NumScatteringOrder;
            uiViewRayMarchMaxSPP = uiViewRayMarchMinSPP >= uiViewRayMarchMaxSPP
                ? uiViewRayMarchMinSPP + 1
                : uiViewRayMarchMaxSPP;
            mConstantBufferCPU.RayMarchMinMaxSPP = new Vector3(uiViewRayMarchMinSPP, uiViewRayMarchMaxSPP);

            AtmosphereUtils.SetConstant(computeShader, typeof(CommonConstantBufferStructure), mConstantBufferCPU);
            AtmosphereUtils.SetConstant(computeShader, typeof(SkyAtmosphereConstantBufferStructure), cb);
        }
        
        int NumScatteringOrder = 4;
        int uiViewRayMarchMinSPP = 4;
        int uiViewRayMarchMaxSPP = 14;
        public RenderTexture _transmittanceLUT;
        public RenderTexture _newMuliScattLUT;
        public RenderTexture _skyViewLUT;
        public RenderTexture _cameraVolumeLUT;
        
         private void PrecomputeTransmittanceLUT()
        {
            Vector2Int size = new Vector2Int(LookUpTablesInfo.TRANSMITTANCE_TEXTURE_WIDTH,
                LookUpTablesInfo.TRANSMITTANCE_TEXTURE_HEIGHT);
            Common.CheckOrCreateLUT(ref _transmittanceLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("IntergalTransmittanceLUT");
            computeShader.SetTexture(index, Shader.PropertyToID("_TransmittanceLUT"), _transmittanceLUT);
            Common.Dispatch(computeShader, index, size);
        }

        private void PrecomputeMuliScattLUT()
        {
            Vector2Int size = new Vector2Int(atmosphereData.MultiScatteringLUTRes, atmosphereData.MultiScatteringLUTRes);
            Common.CheckOrCreateLUT(ref _newMuliScattLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("NewMultiScattCS");
            computeShader.SetTexture(index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            computeShader.SetTexture(index, Shader.PropertyToID("OutputTexture"), _newMuliScattLUT);
            Common.Dispatch(computeShader, index, size);
        }

        private void PrecomputeSkyViewLUT()
        {
            // Vector2Int size = new Vector2Int(192, 108);
            Vector2Int size = new Vector2Int(96, 104);
            Common.CheckOrCreateLUT(ref _skyViewLUT, size, RenderTextureFormat.ARGBHalf);
            int index = computeShader.FindKernel("IntergalSkyViewLutPS");
            computeShader.SetTexture(index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            computeShader.SetTexture(index, Shader.PropertyToID("MultiScatTexture"), _newMuliScattLUT);
            computeShader.SetTexture(index, Shader.PropertyToID("_SkyViewLUT"), _skyViewLUT);
            Common.Dispatch(computeShader, index, size);
        }

        void PrecomputeCameraVolumeWithRayMarch()
        {
            Vector2Int size = Vector2Int.one * 64;
            size = new Vector2Int(LookUpTablesInfo.CAMERA_VOLUME_SIZE_X, LookUpTablesInfo.CAMERA_VOLUME_SIZE_Y);
            Common.CheckOrCreateLUT(ref _cameraVolumeLUT, size, RenderTextureFormat.ARGBHalf, LookUpTablesInfo.CAMERA_VOLUME_SIZE_Z);
            int index = computeShader.FindKernel("IntergalCameraVolumeLUT");
            computeShader.SetTexture(index, Shader.PropertyToID("TransmittanceLutTexture"), _transmittanceLUT);
            computeShader.SetTexture(index, Shader.PropertyToID("MultiScatTexture"), _newMuliScattLUT);
            computeShader.SetTexture(index, Shader.PropertyToID("_CameraVolumeLUT"), _cameraVolumeLUT);
            Common.Dispatch(computeShader, index, size, size.x);
        }
        
        Vector3 MaxZero3(Vector3 a)
        {
            Vector3 r;
            r.x = a.x > 0.0f ? a.x : 0.0f;
            r.y = a.y > 0.0f ? a.y : 0.0f;
            r.z = a.z > 0.0f ? a.z : 0.0f;
            return r;
        }

        Vector3 sub3(Vector3 a, Vector3 b)
        {
            Vector3 r;
            r.x = a.x - b.x;
            r.y = a.y - b.y;
            r.z = a.z - b.z;
            return r;
        }
    }
}