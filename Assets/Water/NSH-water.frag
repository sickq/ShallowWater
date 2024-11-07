#version 450

#ifdef GL_EXT_shader_texture_lod
#extension GL_EXT_shader_texture_lod : enable
#endif
#if 0
#extension GL_EXT_shader_framebuffer_fetch : enable
#endif

precision highp float;
precision highp int;
#define HLSLCC_ENABLE_UNIFORM_BUFFERS 1
#if HLSLCC_ENABLE_UNIFORM_BUFFERS
#define UNITY_UNIFORM
#else
#define UNITY_UNIFORM uniform
#endif
#define UNITY_SUPPORTS_UNIFORM_LOCATION 1
#if UNITY_SUPPORTS_UNIFORM_LOCATION
#define UNITY_LOCATION(x) layout(location = x)
#define UNITY_BINDING(x) layout(binding = x, std140)
#else
#define UNITY_LOCATION(x)
#define UNITY_BINDING(x) layout(std140)
#endif
uniform     mediump vec4 _MainLightPosition;
uniform     mediump vec4 _MainLightColor;
uniform     vec4 _Time;
uniform     vec3 _WorldSpaceCameraPos;
uniform     vec4 _ProjectionParams;
uniform     vec4 _ScreenParams;
uniform     vec4 _ZBufferParams;
uniform     vec4 unity_OrthoParams;
uniform     vec4 hlslcc_mtx4x4unity_MatrixVP[4];
uniform     vec4 _OpaqueColorDynamicScale;
uniform     vec4 _DepthDynamicScale;
uniform     vec4 _SSRMissReplaceColorParam;
uniform     mediump vec2 _SSRParam;
uniform     int _WATERSSR_ON;
uniform     vec4 _DynWaveTexPos_TexelWidth;
uniform     mediump float _DynWaveOn;
uniform     vec4 hlslcc_mtx4x4_BakedWaterShadowMapVPMat[4];
UNITY_BINDING(0) uniform _NshmGlobal {
    mediump vec4 _EnvColor;
    mediump vec4 _AmbientColor;
    mediump vec4 _EnvStrength;
    mediump vec4 _SceneLightGlobalParams;
    mediump vec4 _DielectricSpecOverride;
    mediump vec4 _DefaultSpecCube_HDR;
    mediump vec4 _WindDirection;
    mediump vec4 _WindGlobal;
    vec3 _SkySunDir;
    float _VegetationWindSwitch;
    mediump vec4 ambient_SH[3];
    mediump vec4 ambientChar_SH[7];
    mediump vec4 ambientCharSkin_SH[7];
    mediump vec4 _TerrainLightMapColorScale;
    mediump vec4 _TerrainLightMapColorBias;
    mediump vec4 _TerrainHeightmapBlendScale;
    mediump vec4 _CharacterAOSpecularParam;
    mediump vec4 _GlobalMipBias;
    vec4 _TerrainHeightmapRecipSize;
    vec4 _TerrainHeightmapScale;
    vec4 VTTerrainSize;
    vec4 VTTerainCacheSize;
    vec4 VTPageTableSize;
    vec4 _StreamAnchorPosHeightmap;
    vec4 _TerrainSize;
    vec4 topLeftUVHeightmap[4];
    vec4 _LightTextureAABBMin;
    mediump vec4 g_AtmosphereLightDirection;
    mediump vec4 g_CameraAerialPerspectiveVolumeParam;
    mediump vec4 g_CameraAerialPerspectiveVolumeParam2;
    mediump vec4 _CharacterShadowGlobalParam;
    int pangu_LightmapConfig;
    int _LightmapBaseConfig;
    int overridePropsMaxIndex;
    int _DisableDynamicShadow;
    float _PreWaterDepthSign;
    mediump float _ObjectFresnelIntensity;
    mediump float _NoBakedAmbientScale;
    mediump float _TerrainBlendDistance;
    mediump float _FakeBlendMaskBuff[16];
    int _MaxLightmapMipLevel;
};
UNITY_BINDING(1) uniform Atmosphere {
    float MultipleScatteringFactor;
    float bottom_radius;
    float top_radius;
    float rayleigh_density;
    vec3 rayleigh_scattering;
    vec3 mie_scattering;
    float mie_density;
    float mie_fade_begin;
    vec3 mie_extinction;
    float mie_phase_function_g;
    float mie_phase_function_g2;
    vec3 mie_absorption;
    float AbsorptionDensity0LayerWidth;
    float AbsorptionDensity0ConstantTerm;
    float AbsorptionDensity0LinearTerm;
    float AbsorptionDensity1ConstantTerm;
    float AbsorptionDensity1LinearTerm;
    vec3 absorption_extinction;
    vec3 ground_albedo;
    vec4 hlslcc_mtx4x4gSkyInvViewProjMat[4];
    vec4 hlslcc_mtx4x4gShadowmapViewProjMat[4];
    vec4 CameraAerialPerspectiveVolumeParam;
    vec4 CameraAerialPerspectiveVolumeParam2;
    vec4 CameraAerialPerspectiveVolumeParam3;
    vec4 AtmosphereLightDirection[2];
    vec4 AtmosParam;
    vec4 AtmosParam1;
    vec4 AtmosParam2;
    vec4 AtmosphereLightColor[2];
    vec4 hlslcc_mtx4x4SkyViewLutReferential[4];
};
UNITY_BINDING(2) uniform UnityPerMaterial {
    float _MicroWaveNormalScale;
    float _MacroWaveNormalScale;
    int _UVVDirection1UDirection0;
    float _GlobalTiling;
    vec4 _MicroWaveTiling;
    float _NormalScale;
    float _WaterFallNormalScale;
    float _ShadowDistort;
    vec4 _SlowWaterSpeed;
    float _Distortion;
    vec4 _ShalowColor;
    vec4 _DeepColor;
    float _ShalowFalloffMultiply;
    float _ShalowFalloffPower;
    vec2 _SlowWaterTiling;
    mediump float _WorldTiling;
    float _WaterSpecularClose;
    float _WaterSpecularThreshold;
    float _WaterSmoothness;
    float _FresnelPower;
    float _CleanFalloffMultiply;
    float _CleanFalloffPower;
    float _BackfaceAlpha;
    mediump float gEdgeDepth;
    vec4 _UnderWaterColor;
    vec3 _FoamColor;
    vec3 _FoamColor1;
    vec3 _FoamColor2;
    float _FoamDepth;
    float _FoamDepth1;
    float _FoamFalloff;
    float _FoamFalloff1;
    float _FoamDepth2;
    float _FoamFalloff2;
    vec4 _FoamTiling;
    vec4 _FoamTiling1;
    vec4 _FoamTiling2;
    float _FarNormal;
    mediump float _MinWaterDepth;
    mediump float gAlpha;
    float _ShadowIntensity;
    vec4 _DissolveNoise_ST;
    mediump float _IceIntensity;
    mediump float _PlanarReflIntensity;
    mediump float _PlanarRefAlpha;
    mediump float _PlanarRefAlphaClip;
    float _PlanarReflDistortionIntensity;
    mediump float _RayTracingRef;
    mediump float _AlphaFadeDistance;
    mediump float _AlphaFadeBorder;
    mediump float _WaterBrushColorBrightness;
    mediump float _WaterFallAlpha;
    mediump float _SmallCascadeAngle;
    float _SmallCascadeAngleFalloff;
    mediump vec4 _TilingSpeedFoam;
    mediump float _FoamIntensity;
    float _BigCascadeAngle;
    float _BigCascadeAngleFalloff;
    vec4 _WaterFallEffectTiling;
    vec4 _WaterFallEffectTiling2;
    float _WaterFallEffectAlpha;
    mediump vec4 _WaterFallColor;
    int _EnableDynWaterMask;
    mediump float _CausticsTextureScale;
    mediump float _CausticsTextureAverage;
    mediump float _CausticsStrength;
    mediump float _CausticsFocalDepth;
    mediump float _CausticsDepthOfField;
    mediump float _CausticsEdgeSmooth;
    mediump float _CausticsDistortionScale;
    mediump float _CausticsDistortionStrength;
    mediump float _EnvIntensity;
    mediump float gFinalAlpha;
    mediump float _ShorelineNoiseScale;
    mediump float _ShorelineNoiseStrength;
    float Shore_maxPixelsToShoreline;
    float Shore_maxShallowDepth;
    float Shore_gerstnerWavelength;
    float Shore_gerstnerParallelity;
    float Shore_gerstnerSpeed;
    float Shore_gerstnerAmplitude;
    float Shore_gerstnerWaves;
    float Shore_gerstnerSteepness;
    float Shore_CapFoamStrength;
    float Shore_TrailFoamStrength;
    mediump float _UnderWater;
    vec4 _SubSurfaceColour;
    mediump float _SpecularPower;
    mediump float _SpecularIntensity;
};
UNITY_LOCATION(0) uniform mediump sampler2D _WaterNormal;
UNITY_LOCATION(1) uniform mediump sampler2D _WaterFoam;
UNITY_LOCATION(2) uniform mediump sampler2D _WaterFallEffect;
UNITY_LOCATION(3) uniform highp sampler2D _CameraDepthTexture;
UNITY_LOCATION(4) uniform mediump sampler2D _CameraOpaqueTexture;
UNITY_LOCATION(5) uniform mediump sampler2D SkyViewLutTextureL;
UNITY_LOCATION(6) uniform mediump sampler2D SkyViewLutTextureR;
UNITY_LOCATION(7) uniform mediump sampler3D AtmosphereCameraScatteringVolume;
UNITY_LOCATION(8) uniform mediump sampler2D _WaterMask;
UNITY_LOCATION(9) uniform mediump sampler2D _BakedWaterShadowMap;
UNITY_LOCATION(10) uniform mediump sampler2D _DynamicWaves_Target;
layout(location = 0) in mediump vec4 vs_TEXCOORD0;
layout(location = 1) in highp vec4 vs_TEXCOORD1;
layout(location = 2) in highp vec4 vs_TEXCOORD2;
layout(location = 3) in highp vec4 vs_TEXCOORD3;
layout(location = 4) in highp vec4 vs_TEXCOORD4;
layout(location = 5) in highp vec4 vs_TEXCOORD5;
layout(location = 6) in highp vec4 vs_TEXCOORD6;
layout(location = 7) in highp vec4 vs_TEXCOORD7;
layout(location = 8) in highp vec4 vs_TEXCOORD8;
#if 0
layout(location = 0) inout mediump vec4 SV_Target0;
#else
layout(location = 0) out mediump vec4 SV_Target0;
#endif
vec3 u_xlat0;
int u_xlati0;
bool u_xlatb0;
vec3 u_xlat1;
mediump vec4 u_xlat16_1;
mediump vec3 u_xlat10_1;
uvec3 u_xlatu1;
bvec3 u_xlatb1;
vec3 u_xlat2;
vec4 u_xlat3;
vec4 u_xlat4;
mediump float u_xlat16_4;
mediump float u_xlat10_4;
bool u_xlatb4;
vec4 u_xlat5;
mediump float u_xlat16_5;
vec3 u_xlat6;
mediump vec4 u_xlat16_6;
vec3 u_xlat7;
mediump vec4 u_xlat16_7;
vec4 u_xlat8;
mediump vec4 u_xlat16_8;
mediump vec2 u_xlat16_9;
vec3 u_xlat10;
mediump vec3 u_xlat16_10;
vec4 u_xlat11;
mediump vec3 u_xlat16_11;
vec4 u_xlat12;
mediump vec4 u_xlat16_12;
vec4 u_xlat13;
mediump vec4 u_xlat16_13;
vec4 u_xlat14;
mediump vec3 u_xlat16_14;
vec3 u_xlat15;
vec4 u_xlat16;
mediump vec3 u_xlat16_16;
vec3 u_xlat17;
vec3 u_xlat18;
vec4 u_xlat19;
mediump vec4 u_xlat16_20;
mediump vec3 u_xlat16_21;
vec3 u_xlat22;
float u_xlat23;
bool u_xlatb23;
vec3 u_xlat24;
vec2 u_xlat25;
mediump vec3 u_xlat16_26;
vec2 u_xlat27;
bool u_xlatb27;
float u_xlat28;
mediump vec2 u_xlat16_28;
vec2 u_xlat29;
vec3 u_xlat31;
bool u_xlatb31;
mediump vec3 u_xlat16_36;
mediump vec3 u_xlat16_47;
vec3 u_xlat50;
vec3 u_xlat52;
float u_xlat54;
float u_xlat55;
vec2 u_xlat58;
mediump float u_xlat10_58;
bool u_xlatb58;
vec2 u_xlat62;
mediump vec2 u_xlat10_62;
mediump float u_xlat16_63;
vec2 u_xlat64;
bvec2 u_xlatb64;
vec2 u_xlat66;
mediump float u_xlat16_67;
vec2 u_xlat76;
int u_xlati76;
bool u_xlatb76;
float u_xlat81;
float u_xlat82;
float u_xlat83;
float u_xlat85;
mediump float u_xlat16_85;
bool u_xlatb85;
float u_xlat87;
bool u_xlatb87;
float u_xlat88;
bool u_xlatb88;
mediump float u_xlat16_90;
float u_xlat91;
int u_xlati91;
bool u_xlatb91;
float u_xlat92;
int u_xlati92;
bool u_xlatb92;
int u_xlati96;
bool u_xlatb96;
float u_xlat98;
bool u_xlatb98;
float u_xlat99;
bool u_xlatb99;
float u_xlat100;
mediump float u_xlat16_102;
float u_xlat103;
int u_xlati103;
bool u_xlatb103;
float u_xlat105;
void main()
{

    u_xlat0.x = vs_TEXCOORD2.z;
    u_xlat0.y = vs_TEXCOORD3.z;
    u_xlat0.z = vs_TEXCOORD4.z;
    u_xlat81 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat81 = inversesqrt(u_xlat81);

    //normal
    u_xlat0.xyz = vec3(u_xlat81) * u_xlat0.xyz;



    //posWorld
    u_xlat1.x = vs_TEXCOORD2.w;
    u_xlat1.y = vs_TEXCOORD3.w;
    u_xlat1.z = vs_TEXCOORD4.w;
    //
    u_xlat2.xyz = (-u_xlat1.xyz) + vec3(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y, _WorldSpaceCameraPos.z);
    u_xlat81 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat81 = inversesqrt(u_xlat81);

    //viewDir
    u_xlat3.xyz = vec3(u_xlat81) * u_xlat2.xyz;


    u_xlat82 = u_xlat0.y;
    u_xlat82 = clamp(u_xlat82, 0.0, 1.0);
    u_xlat83 = _BigCascadeAngle * 0.0222222228;
    u_xlat4.x = (-_BigCascadeAngle) * 0.0222222228 + 1.0;
    u_xlat4.x = u_xlat82 + (-u_xlat4.x);
    u_xlat4.x = max(u_xlat4.x, 0.0);
    u_xlat4.x = min(u_xlat4.x, 2.0);

    u_xlat83 = float(1.0) / u_xlat83;
    u_xlat83 = u_xlat83 * u_xlat4.x;
    u_xlat83 = clamp(u_xlat83, 0.0, 1.0);

    u_xlat83 = (-u_xlat83) + 1.0;
    u_xlat83 = log2(u_xlat83);
    u_xlat83 = u_xlat83 * _BigCascadeAngleFalloff;
    u_xlat83 = exp2(u_xlat83);
    u_xlat83 = min(u_xlat83, 1.0);


    u_xlat16_5 = _SmallCascadeAngle * 0.0222222228;
    u_xlat4.x = (-_SmallCascadeAngle) * 0.0222222228 + 1.0;
    u_xlat82 = u_xlat82 + (-u_xlat4.x);
    u_xlat82 = max(u_xlat82, 0.0);
    u_xlat82 = min(u_xlat82, 2.0);

    u_xlat4.x = float(1.0) / u_xlat16_5;
    u_xlat82 = u_xlat82 * u_xlat4.x;
    u_xlat82 = clamp(u_xlat82, 0.0, 1.0);
    u_xlat82 = (-u_xlat82) + 1.0;
    u_xlat82 = log2(u_xlat82);
    u_xlat82 = u_xlat82 * _SmallCascadeAngleFalloff;
    u_xlat82 = exp2(u_xlat82);
    u_xlat82 = min(u_xlat82, 1.0);



    u_xlat4.xy = _Time.yy * _TilingSpeedFoam.zw;
    u_xlatb58 = 0.5<_WorldTiling;
    u_xlat6.xy = (bool(u_xlatb58)) ? vec2(1.0, 0.0) : vs_TEXCOORD2.xy;
    u_xlat7.xy = (bool(u_xlatb58)) ? vec2(0.0, 0.0) : vs_TEXCOORD3.xy;
    u_xlat5.x = float(0.0);
    u_xlat5.y = float(1.0);
    u_xlat5.zw = u_xlat1.xz;
    u_xlat8.xy = vs_TEXCOORD4.xy;
    u_xlat8.zw = vs_TEXCOORD6.xy;
    u_xlat8 = (bool(u_xlatb58)) ? u_xlat5 : u_xlat8;
    u_xlat58.xy = u_xlat5.zw + (-_TerrainSize.zw);
    u_xlat58.xy = u_xlat58.xy * _TerrainSize.yy;
    u_xlat10_58 = texture(_WaterMask, u_xlat58.xy).z;
    u_xlat85 = u_xlat10_58 + -0.00100000005;
    u_xlatb85 = u_xlat85<0.0;
    if(u_xlatb85){discard;}
    u_xlat16_9.x = _IceIntensity;
    u_xlat16_9.x = clamp(u_xlat16_9.x, 0.0, 1.0);


    u_xlat85 = vs_TEXCOORD5.w * 0.5;
    u_xlat87 = (-vs_TEXCOORD5.w) * 0.5 + vs_TEXCOORD5.y;
    u_xlat10.y = u_xlat87 * _ProjectionParams.x + u_xlat85;
    u_xlat10.x = vs_TEXCOORD5.x;
    u_xlat10.xy = u_xlat10.xy / vs_TEXCOORD5.ww;


    u_xlat85 = float(1.0) / _GlobalTiling;
    u_xlat87 = _Time.y * 0.100000001;
    u_xlat11.xyz = _Time.yyy * vec3(0.150000006, 0.150000006, 0.150000006) + vec3(1.0, 1.5, 0.5);
    u_xlat88 = u_xlat11.z + u_xlat11.z;
    u_xlat88 = min(abs(u_xlat88), 1.0);

    u_xlat62.xy = u_xlat8.zw * vec2(_SlowWaterTiling.x, _SlowWaterTiling.y);
    u_xlat62.xy = vec2(u_xlat85) * u_xlat62.xy;
    u_xlat11 = _SlowWaterSpeed.xyxy * u_xlat11.xxyy + u_xlat62.xyxy;


    u_xlat62.xy = _Time.yy * _SlowWaterSpeed.zw + u_xlat62.xy;
    u_xlat85 = u_xlat16_9.x * (-_NormalScale) + _NormalScale;
    u_xlat64.xy = u_xlat16_9.xx * (-vec2(_MicroWaveNormalScale, _MacroWaveNormalScale)) + vec2(_MicroWaveNormalScale, _MacroWaveNormalScale);
    u_xlat16_12.xyz = texture(_WaterNormal, u_xlat11.xy).xyw;


    u_xlat16_13.x = dot(u_xlat16_12.zz, u_xlat16_12.xx);
    u_xlat16_13.y = u_xlat16_12.y + u_xlat16_12.y;
    u_xlat16_36.xy = u_xlat16_13.xy + vec2(-1.0, -1.0);
    u_xlat16_13.xy = vec2(u_xlat85) * u_xlat16_36.xy;
    u_xlat16_36.x = dot(u_xlat16_13.xy, u_xlat16_13.xy);
    u_xlat16_36.x = min(u_xlat16_36.x, 1.0);
    u_xlat16_36.x = (-u_xlat16_36.x) + 1.0;
    u_xlat16_13.z = sqrt(u_xlat16_36.x);


    u_xlat16_11.xyz = texture(_WaterNormal, u_xlat11.zw).xyw;
    u_xlat16_14.x = dot(u_xlat16_11.zz, u_xlat16_11.xx);
    u_xlat16_14.y = u_xlat16_11.y + u_xlat16_11.y;
    u_xlat16_36.xy = u_xlat16_14.xy + vec2(-1.0, -1.0);
    u_xlat16_14.xy = vec2(u_xlat85) * u_xlat16_36.xy;
    u_xlat16_36.x = dot(u_xlat16_14.xy, u_xlat16_14.xy);
    u_xlat16_36.x = min(u_xlat16_36.x, 1.0);
    u_xlat16_36.x = (-u_xlat16_36.x) + 1.0;
    u_xlat16_14.z = sqrt(u_xlat16_36.x);

    //finalSlowWaveNormal
    u_xlat11.xyz = (-u_xlat16_13.xyz) + u_xlat16_14.xyz;
    u_xlat11.xyz = vec3(u_xlat88) * u_xlat11.xyz + u_xlat16_13.xyz;
    u_xlat12.xy = u_xlat62.xy * _MicroWaveTiling.xy;


    //microNormal
    u_xlat16_12.xyz = texture(_WaterNormal, u_xlat12.xy).xyw;
    u_xlat16_13.x = dot(u_xlat16_12.zz, u_xlat16_12.xx);
    u_xlat16_13.y = u_xlat16_12.y + u_xlat16_12.y;
    u_xlat16_36.xy = u_xlat16_13.xy + vec2(-1.0, -1.0);
    u_xlat16_36.xy = u_xlat64.xx * u_xlat16_36.xy;
    u_xlat16_90 = dot(u_xlat16_36.xy, u_xlat16_36.xy);
    u_xlat16_90 = min(u_xlat16_90, 1.0);
    u_xlat16_90 = (-u_xlat16_90) + 1.0;
    u_xlat16_90 = sqrt(u_xlat16_90);


    u_xlat62.xy = u_xlat11.xy * vec2(0.0500000007, 0.0500000007) + u_xlat62.xy;

    //macroNormal
    u_xlat16_12.xyz = texture(_WaterNormal, u_xlat62.xy).xyw;
    u_xlat16_13.x = dot(u_xlat16_12.zz, u_xlat16_12.xx);
    u_xlat16_13.y = u_xlat16_12.y + u_xlat16_12.y;
    u_xlat16_13.xy = u_xlat16_13.xy + vec2(-1.0, -1.0);
    u_xlat16_13.xy = u_xlat64.yy * u_xlat16_13.xy;
    u_xlat16_67 = dot(u_xlat16_13.xy, u_xlat16_13.xy);
    u_xlat16_67 = min(u_xlat16_67, 1.0);
    u_xlat16_67 = (-u_xlat16_67) + 1.0;
    u_xlat16_67 = sqrt(u_xlat16_67);


    u_xlat16_13.xy = vec2(u_xlat16_90) * u_xlat16_13.xy;
    u_xlat16_12.xy = u_xlat16_36.xy * vec2(u_xlat16_67) + u_xlat16_13.xy;

    u_xlat16_12.zw = vec2(u_xlat16_90) * vec2(u_xlat16_67);
    u_xlat16_36.x = dot(u_xlat16_12.xyw, u_xlat16_12.xyw);
    u_xlat16_36.x = inversesqrt(u_xlat16_36.x);
    u_xlat16_12 = u_xlat16_36.xxxx * u_xlat16_12;
    u_xlat16_13 = u_xlat11.zzxy * u_xlat16_12;
    u_xlat16_13.xy = u_xlat16_13.zw + u_xlat16_13.xy;
    u_xlat16_13.z = u_xlat11.z * u_xlat16_12.w;


    u_xlat16_36.x = dot(u_xlat16_13.xyz, u_xlat16_13.xyz);
    u_xlat16_36.x = inversesqrt(u_xlat16_36.x);
    u_xlat16_14.xyz = u_xlat16_36.xxx * u_xlat16_13.xyz;


    //waterFallEffectTiling1
    //waterFallEffectTiling2
    u_xlat12.y = u_xlat87 * _WaterFallEffectTiling.w;
    u_xlat66.y = u_xlat87 * _WaterFallEffectTiling2.w;

    //bigFinalNormal
    u_xlat15.xyz = (-u_xlat16_13.xyz) * u_xlat16_36.xxx + vec3(0.0, 0.0, 1.0);
    u_xlat15.xyz = vec3(u_xlat83) * u_xlat15.xyz + u_xlat16_14.xyz;

    //formInstensity
    u_xlat82 = inversesqrt(u_xlat82);
    u_xlat82 = float(1.0) / u_xlat82;
    u_xlat82 = u_xlat82 * _FoamIntensity;


    //realFoamSpeed
    u_xlat16.xyz = u_xlat4.xyy * vec3(4.0, 4.0, 0.173643112);

    //foamUVOffset
    u_xlat62.xy = vs_TEXCOORD6.xy * _TilingSpeedFoam.xy + u_xlat16.xy;
    u_xlat62.xy = u_xlat62.xy * vec2(0.00390625, 0.00390625) + u_xlat15.xy;

    //waterFoam
    u_xlat16_85 = texture(_WaterFoam, u_xlat62.xy).x;
    u_xlat16.x = u_xlat4.x * 0.984808624 + (-u_xlat16.z);

    u_xlat16.y = dot(u_xlat4.xy, vec2(0.173643112, 0.984808624));

    u_xlat4.xy = vs_TEXCOORD6.xy * _TilingSpeedFoam.xy + u_xlat16.xy;
    u_xlat4.xy = u_xlat4.xy * vec2(0.0078125, 0.0078125) + vec2(0.5, 0.5);

    u_xlat16_4 = texture(_WaterFoam, u_xlat4.xy).x;
    u_xlat4.x = u_xlat16_4 * 0.400000006;
    u_xlat4.x = u_xlat16_85 * 0.600000024 + u_xlat4.x;

    //formInstensity
    u_xlat82 = u_xlat82 * u_xlat4.x;


    u_xlat4.y = vs_TEXCOORD6.x * _WaterFallEffectTiling.y;
    u_xlat4.x = vs_TEXCOORD6.y * _WaterFallEffectTiling.x + _WaterFallEffectTiling.z;
    u_xlat12.x = float(0.0);
    u_xlat66.x = float(0.0);
    u_xlat4.xy = u_xlat12.xy + u_xlat4.xy;
    //waterFallEffect
    u_xlat16_13 = texture(_WaterFallEffect, u_xlat4.xy);

    u_xlat4.y = vs_TEXCOORD6.x * _WaterFallEffectTiling2.y;
    u_xlat4.x = vs_TEXCOORD6.y * _WaterFallEffectTiling2.x + _WaterFallEffectTiling2.z;
    u_xlat4.xy = u_xlat66.xy + u_xlat4.xy;
    //waterFallEffect2
    u_xlat16_12 = texture(_WaterFallEffect, u_xlat4.xy);


    u_xlat12 = u_xlat16_12.wxyz + u_xlat16_13.wxyz;
    u_xlat12.x = u_xlat12.x;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat16_14.x = dot(u_xlat12.xx, u_xlat12.yy);

    u_xlat16_14.y = u_xlat12.z + u_xlat12.z;

    u_xlat16_36.xy = u_xlat16_14.xy + vec2(-1.0, -1.0);
    u_xlat16_14.xy = u_xlat16_36.xy * vec2(vec2(_ShadowDistort, _ShadowDistort));

    u_xlat16_36.x = dot(u_xlat16_14.xy, u_xlat16_14.xy);
    u_xlat16_36.x = min(u_xlat16_36.x, 1.0);
    u_xlat16_36.x = (-u_xlat16_36.x) + 1.0;
    u_xlat16_14.z = sqrt(u_xlat16_36.x);

    //waterFallColor
    u_xlat4.xyw = vec3(u_xlat82) * vec3(vec3(_ShadowDistort, _ShadowDistort, _ShadowDistort)) + u_xlat16_14.xyz;


    //水面交互的波纹
    //TODO DynamicWave 可以结合浅水方程来实现
    u_xlat62.xy = u_xlat5.zw + (-_DynWaveTexPos_TexelWidth.xy);
    u_xlat62.xy = u_xlat62.xy * _DynWaveTexPos_TexelWidth.zw;
    u_xlatb87 = 0.0<_DynWaveOn;
    u_xlatb64.xy = greaterThanEqual(vec4(1.0, 1.0, 1.0, 1.0), abs(u_xlat62.xyxy)).xy;
    u_xlatb88 = u_xlatb64.y && u_xlatb64.x;
    u_xlatb87 = u_xlatb87 && u_xlatb88;
    if(u_xlatb87){
        u_xlat62.xy = u_xlat62.xy * vec2(0.5, 0.5) + vec2(0.5, 0.5);
        u_xlat10_62.xy = texture(_DynamicWaves_Target, u_xlat62.xy).zw;
        u_xlat16_14.xz = u_xlat10_62.xy * vec2(2.0, 2.0) + vec2(-1.0, -1.0);
        u_xlat16_36.x = (-u_xlat16_14.x) * u_xlat16_14.x + 1.0;
        u_xlat16_36.x = (-u_xlat16_14.z) * u_xlat16_14.z + u_xlat16_36.x;
        u_xlat16_36.x = max(u_xlat16_36.x, 0.0);
        u_xlat16_14.y = sqrt(u_xlat16_36.x);
        u_xlat16.xyz = u_xlat15.xyz + vec3(0.0, 1.0, 0.0);
        u_xlat17.xyz = u_xlat16_14.xyz * vec3(-1.0, 1.0, -1.0);
        u_xlat87 = dot(u_xlat16.xyz, u_xlat17.xyz);
        u_xlat16.xzw = vec3(u_xlat87) * u_xlat16.xyz;
        u_xlat16.xyz = u_xlat16.xzw / u_xlat16.yyy;
        u_xlat16.xyz = (-u_xlat16_14.xyz) * vec3(-1.0, 1.0, -1.0) + u_xlat16.xyz;
        u_xlat16_16.xyz = u_xlat16.xyz;
    } else {
        u_xlat16_16.xyz = u_xlat15.xyz;
    }


    u_xlat62.xy = u_xlat16_16.xy * vec2(_Distortion);
    u_xlat87 = _ZBufferParams.z * vs_TEXCOORD7.z + _ZBufferParams.w;
    u_xlat87 = float(1.0) / u_xlat87;
    u_xlat88 = (-_ProjectionParams.y) + _ProjectionParams.z;
    u_xlat64.x = (-vs_TEXCOORD7.z) + 1.0;
    u_xlat64.x = u_xlat88 * u_xlat64.x + _ProjectionParams.y;
    u_xlat64.x = (-u_xlat87) + u_xlat64.x;
    u_xlat87 = unity_OrthoParams.w * u_xlat64.x + u_xlat87;
    u_xlat87 = u_xlat87 + (-vs_TEXCOORD5.w);
    //pixelEyeDepth
    u_xlat87 = unity_OrthoParams.w * u_xlat87 + vs_TEXCOORD5.w;


    u_xlat64.xy = vec2(u_xlat10_58) * u_xlat62.xy;

    u_xlat62.xy = vec2(u_xlat10_58) * u_xlat62.xy + u_xlat10.xy;
    u_xlat62.xy = u_xlat62.xy * _DepthDynamicScale.xy;
    u_xlat62.xy = max(u_xlat62.xy, vec2(0.0, 0.0));
    u_xlat15.xy = min(u_xlat62.xy, _DepthDynamicScale.zw);
    u_xlat92 = textureLod(_CameraDepthTexture, u_xlat15.xy, 0.0).x;


    u_xlat15.x = _ZBufferParams.z * u_xlat92 + _ZBufferParams.w;
    u_xlat15.x = float(1.0) / u_xlat15.x;

    u_xlat92 = (-u_xlat92) + 1.0;
    u_xlat92 = u_xlat88 * u_xlat92 + _ProjectionParams.y;
    u_xlat92 = (-u_xlat15.x) + u_xlat92;

    //texEyeDepth
    u_xlat92 = unity_OrthoParams.w * u_xlat92 + u_xlat15.x;
    u_xlatb92 = u_xlat92>=u_xlat87;
    u_xlat92 = u_xlatb92 ? 1.0 : float(0.0);

    //opaqueColorUV
    u_xlat10.xy = vec2(u_xlat92) * u_xlat64.xy + u_xlat10.xy;

    //waterFallColor
    u_xlat4.xyw = vec3(u_xlat83) * u_xlat4.xyw + u_xlat1.xyz;

    //TODO bakedWaterShadowMap
    u_xlat15.xyz = u_xlat4.yyy * hlslcc_mtx4x4_BakedWaterShadowMapVPMat[1].xyz;
    u_xlat15.xyz = hlslcc_mtx4x4_BakedWaterShadowMapVPMat[0].xyz * u_xlat4.xxx + u_xlat15.xyz;
    u_xlat4.xyw = hlslcc_mtx4x4_BakedWaterShadowMapVPMat[2].xyz * u_xlat4.www + u_xlat15.xyz;
    u_xlat4.xyw = u_xlat4.xyw + hlslcc_mtx4x4_BakedWaterShadowMapVPMat[3].xyz;
    u_xlat10_4 = texture(_BakedWaterShadowMap, u_xlat4.xy).x;
    u_xlat16_36.x = (-_ShadowIntensity) + 1.0;
    u_xlat16_36.x = u_xlat10_4 * _ShadowIntensity + u_xlat16_36.x;
    u_xlatb4 = 0.0>=u_xlat4.w;
    u_xlatb31 = u_xlat4.w>=1.0;
    u_xlatb4 = u_xlatb31 || u_xlatb4;
    u_xlat4.x = (u_xlatb4) ? 1.0 : u_xlat16_36.x;


    u_xlat31.xz = u_xlat10.xy * _OpaqueColorDynamicScale.xy;
    u_xlat31.xz = max(u_xlat31.xz, vec2(0.0, 0.0));
    u_xlat31.xz = min(u_xlat31.xz, _OpaqueColorDynamicScale.zw);
    //opaqueColor
    u_xlat16_10.xyz = textureLod(_CameraOpaqueTexture, u_xlat31.xz, 0.0).xyz;

    //underWaterColor
    u_xlat15.xyz = u_xlat16_10.xyz * _UnderWaterColor.xyz;


    u_xlat31.xz = vs_TEXCOORD5.xy / vs_TEXCOORD5.ww;
    u_xlat31.xz = u_xlat31.xz * _DepthDynamicScale.xy;
    u_xlat31.xz = max(u_xlat31.xz, vec2(0.0, 0.0));
    u_xlat31.xz = min(u_xlat31.xz, _DepthDynamicScale.zw);
    //baseTexDepth
    u_xlat31.x = textureLod(_CameraDepthTexture, u_xlat31.xz, 0.0).x;
    u_xlat85 = _ZBufferParams.z * u_xlat31.x + _ZBufferParams.w;
    u_xlat85 = float(1.0) / u_xlat85;
    u_xlat31.x = (-u_xlat31.x) + 1.0;
    u_xlat31.x = u_xlat88 * u_xlat31.x + _ProjectionParams.y;
    u_xlat31.x = (-u_xlat85) + u_xlat31.x;
    //baseEyeTexDepth
    u_xlat31.x = unity_OrthoParams.w * u_xlat31.x + u_xlat85;


    u_xlat31.x = (-u_xlat87) + u_xlat31.x;
    u_xlat31.x = max(abs(u_xlat31.x), _MinWaterDepth);
    u_xlat85 = u_xlat31.x * _ShalowFalloffMultiply;
    u_xlat85 = log2(u_xlat85);
    u_xlat85 = u_xlat85 * (-_ShalowFalloffPower);
    u_xlat85 = exp2(u_xlat85);
    //shalowFalloff
    u_xlat85 = min(u_xlat85, 1.0);


    u_xlat87 = float(1.0) / gEdgeDepth;
    u_xlat87 = u_xlat31.x * u_xlat87;
    u_xlat87 = clamp(u_xlat87, 0.0, 1.0);

    u_xlat88 = u_xlat87 * -2.0 + 3.0;
    u_xlat87 = u_xlat87 * u_xlat87;
    u_xlat87 = u_xlat87 * u_xlat88;

    u_xlat17.xyz = _ShalowColor.xyz + (-_DeepColor.xyz);
    //waterBaseColor
    u_xlat17.xyz = vec3(u_xlat85) * u_xlat17.xyz + _DeepColor.xyz;

    u_xlat88 = max(_MainLightColor.y, _MainLightColor.x);
    u_xlat88 = max(u_xlat88, _MainLightColor.z);
    u_xlatb91 = 1.0<u_xlat88;
    u_xlat18.xyz = _MainLightColor.xyz / vec3(u_xlat88);
    //lightColor
    u_xlat18.xyz = (bool(u_xlatb91)) ? u_xlat18.xyz : _MainLightColor.xyz;


    u_xlat19.xyz = u_xlat17.xyz * u_xlat18.xyz + (-u_xlat17.xyz);
    //waterBaseColor
    u_xlat17.xyz = vec3(_EnvIntensity) * u_xlat19.xyz + u_xlat17.xyz;


    u_xlat85 = (-u_xlat85) + 1.0;
    u_xlat85 = u_xlat87 * u_xlat85;

    u_xlat10.xyz = (-u_xlat16_10.xyz) * _UnderWaterColor.xyz + u_xlat17.xyz;

    //waterBaseColor = lerp(waterBaseColor, underWaterColor, underWaterLerp);
    u_xlat10.xyz = vec3(u_xlat85) * u_xlat10.xyz + u_xlat15.xyz;

    u_xlat17.xyz = u_xlat18.xyz + (-_AmbientColor.xyz);
    //ambientColor
    u_xlat17.xyz = u_xlat4.xxx * u_xlat17.xyz + _AmbientColor.xyz;

    u_xlat17.xyz = u_xlat17.xyz + vec3(-1.0, -1.0, -1.0);
    //ambientColor = lerp(float3(1, 1, 1), ambientColor, _EnvIntensity);
    u_xlat17.xyz = vec3(_EnvIntensity) * u_xlat17.xyz + vec3(1.0, 1.0, 1.0);


    u_xlat17.xyz = clamp(u_xlat17.xyz, 0.0, 1.0);
    u_xlat17.xyz = u_xlat12.yzw * u_xlat17.xyz + (-u_xlat10.xyz);
    //waterBaseColor = lerp(waterBaseColor, ambientColor * waterFallEffect.yzw, bigCascade);
    u_xlat10.xyz = vec3(u_xlat83) * u_xlat17.xyz + u_xlat10.xyz;


    u_xlat31.x = u_xlat31.x * _CleanFalloffMultiply;
    u_xlat31.x = log2(abs(u_xlat31.x));
    u_xlat31.x = u_xlat31.x * _CleanFalloffPower;
    u_xlat31.x = exp2(u_xlat31.x);

    u_xlat31.x = min(u_xlat31.x, 1.0);

    u_xlat85 = u_xlat31.x * _BackfaceAlpha;
    //cleanFalloff
    u_xlat31.x = ((gl_FrontFacing ? 0xffffffffu : uint(0)) != uint(0)) ? u_xlat31.x : u_xlat85;

    //maxFalloff
    u_xlat85 = u_xlat10_58 * u_xlat31.x;
    u_xlat17.xyz = _EnvColor.xyz * vec3(_WaterSpecularClose);
    u_xlat17.xyz = u_xlat17.xyz * _AmbientColor.xyz + (-vec3(_WaterSpecularClose));
    //waterSpecularCloseColor
    u_xlat17.xyz = vec3(_EnvIntensity) * u_xlat17.xyz + vec3(_WaterSpecularClose);


    u_xlat6.z = u_xlat0.x;
    u_xlat16_20.x = dot(u_xlat11.xyz, u_xlat6.xyz);
    u_xlat7.z = u_xlat0.y;
    u_xlat16_20.y = dot(u_xlat11.xyz, u_xlat7.xyz);
    u_xlat0.xy = u_xlat8.xy;
    u_xlat16_20.z = dot(u_xlat11.xyz, u_xlat0.xyz);

    u_xlat16_36.x = dot(u_xlat16_20.xyz, u_xlat16_20.xyz);
    u_xlat16_36.x = inversesqrt(u_xlat16_36.x);
    u_xlat16_21.xyz = u_xlat16_36.xxx * u_xlat16_20.xyz;


    //tempNormalWorld
    u_xlat11.xyz = vec3(u_xlat83) * vec3(0.0, -1.0, 1.0) + vec3(0.0, 1.0, 0.0);
    u_xlat87 = u_xlat3.y + u_xlat3.y;
    u_xlat87 = min(abs(u_xlat87), 1.0);
    u_xlat87 = (-u_xlat87) + 1.0;

    u_xlat11.xyz = (-u_xlat16_20.xyz) * u_xlat16_36.xxx + u_xlat11.xyz;

    //tempNormalWorld = lerp(normalWorld, tempNormalWorld, viewYParam);
    u_xlat11.xyz = vec3(u_xlat87) * u_xlat11.xyz + u_xlat16_21.xyz;


    //normalWithWave
    u_xlat16_20.x = dot(u_xlat16_16.xyz, u_xlat6.xyz);
    u_xlat16_20.y = dot(u_xlat16_16.xyz, u_xlat7.xyz);
    u_xlat16_20.z = dot(u_xlat16_16.xyz, u_xlat0.xyz);

    u_xlat16_36.x = dot(u_xlat16_20.xyz, u_xlat16_20.xyz);
    u_xlat16_36.x = inversesqrt(u_xlat16_36.x);

    //finalNormalWorld
    u_xlat16_6.xyz = u_xlat16_36.xxx * u_xlat16_20.xyz;

    u_xlatb0 = u_xlat83<1.0;
    if(u_xlatb0){
        u_xlat16_36.x = dot((-u_xlat3.xyz), u_xlat11.xyz);
        u_xlat16_36.x = u_xlat16_36.x + u_xlat16_36.x;
        u_xlat16_7.xyz = u_xlat11.xyz * (-u_xlat16_36.xxx) + (-u_xlat3.xyz);

        u_xlat16_7.w = max(u_xlat16_7.y, 0.0);
        u_xlat16_36.x = dot(u_xlat16_7.xzw, u_xlat16_7.xzw);
        u_xlat16_36.x = inversesqrt(u_xlat16_36.x);
        u_xlat16_8.xyz = u_xlat16_7.xwz * u_xlat16_36.xxx;

        u_xlatb0 = 0<_WATERSSR_ON;
        if(u_xlatb0){
            u_xlat0.xyz = vs_TEXCOORD3.www * hlslcc_mtx4x4unity_MatrixVP[1].xyw;
            u_xlat0.xyz = hlslcc_mtx4x4unity_MatrixVP[0].xyw * vs_TEXCOORD2.www + u_xlat0.xyz;
            u_xlat0.xyz = hlslcc_mtx4x4unity_MatrixVP[2].xyw * vs_TEXCOORD4.www + u_xlat0.xyz;
            u_xlat0.xyz = u_xlat0.xyz + hlslcc_mtx4x4unity_MatrixVP[3].xyw;

            u_xlat19.xyz = u_xlat16_7.xwz * u_xlat16_36.xxx + u_xlat1.xyz;

            u_xlat22.xyz = u_xlat19.yyy * hlslcc_mtx4x4unity_MatrixVP[1].xyw;
            u_xlat19.xyw = hlslcc_mtx4x4unity_MatrixVP[0].xyw * u_xlat19.xxx + u_xlat22.xyz;
            u_xlat19.xyz = hlslcc_mtx4x4unity_MatrixVP[2].xyw * u_xlat19.zzz + u_xlat19.xyw;
            u_xlat19.xyz = u_xlat19.xyz + hlslcc_mtx4x4unity_MatrixVP[3].xyw;

            u_xlatb91 = u_xlat19.z>=u_xlat0.z;
            if(u_xlatb91){
                u_xlat22.xy = vs_TEXCOORD3.ww * hlslcc_mtx4x4unity_MatrixVP[1].xy;
                u_xlat22.xy = hlslcc_mtx4x4unity_MatrixVP[0].xy * vs_TEXCOORD2.ww + u_xlat22.xy;
                u_xlat22.xy = hlslcc_mtx4x4unity_MatrixVP[2].xy * vs_TEXCOORD4.ww + u_xlat22.xy;
                u_xlat22.xy = u_xlat22.xy + hlslcc_mtx4x4unity_MatrixVP[3].xy;

                u_xlat50.z = float(1.0) / u_xlat0.z;
                u_xlat24.x = float(0.5);
                u_xlat24.z = float(0.5);
                u_xlat24.y = _ProjectionParams.x;
                u_xlat13.xyz = u_xlat0.xyz * u_xlat24.xyz;
                u_xlat13.w = u_xlat13.y * 0.5;
                u_xlat0.xy = u_xlat13.zz + u_xlat13.xw;
                u_xlat50.xy = u_xlat50.zz * u_xlat0.xy;
                u_xlat52.z = float(1.0) / u_xlat19.z;
                u_xlat13.xyz = u_xlat19.xyz * u_xlat24.xyz;
                u_xlat13.w = u_xlat13.y * 0.5;
                u_xlat0.xy = u_xlat13.zz + u_xlat13.xw;
                u_xlat52.xy = u_xlat52.zz * u_xlat0.xy;
                u_xlat19.xyz = (-u_xlat50.xyz) + u_xlat52.xyz;
                u_xlat0.xy = abs(u_xlat19.yx) * _ScreenParams.yx;
                u_xlat0.xy = vec2(1.0, 1.0) / u_xlat0.xy;
                u_xlatb91 = abs(u_xlat19.y)<abs(u_xlat19.x);
                u_xlat91 = u_xlatb91 ? 1.0 : float(0.0);
                u_xlat27.x = (-u_xlat0.x) + u_xlat0.y;
                u_xlat0.x = u_xlat91 * u_xlat27.x + u_xlat0.x;
                u_xlat0.x = u_xlat0.x * _SSRParam.x;
                u_xlat19.xyz = u_xlat0.xxx * u_xlat19.xyz;
                u_xlat0.x = dot(u_xlat22.xy, vec2(0.0671105608, 0.00583714992));
                u_xlat0.x = fract(u_xlat0.x);
                u_xlat0.x = u_xlat0.x * 52.9829178;
                u_xlat0.x = fract(u_xlat0.x);
                u_xlat0.x = u_xlat0.x * 0.100000001 + 1.0;
                u_xlat13.z = 1.0;
                u_xlat14.x = float(0.0);
                u_xlat14.y = float(0.0);
                u_xlat14.z = float(0.0);
                u_xlat14.w = float(0.0);
                u_xlat16_63 = u_xlat0.z;
                u_xlat16_90 = u_xlat0.x;
                u_xlat22.xy = u_xlat50.xy;
                u_xlat27.x = 0.0;
                u_xlati91 = 0;
                u_xlati92 = 0;
                u_xlati96 = 0;
                while(true){
                    u_xlat98 = float(u_xlati92);
                    u_xlatb98 = u_xlat98>=_SSRParam.y;
                    u_xlati96 = 0;
                    if(u_xlatb98){break;}
                    u_xlat16.yzw = u_xlat19.xyz * vec3(u_xlat16_90) + u_xlat50.xyz;
                    u_xlatb98 = 0.0>=u_xlat16.z;
                    u_xlatb99 = u_xlat16.z>=1.0;
                    u_xlatb98 = u_xlatb98 || u_xlatb99;
                    if(u_xlatb98){
                        u_xlati96 = 0;
                        break;
                    }
                    u_xlat98 = max(u_xlat16.y, 9.99999975e-05);
                    u_xlat16.x = min(u_xlat98, 0.999899983);
                    u_xlat76.xy = u_xlat16.xz * _DepthDynamicScale.xy;
                    u_xlat76.xy = max(u_xlat76.xy, vec2(0.0, 0.0));
                    u_xlat76.xy = min(u_xlat76.xy, _DepthDynamicScale.zw);
                    u_xlat98 = textureLod(_CameraDepthTexture, u_xlat76.xy, 0.0).x;
                    u_xlat98 = _ZBufferParams.z * u_xlat98 + _ZBufferParams.w;
                    u_xlat98 = float(1.0) / u_xlat98;
                    u_xlat99 = float(1.0) / u_xlat16.w;
                    u_xlat100 = (-u_xlat98) + u_xlat99;
                    u_xlatb76 = u_xlat98<u_xlat0.z;
                    u_xlati76 = int(uint(u_xlati91) | (uint(u_xlatb76) * 0xffffffffu));
                    u_xlatb103 = 0.0<u_xlat100;
                    u_xlatb98 = u_xlat0.z<u_xlat98;
                    u_xlatb98 = u_xlatb98 && u_xlatb103;
                    u_xlat16_20.x = (-u_xlat16_63) + u_xlat99;
                    u_xlat16_20.x = abs(u_xlat16_20.x) + abs(u_xlat16_20.x);
                    u_xlatb103 = u_xlat100<u_xlat16_20.x;
                    u_xlatb98 = u_xlatb98 && u_xlatb103;
                    if(u_xlatb98){
                        u_xlat103 = u_xlat27.x + (-u_xlat100);
                        u_xlat103 = u_xlat27.x / u_xlat103;
                        u_xlat103 = clamp(u_xlat103, 0.0, 1.0);
                        u_xlatb23 = u_xlat99>=_ProjectionParams.z;
                        u_xlat23 = u_xlatb23 ? 1.0 : float(0.0);
                        u_xlat105 = (-u_xlat103) + 1.0;
                        u_xlat103 = u_xlat23 * u_xlat105 + u_xlat103;
                        u_xlat25.xy = (-u_xlat22.xy) + u_xlat16.xz;
                        u_xlat13.xy = vec2(u_xlat103) * u_xlat25.xy + u_xlat22.xy;
                        u_xlati103 = int(uint(u_xlati76) & 1u);
                        u_xlat13.w = float(u_xlati103);
                        u_xlat14 = u_xlat13;
                        u_xlati91 = u_xlati76;
                        u_xlati96 = int(0xFFFFFFFFu);
                        break;
                    }
                    u_xlat16_90 = u_xlat16_90 + 2.0;
                    u_xlat16_63 = u_xlat99;
                    u_xlat22.xy = u_xlat16.xz;
                    u_xlat27.x = u_xlat100;
                    u_xlati91 = u_xlati76;
                    u_xlati96 = int(u_xlatb98);
                    u_xlati92 = u_xlati92 + 1;
                    u_xlat14.x = float(0.0);
                    u_xlat14.y = float(0.0);
                    u_xlat14.z = float(0.0);
                    u_xlat14.w = float(0.0);
                }
                if(u_xlati96 == 0) {
                    u_xlat1.xyz = u_xlat16_8.xyz * vec3(10000.0, 10000.0, 10000.0) + u_xlat1.xyz;
                    u_xlat19.xyz = u_xlat1.yyy * hlslcc_mtx4x4unity_MatrixVP[1].xyw;
                    u_xlat19.xyz = hlslcc_mtx4x4unity_MatrixVP[0].xyw * u_xlat1.xxx + u_xlat19.xyz;
                    u_xlat1.xyz = hlslcc_mtx4x4unity_MatrixVP[2].xyw * u_xlat1.zzz + u_xlat19.xyz;
                    u_xlat1.xyz = u_xlat1.xyz + hlslcc_mtx4x4unity_MatrixVP[3].xyw;
                    u_xlat0.x = float(1.0) / u_xlat1.z;
                    u_xlat13.xyz = u_xlat24.xyz * u_xlat1.xyz;
                    u_xlat13.w = u_xlat13.y * 0.5;
                    u_xlat1.xy = u_xlat13.zz + u_xlat13.xw;
                    u_xlat13.zw = u_xlat0.xx * u_xlat1.yx;
                    u_xlat13.x = uintBitsToFloat(uint(u_xlati91) & 1065353216u);
                    u_xlatb0 = 0.0<u_xlat13.z;
                    u_xlatb27 = u_xlat13.z<1.0;
                    u_xlatb0 = u_xlatb27 && u_xlatb0;
                    if(u_xlatb0){
                        u_xlat0.x = max(u_xlat13.w, 9.99999975e-05);
                        u_xlat13.y = min(u_xlat0.x, 0.999899983);
                        u_xlat0.xy = u_xlat13.yz * _DepthDynamicScale.xy;
                        u_xlat0.xy = max(u_xlat0.xy, vec2(0.0, 0.0));
                        u_xlat0.xy = min(u_xlat0.xy, _DepthDynamicScale.zw);
                        u_xlat0.x = textureLod(_CameraDepthTexture, u_xlat0.xy, 0.0).x;
                        u_xlat0.x = _ZBufferParams.z * u_xlat0.x + _ZBufferParams.w;
                        u_xlat0.x = float(1.0) / u_xlat0.x;
                        u_xlati0 = int((u_xlat0.z<u_xlat0.x) ? 0xFFFFFFFFu : uint(0));
                        u_xlat13.w = 1.0;
                        u_xlat14 = (int(u_xlati0) != 0) ? u_xlat13.yzwx : u_xlat14;
                        u_xlat13.x = (u_xlati0 != 0) ? u_xlat13.x : 1.0;
                    } else {
                        u_xlati0 = 0;
                    }
                    u_xlat13.y = 0.0;
                    u_xlat14 = (int(u_xlati0) != 0) ? u_xlat14 : u_xlat13.yyyx;
                    u_xlat13.w = u_xlat14.z;
                } else {
                    u_xlat13.w = u_xlat14.z;
                }
            } else {
                u_xlat13.w = 0.0;
                u_xlat14.x = float(0.0);
                u_xlat14.y = float(0.0);
                u_xlat14.w = float(0.0);
            }
            u_xlat0.xy = u_xlat14.xy * _OpaqueColorDynamicScale.xy;
            u_xlat0.xy = max(u_xlat0.xy, vec2(0.0, 0.0));
            u_xlat0.xy = min(u_xlat0.xy, _OpaqueColorDynamicScale.zw);
            u_xlat0.xyz = textureLod(_CameraOpaqueTexture, u_xlat0.xy, 0.0).xyz;
        } else {
            u_xlat0.x = float(0.0);
            u_xlat0.y = float(0.0);
            u_xlat0.z = float(0.0);
            u_xlat13.w = 0.0;
            u_xlat14.y = float(0.0);
            u_xlat14.w = float(0.0);
        }
        u_xlatu1.xyz = uvec3(floatBitsToUint(u_xlat0.xyz)) & uvec3(2147483647u, 2147483647u, 2147483647u);
        u_xlatb1.xyz = lessThan(uvec4(2139095040u, 2139095040u, 2139095040u, 0u), u_xlatu1.xyzx).xyz;
        u_xlatb1.x = u_xlatb1.y || u_xlatb1.x;
        u_xlatb1.x = u_xlatb1.z || u_xlatb1.x;
        u_xlat13.xyz = (u_xlatb1.x) ? vec3(0.0, 0.0, 0.0) : u_xlat0.xyz;
        u_xlat0.x = abs(u_xlat14.y) * 5.5 + -5.0;
        u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
        u_xlat0.x = dot(u_xlat0.xx, u_xlat0.xx);
        u_xlat0.x = (-u_xlat0.x) + 1.0;
        u_xlat0.x = max(u_xlat0.x, 0.0);
        
        u_xlat27.x = u_xlat14.w * _SSRMissReplaceColorParam.w;
        u_xlat54 = (-u_xlat13.w) + 1.0;
        u_xlat27.x = u_xlat54 * u_xlat27.x;
        u_xlat14.xyz = (-u_xlat13.xyz) + _SSRMissReplaceColorParam.xyz;
        u_xlat14.w = (-u_xlat13.w) + 1.0;
        u_xlat13 = u_xlat27.xxxx * u_xlat14 + u_xlat13;
        u_xlat27.x = (-u_xlat16_7.w) * u_xlat16_36.x + 1.0;
        u_xlat27.y = u_xlat27.x * 0.5;
        u_xlat1.x = (-u_xlat16_8.y) * u_xlat16_8.y + 1.0;
        u_xlat1.x = inversesqrt(u_xlat1.x);
        u_xlat16_8.w = (-u_xlat16_8.x);
        u_xlat28 = dot(u_xlat16_8.wz, g_AtmosphereLightDirection.xy);
        u_xlat1.x = u_xlat1.x * u_xlat28;
        u_xlat1.x = max(u_xlat1.x, -1.0);
        u_xlat1.x = min(u_xlat1.x, 1.0);
        u_xlat28 = abs(u_xlat1.x) * abs(u_xlat1.x);
        u_xlat55 = abs(u_xlat1.x) * u_xlat28;
        u_xlat91 = abs(u_xlat1.x) * -0.212114394 + 1.57072878;
        u_xlat28 = u_xlat28 * 0.0742610022 + u_xlat91;
        u_xlat28 = u_xlat55 * -0.0187292993 + u_xlat28;
        u_xlat55 = -abs(u_xlat1.x) + 1.0;
        u_xlat55 = sqrt(u_xlat55);
        u_xlat91 = u_xlat28 * u_xlat55;
        u_xlatb1.x = u_xlat1.x>=0.0;
        u_xlat28 = (-u_xlat55) * u_xlat28 + 3.14159274;
        u_xlat1.x = (u_xlatb1.x) ? u_xlat91 : u_xlat28;
        u_xlat1.x = u_xlat1.x * 0.318309873;
        u_xlat27.x = sqrt(u_xlat1.x);
        u_xlat27.xy = u_xlat27.xy + vec2(0.00520833349, 0.00480769249);
        u_xlat1.yz = u_xlat27.xy * vec2(0.989690721, 0.990476191);
        u_xlatb27 = CameraAerialPerspectiveVolumeParam2.w<0.0;
        u_xlat54 = max(abs(u_xlat16_8.z), abs(u_xlat16_8.x));
        u_xlat91 = min(abs(u_xlat16_8.z), abs(u_xlat16_8.x));
        u_xlat54 = u_xlat91 / u_xlat54;
        u_xlat91 = u_xlat54 * u_xlat54;
        u_xlat92 = u_xlat91 * 0.0872929022 + -0.301894993;
        u_xlat91 = u_xlat92 * u_xlat91 + 1.0;
        u_xlat92 = u_xlat54 * u_xlat91;
        u_xlatb96 = abs(u_xlat16_8.x)<abs(u_xlat16_8.z);
        u_xlat54 = (-u_xlat91) * u_xlat54 + 1.57079637;
        u_xlat54 = (u_xlatb96) ? u_xlat54 : u_xlat92;
        u_xlatb91 = u_xlat16_8.x<0.0;
        u_xlat92 = (-u_xlat54) + 3.14159274;
        u_xlat54 = (u_xlatb91) ? u_xlat92 : u_xlat54;
        u_xlatb91 = (-u_xlat16_8.z)<0.0;
        u_xlat54 = (u_xlatb91) ? (-u_xlat54) : u_xlat54;
        u_xlat54 = u_xlat54 + 3.14159274;
        u_xlat54 = u_xlat54 * 0.159154937 + 0.00520833349;
        u_xlat54 = u_xlat54 * 0.989690721;
        u_xlat1.x = (u_xlatb27) ? u_xlat54 : u_xlat1.y;
        u_xlat19.xyz = textureLod(SkyViewLutTextureL, u_xlat1.xz, 0.0).xyz;
        u_xlatb27 = CameraAerialPerspectiveVolumeParam2.w>=0.0;
        if(u_xlatb27){
            u_xlat10_1.xyz = textureLod(SkyViewLutTextureR, u_xlat1.xz, 0.0).xyz;
            u_xlat1.xyz = (-u_xlat19.xyz) + u_xlat10_1.xyz;
            u_xlat19.xyz = CameraAerialPerspectiveVolumeParam2.www * u_xlat1.xyz + u_xlat19.xyz;
        }
        u_xlatu1.xyz = uvec3(floatBitsToUint(u_xlat19.xyz)) & uvec3(2147483647u, 2147483647u, 2147483647u);
        u_xlatb1.xyz = lessThan(uvec4(2139095040u, 2139095040u, 2139095040u, 0u), u_xlatu1.xyzx).xyz;
        u_xlatb27 = u_xlatb1.y || u_xlatb1.x;
        u_xlatb27 = u_xlatb1.z || u_xlatb27;
        u_xlat16_36.xyz = (bool(u_xlatb27)) ? vec3(0.0, 0.0, 0.0) : u_xlat19.xyz;
        u_xlat0.x = u_xlat0.x * u_xlat13.w;
        u_xlat1.xyz = (-u_xlat16_36.xyz) + u_xlat13.xyz;
        u_xlat0.xyz = u_xlat0.xxx * u_xlat1.xyz + u_xlat16_36.xyz;
        u_xlat16_36.xyz = min(u_xlat0.xyz, vec3(1.0, 1.0, 1.0));
        u_xlatb0 = 0.5<_RayTracingRef;
        u_xlat16_36.xyz = (bool(u_xlatb0)) ? vec3(0.0, 0.0, 0.0) : u_xlat16_36.xyz;
    } else {
        u_xlat16_36.x = float(0.0);
        u_xlat16_36.y = float(0.0);
        u_xlat16_36.z = float(0.0);
    }
    u_xlat0.xyz = u_xlat10.xyz * vec3(0.5, 0.5, 0.5) + (-u_xlat16_36.xyz);

    //float3 waterBaseColor2 = lerp(reflectColor, waterBaseColor * 0.5, bigCascade);
    u_xlat0.xyz = vec3(u_xlat83) * u_xlat0.xyz + u_xlat16_36.xyz;

    u_xlat16_36.xyz = u_xlat4.xxx * u_xlat10.xyz;
    u_xlat16_20.xyz = (-u_xlat17.xyz) + vec3(1.0, 1.0, 1.0);
    //float3 bakedColorTemp = (bakedWaterShadowMap * waterBaseColor) * (1 - waterSpecularCloseColor);
    u_xlat16_36.xyz = u_xlat16_36.xyz * u_xlat16_20.xyz;

    u_xlat16_20.x = (-_WaterSmoothness) + 1.0;
    u_xlat16_20.x = u_xlat16_20.x * u_xlat16_20.x;
    u_xlat16_20.x = max(u_xlat16_20.x, 6.10351562e-05);
    u_xlat16_47.x = u_xlat16_20.x * u_xlat16_20.x;
    u_xlat1.x = u_xlat16_20.x * 4.0 + 2.0;
    u_xlat28 = u_xlat16_20.x * u_xlat16_20.x + -1.0;
    u_xlat16_6.w = 1.0;


    //indirectDiffuse
    u_xlat16_21.x = dot(ambient_SH[0], u_xlat16_6);
    u_xlat16_21.y = dot(ambient_SH[1], u_xlat16_6);
    u_xlat16_21.z = dot(ambient_SH[2], u_xlat16_6);
    u_xlat16_20.xzw = u_xlat16_21.xyz + vs_TEXCOORD1.xyz;



    //NoL
    u_xlat16_21.x = dot(u_xlat16_6.xyz, _MainLightPosition.xyz);
    u_xlat16_21.x = clamp(u_xlat16_21.x, 0.0, 1.0);
    //NoL * lightColor
    u_xlat16_21.xyz = u_xlat16_21.xxx * _MainLightColor.xyz;

    u_xlat2.xyz = u_xlat2.xyz * vec3(u_xlat81) + _MainLightPosition.xyz;
    u_xlat16_102 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat16_102 = max(u_xlat16_102, 6.10351562e-05);
    u_xlat16_102 = inversesqrt(u_xlat16_102);

    //halfDir
    u_xlat16_26.xyz = u_xlat2.xyz * vec3(u_xlat16_102);


    //NoH
    u_xlat81 = dot(u_xlat16_6.xyz, u_xlat16_26.xyz);
    u_xlat81 = clamp(u_xlat81, 0.0, 1.0);

    //LoH
    u_xlat55 = dot(_MainLightPosition.xyz, u_xlat16_26.xyz);
    u_xlat55 = clamp(u_xlat55, 0.0, 1.0);

    //NoH^2
    u_xlat81 = u_xlat81 * u_xlat81;
    //NoH^2 * roughness2MinusOne + 1
    u_xlat81 = u_xlat81 * u_xlat28 + 1.00001001;

    u_xlat16_102 = u_xlat55 * u_xlat55;
    u_xlat81 = u_xlat81 * u_xlat81;
    u_xlat28 = max(u_xlat16_102, 0.100000001);
    u_xlat81 = u_xlat81 * u_xlat28;
    u_xlat81 = u_xlat1.x * u_xlat81;
    u_xlat81 = u_xlat16_47.x / u_xlat81;
    u_xlat16_47.x = u_xlat81 + -6.10351562e-05;
    u_xlat16_47.x = max(u_xlat16_47.x, 0.0);
    u_xlat16_47.x = min(u_xlat16_47.x, 100.0);


    //brdf * waterSpecularCloseColor + bakedColorTemp
    u_xlat16_26.xyz = u_xlat16_47.xxx * u_xlat17.xyz + u_xlat16_36.xyz;

    u_xlat16_21.xyz = u_xlat16_21.xyz * u_xlat16_26.xyz;

    u_xlat16_21.xyz = vec3(u_xlat83) * (-u_xlat16_21.xyz) + u_xlat16_21.xyz;


    u_xlat16_36.xyz = u_xlat16_20.xzw * u_xlat16_36.xyz + u_xlat16_21.xyz;

    //NoV
    u_xlat81 = dot(u_xlat11.xyz, u_xlat3.xyz);
    u_xlat81 = clamp(u_xlat81, 0.0, 1.0);

    //1 - NoV
    u_xlat81 = (-u_xlat81) + 1.0;

    //(1 - NoV)^4
    u_xlat16_20.x = u_xlat81 * u_xlat81;
    u_xlat16_20.x = u_xlat16_20.x * u_xlat16_20.x;

    u_xlat16_47.xyz = u_xlat0.xyz + (-u_xlat16_36.xyz);
    u_xlat16_36.xyz = u_xlat16_20.xxx * u_xlat16_47.xyz + u_xlat16_36.xyz;


    //resultColor = underWaterColor * bigCascade + resultColor;
    u_xlat0.xyz = vec3(u_xlat83) * u_xlat15.xyz + u_xlat16_36.xyz;

    //1 - bigCascade;
    u_xlat81 = (-u_xlat83) + 1.0;
    //upValue * foamInstensity;
    u_xlat81 = u_xlat81 * u_xlat82;
    //1 - iceIntensity
    u_xlat16_9.x = (-u_xlat16_9.x) + 1.0;
    //
    u_xlat81 = u_xlat81 * u_xlat16_9.x;

    u_xlat1.xyz = vec3(u_xlat82) * u_xlat18.xyz + (-u_xlat0.xyz);
    //lerp(resultColor, foamInstensity * lightColor, tempAAA);
    u_xlat0.xyz = vec3(u_xlat81) * u_xlat1.xyz + u_xlat0.xyz;


    u_xlat1.xyz = u_xlat10.xyz * _WaterFallColor.xyz;

    u_xlat2.xyz = vec3(u_xlat83) * u_xlat1.xyz;

    //resultColor = waterFallColor2 * maxFalloff + resultColor;
    u_xlat0.xyz = u_xlat2.xyz * vec3(u_xlat85) + u_xlat0.xyz;


    u_xlat2.xyz = vec3(u_xlat85) * u_xlat1.xyz;

    u_xlat1.xyz = (-u_xlat1.xyz) * vec3(u_xlat85) + u_xlat0.xyz;

    //lerp(maxFalloff * waterFallColor1, resultColor, bakedWaterShadowMap);
    u_xlat1.xyz = u_xlat4.xxx * u_xlat1.xyz + u_xlat2.xyz;

    u_xlat1.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;
    //resultColor = lerp(resultColor, waterFallColor1, bigCascade);
    u_xlat0.xyz = vec3(u_xlat83) * u_xlat1.xyz + u_xlat0.xyz;


    //waterFallEffectAlpha
    u_xlat81 = u_xlat83 * _WaterFallEffectAlpha;

    u_xlat1.x = (-u_xlat31.x) * u_xlat10_58 + u_xlat12.x;

    //waterFallEffectAlpha = lerp(maxFalloff, waterFallEffect.x, waterFallEffectAlpha);
    u_xlat81 = u_xlat81 * u_xlat1.x + u_xlat85;

    //waterFallEffectAlpha = waterFallEffectAlpha * maxFalloff;
    u_xlat81 = u_xlat81 * u_xlat85;


    u_xlat1.x = u_xlat81 * _WaterFallAlpha + (-u_xlat81);
    u_xlat81 = u_xlat83 * u_xlat1.x + u_xlat81;

    u_xlat1.x = vs_TEXCOORD8.w * gFinalAlpha;
    //waterFallEffectAlpha = waterFallEffectAlpha * i.vertexColor.a * gFinalAlpha;
    u_xlat81 = u_xlat81 * u_xlat1.x;

    u_xlat16_9.x = (-u_xlat3.y) * u_xlat3.y + 1.0;
    u_xlat16_9.x = inversesqrt(u_xlat16_9.x);
    u_xlat3.w = (-u_xlat3.z);
    u_xlat16_36.x = dot(u_xlat3.xw, g_AtmosphereLightDirection.xy);
    u_xlat1.x = u_xlat16_9.x * u_xlat16_36.x;
    u_xlat1.x = max(u_xlat1.x, -1.0);
    u_xlat1.x = min(u_xlat1.x, 1.0);
    u_xlat28 = abs(u_xlat1.x) * abs(u_xlat1.x);
    u_xlat55 = abs(u_xlat1.x) * u_xlat28;
    u_xlat82 = abs(u_xlat1.x) * -0.212114394 + 1.57072878;
    u_xlat28 = u_xlat28 * 0.0742610022 + u_xlat82;
    u_xlat28 = u_xlat55 * -0.0187292993 + u_xlat28;
    u_xlat55 = -abs(u_xlat1.x) + 1.0;
    u_xlat55 = sqrt(u_xlat55);
    u_xlat82 = u_xlat28 * u_xlat55;
    u_xlatb1.x = u_xlat1.x>=0.0;
    u_xlat28 = (-u_xlat55) * u_xlat28 + 3.14159274;
    u_xlat1.x = (u_xlatb1.x) ? u_xlat82 : u_xlat28;
    u_xlat1.x = u_xlat1.x * 0.318309873;
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat2.xy = u_xlat5.zw + (-vec2(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.z));
    u_xlat82 = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat29.y = sqrt(u_xlat82);
    u_xlat29.x = vs_TEXCOORD3.w + g_CameraAerialPerspectiveVolumeParam.x;
    u_xlat16_9.xy = u_xlat29.xy * g_CameraAerialPerspectiveVolumeParam.zy;
    u_xlat16_9.xy = clamp(u_xlat16_9.xy, 0.0, 1.0);
    u_xlat16_28.xy = sqrt(u_xlat16_9.xy);
    u_xlat1.yz = u_xlat16_28.xy;
    u_xlat16_1 = textureLod(AtmosphereCameraScatteringVolume, u_xlat1.xyz, 0.0);
    u_xlat16_9.x = (-u_xlat16_1.w) + 1.0;
    u_xlat0.xyz = u_xlat0.xyz * u_xlat16_9.xxx + u_xlat16_1.xyz;
    SV_Target0.xyz = vs_TEXCOORD0.www * u_xlat0.xyz + vs_TEXCOORD0.xyz;
    SV_Target0.w = u_xlat81;
    return;
}