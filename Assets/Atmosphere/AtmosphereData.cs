namespace Atmosphere
{
    using UnityEngine;
    
    [CreateAssetMenu(fileName = "AtmosphereData", menuName = "Atmosphere/AtmosphereData")]
    public class AtmosphereData : ScriptableObject
    {
        // Values shown here are the result of integration over wavelength power spectrum integrated with paricular function.
        // Refer to https://github.com/ebruneton/precomputed_atmospheric_scattering for details.
        
        [Range(0, 5.0f), Header("多重散射权重")] public float currentMultipleScatteringFactor = 1.0f;
        [Range(0, 0.999f), Header("Mie散射G值")] public float mie_phase_function_g = 0.8f;
        [Range(0, 30.0f), Header("计算散射的光强")] public float mSunIlluminanceScale = 1.0f;
        
        [Range(0, 10.0f)] public float EarthRayleighScaleHeight = 7.5f;
        [Range(0, 10.0f)] public float EarthMieScaleHeight = 0.3f;
        
        
        [Range(-1, 1)] public float MieFadeBegin = 0.0f;
        
        public float EarthBottomRadius = 6360.0f;
        [Range(10.0f, 150.0f)] public float AtmosphereHeight = 60.0f;

        [Header("Mie消散颜色")]
        public Color MieExtinctionColor = new Color(0.35055f, 0.20272f, 0.21735f);
        [Range(0.001f, 10.0f)] public float MieExtinctionLength = 1f;
        
        [Header("Mie散射颜色")]
        public Color MieScatteringColor = new Color(0.20755f, 0.05972f, 0.07435f);
        [Range(0.001f, 10.0f)] public float MieScatteringLength = 1.0f;
        
        [Header("Rayleigh散射颜色")]
        public Color RayleighScatteringColor = new Color(0.09204f, 0.1276f, 0.20117f);
        [Range(0.001f, 10.0f)] public float RayleighScatteringLength = 1.0f;

        public Color AbsorptionExtinctionColor = new Color(0.00574f, 0.0074f, 0.00035f);
        [Range(0.001f, 10.0f)] public float AbsorptionExtinctionLength = 1.0f;

        [Header("地表颜色")]
        public Color GroundAlbedo = new Color(0.40198f, 0.40198f, 0.40198f);

        [Range(0, 1), Header("散射偏移权重")]
        public float AtmosphereColorOffsetWeight = 0.0f;
        
        [Header("Mie Offset Color")]
        public Color AtmosphereColor1 = new Color(0.17012f, 0.04081f, 0.03251f);
        
        [Header("Rayleigh Offset Color")]
        public Color AtmosphereColor2 = new Color(0.82988f, 0.95919f, 0.96749f);
        
        public float AbsorptionDensity0LayerWidth = 25.0f;
        public float AbsorptionDensity0ConstantTerm = -0.66667f;
        public float AbsorptionDensity0LinearTerm = 0.06667f;
        public float AbsorptionDensity1ConstantTerm = 2.66667f;
        public float AbsorptionDensity1LinearTerm = -0.06667f;
        
        public int MultiScatteringLUTRes = 32;

        public float EarthTopRadius => EarthBottomRadius + AtmosphereHeight; // 100km atmosphere radius, less edge visible and it contain 99.99% of the atmosphere medium https://en.wikipedia.org/wiki/K%C3%A1rm%C3%A1n_line
        public float RayleighDensityExpScale => -1.0f / EarthRayleighScaleHeight;
        public float MieDensityExpScale => -1.0f / EarthMieScaleHeight;
        public Color MieScattering => MieScatteringColor * MieScatteringLength;
        public Color MieExtinction => MieExtinctionColor * MieExtinctionLength;
        public Color MieAbsorption => MieExtinction - MieScattering;    //TODO max(this, 0);
        public Color RayleighScattering => RayleighScatteringColor * RayleighScatteringLength;
        public Color AbsorptionExtinction => AbsorptionExtinctionColor * AbsorptionExtinctionLength;
        public float MiePhaseG => mie_phase_function_g;

    }

    [System.Serializable]
    public struct CommonConstantBufferStructure
    {
        public Vector3 gResolution;
        public Matrix4x4 gViewProjMat;
        public Vector4 gColor;
        public Vector3 gSunIlluminance;
        public int gScatteringMaxPathDepth;
        public float gScreenshotCaptureActive;
        public Vector3 RayMarchMinMaxSPP;
    };

    [System.Serializable]
    public struct SkyAtmosphereConstantBufferStructure
    {
        // Radius of the planet (center to ground)
        public float BottomRadius;
        // Maximum considered atmosphere height (center to atmosphere top)
        public float TopRadius;

        // Rayleigh scattering exponential distribution scale in the atmosphere
        public float RayleighDensityExpScale;
        
        // Mie scattering exponential distribution scale in the atmosphere
        public float MieDensityExpScale;
        
        public float MieFadeBegin;
        public float MieDensity;
        public float RayleighDensity;

        // Rayleigh scattering coefficients
        public Color RayleighScattering;
        
        // Mie scattering coefficients
        public Color MieScattering;
        // Mie extinction coefficients
        public Color MieExtinction;
        // Mie absorption coefficients
        public Color MieAbsorption;
        // Mie phase function excentricity
        public float MiePhaseG;	//mie_phase_function_g

        // Another medium type in the atmosphere
        public float AbsorptionDensity0LayerWidth;
        public float AbsorptionDensity0ConstantTerm;
        public float AbsorptionDensity0LinearTerm;
        public float AbsorptionDensity1ConstantTerm;
        public float AbsorptionDensity1LinearTerm;
        // This other medium only absorb light, e.g. useful to represent ozone in the earth atmosphere
        public Color AbsorptionExtinction;		//absorption_extinction

        // The albedo of the ground.
        public Color GroundAlbedo;

        public int TRANSMITTANCE_TEXTURE_WIDTH;
        public int TRANSMITTANCE_TEXTURE_HEIGHT;
        public int IRRADIANCE_TEXTURE_WIDTH;
        public int IRRADIANCE_TEXTURE_HEIGHT;

        public int SCATTERING_TEXTURE_R_SIZE;
        public int SCATTERING_TEXTURE_MU_SIZE;
        public int SCATTERING_TEXTURE_MU_S_SIZE;
        public int SCATTERING_TEXTURE_NU_SIZE;

        public Vector4 CameraAerialPerspectiveVolumeParam;
        public Vector4 CameraAerialPerspectiveVolumeParam2;
        public Vector4 CameraAerialPerspectiveVolumeParam3;

        public Vector4 AerialVolumeSampleCountParam;

        public Vector4 AtmosParam;
        public Vector4 AtmosParam1;
        public Vector4 AtmosParam2; 
        
        //
        // Other globals
        //

        public Matrix4x4 gSkyViewProjMat;
        public Matrix4x4 gSkyInvViewProjMat;
        public Matrix4x4 gSkyInvProjMat;
        public Matrix4x4 gSkyInvViewMat;
        public Matrix4x4 gShadowmapViewProjMat;

        public Vector3 camera;
        public Vector3 sun_direction;
        public Vector3 view_ray;

        public float MultipleScatteringFactor;
        public float MultiScatteringLUTRes;
    };

    struct LookUpTablesInfo
    {
        public const int TRANSMITTANCE_TEXTURE_WIDTH = 256;
        public const int TRANSMITTANCE_TEXTURE_HEIGHT = 64;

        public const int SCATTERING_TEXTURE_R_SIZE = 32;
        public const int SCATTERING_TEXTURE_MU_SIZE = 128;
        public const int SCATTERING_TEXTURE_MU_S_SIZE = 32;
        public const int SCATTERING_TEXTURE_NU_SIZE = 8;

        public const int IRRADIANCE_TEXTURE_WIDTH = 64;
        public const int IRRADIANCE_TEXTURE_HEIGHT = 16;

        public const int CAMERA_VOLUME_SIZE_X = 16;
        public const int CAMERA_VOLUME_SIZE_Y = 16;
        public const int CAMERA_VOLUME_SIZE_Z = 8;
    }
}