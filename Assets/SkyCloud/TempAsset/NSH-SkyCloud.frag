#version 450

#ifdef GL_EXT_shader_texture_lod
#extension GL_EXT_shader_texture_lod : enable
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
uniform 	vec3 _WorldSpaceCameraPos;
uniform 	vec4 hlslcc_mtx4x4_LastVp[4];
uniform 	vec4 _PerlinOffsetAndScale;
uniform 	vec4 _WorleyOffsetAndScale;
uniform 	vec4 _startPosOS;
uniform 	vec4 _Worley2Param;
uniform 	vec4 _CloudNoiseParam;
uniform 	vec4 _FakeCloudTransmittanceParam;
uniform 	vec3 scale;
uniform 	vec3 invscale;
uniform 	vec4 _extraParam1;
uniform 	vec4 _sunColor;
uniform 	vec4 _envColor;
uniform 	vec4 _darkColor;
uniform 	vec4 _subRayParam;
uniform 	vec3 _subRayStep;
uniform 	vec3 _sunDir;
uniform 	vec4 _phaseParam;
uniform 	vec4 _backPhaseParam;
uniform 	vec4 _sampleParam;
#if HLSLCC_ENABLE_UNIFORM_BUFFERS
UNITY_BINDING(0) uniform _NshmGlobal {
#endif
	UNITY_UNIFORM mediump vec4 _EnvColor;
	UNITY_UNIFORM mediump vec4 _AmbientColor;
	UNITY_UNIFORM mediump vec4 _EnvStrength;
	UNITY_UNIFORM mediump vec4 _SceneLightGlobalParams;
	UNITY_UNIFORM mediump vec4 _DielectricSpecOverride;
	UNITY_UNIFORM mediump vec4 _DefaultSpecCube_HDR;
	UNITY_UNIFORM mediump vec4 _WindDirection;
	UNITY_UNIFORM mediump vec4 _WindGlobal;
	UNITY_UNIFORM vec3 _SkySunDir;
	UNITY_UNIFORM float _VegetationWindSwitch;
	UNITY_UNIFORM mediump vec4 ambient_SH[3];
	UNITY_UNIFORM mediump vec4 ambientChar_SH[7];
	UNITY_UNIFORM mediump vec4 ambientCharSkin_SH[7];
	UNITY_UNIFORM mediump vec4 _TerrainLightMapColorScale;
	UNITY_UNIFORM mediump vec4 _TerrainLightMapColorBias;
	UNITY_UNIFORM mediump vec4 _TerrainHeightmapBlendScale;
	UNITY_UNIFORM mediump vec4 _CharacterAOSpecularParam;
	UNITY_UNIFORM mediump vec4 _GlobalMipBias;
	UNITY_UNIFORM vec4 _TerrainHeightmapRecipSize;
	UNITY_UNIFORM vec4 _TerrainHeightmapScale;
	UNITY_UNIFORM vec4 VTTerrainSize;
	UNITY_UNIFORM vec4 VTTerainCacheSize;
	UNITY_UNIFORM vec4 VTPageTableSize;
	UNITY_UNIFORM vec4 _StreamAnchorPosHeightmap;
	UNITY_UNIFORM vec4 _TerrainSize;
	UNITY_UNIFORM vec4 topLeftUVHeightmap[4];
	UNITY_UNIFORM vec4 _LightTextureAABBMin;
	UNITY_UNIFORM mediump vec4 g_AtmosphereLightDirection;
	UNITY_UNIFORM mediump vec4 g_CameraAerialPerspectiveVolumeParam;
	UNITY_UNIFORM mediump vec4 g_CameraAerialPerspectiveVolumeParam2;
	UNITY_UNIFORM mediump vec4 _CharacterShadowGlobalParam;
	UNITY_UNIFORM int pangu_LightmapConfig;
	UNITY_UNIFORM int _LightmapBaseConfig;
	UNITY_UNIFORM int overridePropsMaxIndex;
	UNITY_UNIFORM int _DisableDynamicShadow;
	UNITY_UNIFORM float _PreWaterDepthSign;
	UNITY_UNIFORM mediump float _ObjectFresnelIntensity;
	UNITY_UNIFORM mediump float _NoBakedAmbientScale;
	UNITY_UNIFORM mediump float _TerrainBlendDistance;
	UNITY_UNIFORM mediump float _FakeBlendMaskBuff[16];
	UNITY_UNIFORM int _MaxLightmapMipLevel;
#if HLSLCC_ENABLE_UNIFORM_BUFFERS
};
#endif
UNITY_LOCATION(0) uniform mediump sampler3D AtmosphereCameraScatteringVolume;
UNITY_LOCATION(1) uniform mediump sampler3D _worleyNoiseTex;
UNITY_LOCATION(2) uniform mediump sampler2D _HizDepthTex;
UNITY_LOCATION(3) uniform mediump sampler2D _perlinForSkyCloudTex;
UNITY_LOCATION(4) uniform mediump sampler2D _perlinToDilateWorley;
in highp vec4 vs_TEXCOORD0;
in highp vec3 vs_TEXCOORD1;
layout(location = 0) out highp vec4 SV_Target0;
vec4 u_xlat0;
mediump vec4 u_xlat16_0;
ivec4 u_xlati0;
bool u_xlatb0;
vec2 u_xlat1;
mediump vec4 u_xlat16_1;
bvec2 u_xlatb1;
vec4 u_xlat2;
vec4 u_xlat3;
vec3 u_xlat4;
vec2 u_xlat5;
int u_xlati5;
vec3 u_xlat6;
float u_xlat7;
vec4 u_xlat8;
vec3 u_xlat9;
vec3 u_xlat10;
vec2 u_xlat11;
mediump float u_xlat16_11;
mediump vec2 u_xlat16_12;
float u_xlat13;
mediump vec2 u_xlat16_13;
vec3 u_xlat14;
int u_xlati14;
float u_xlat16;
vec3 u_xlat18;
int u_xlati20;
float u_xlat21;
bool u_xlatb21;
mediump float u_xlat16_25;
float u_xlat26;
bool u_xlatb26;
vec2 u_xlat27;
float u_xlat29;
vec2 u_xlat33;
mediump float u_xlat16_33;
bool u_xlatb33;
float u_xlat34;
vec2 u_xlat37;
float u_xlat39;
bool u_xlatb39;
float u_xlat40;
float u_xlat41;
float u_xlat42;
float u_xlat43;
float u_xlat45;
float u_xlat46;
mediump float u_xlat16_46;
bool u_xlatb46;
int u_xlati47;
float u_xlat48;
bool u_xlatb48;
float u_xlat49;
mediump float u_xlat16_49;
void main()
{
    u_xlat0.xyz = vs_TEXCOORD1.yyy * hlslcc_mtx4x4_LastVp[1].xyw;
    u_xlat0.xyz = hlslcc_mtx4x4_LastVp[0].xyw * vs_TEXCOORD1.xxx + u_xlat0.xyz;
    u_xlat0.xyz = hlslcc_mtx4x4_LastVp[2].xyw * vs_TEXCOORD1.zzz + u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz + hlslcc_mtx4x4_LastVp[3].xyw;
    u_xlat0.xy = u_xlat0.xy / u_xlat0.zz;
    u_xlat0.xy = u_xlat0.xy * vec2(0.5, 0.5) + vec2(0.5, 0.5);
#ifdef UNITY_ADRENO_ES3
    u_xlat0.xy = min(max(u_xlat0.xy, 0.0), 1.0);
#else
    u_xlat0.xy = clamp(u_xlat0.xy, 0.0, 1.0);
#endif

    u_xlat26 = textureLod(_HizDepthTex, u_xlat0.xy, 2.0).x;

#ifdef UNITY_ADRENO_ES3
    u_xlatb39 = !!(u_xlat26!=1.0);
#else
    u_xlatb39 = u_xlat26!=1.0;
#endif
#ifdef UNITY_ADRENO_ES3
    u_xlatb26 = !!(0.99000001<u_xlat26);
#else
    u_xlatb26 = 0.99000001<u_xlat26;
#endif
    u_xlati0.z = int(uint((uint(u_xlatb26) * 0xffffffffu) & (uint(u_xlatb39) * 0xffffffffu)));
    u_xlatb1.xy = lessThan(vec4(0.0, 0.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlati0.w = int(uint((uint(u_xlatb1.y) * 0xffffffffu) & (uint(u_xlatb1.x) * 0xffffffffu)));
    u_xlati0.xy = ivec2(uvec2(lessThan(u_xlat0.xyxx, vec4(1.0, 1.0, 0.0, 0.0)).xy) * 0xFFFFFFFFu);
    u_xlati0.xz = ivec2(uvec2(uint(u_xlati0.y) & uint(u_xlati0.x), uint(u_xlati0.w) & uint(u_xlati0.z)));
    u_xlati0.x = int(uint(uint(u_xlati0.x) & uint(u_xlati0.z)));
    if(u_xlati0.x != 0) {
        SV_Target0 = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }



    //camera 2 world  =  Ray
    u_xlat0.xyz = vs_TEXCOORD1.xyz + (-vec3(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y, _WorldSpaceCameraPos.z));
    u_xlat39 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat1.x = sqrt(u_xlat39);
    u_xlat39 = float(1.0) / float(u_xlat1.x);


    u_xlat2.xyz = vs_TEXCOORD0.xyz + (-_startPosOS.xyz);


    //osViewDir
    u_xlat2.xyz = vec3(u_xlat39) * u_xlat2.xyz;

    //viewDir
    u_xlat0.xyz = vec3(u_xlat39) * u_xlat0.xyz;



    ddx(worldPos.xz)
    u_xlat27.xy = dFdx(vs_TEXCOORD1.xz);
    u_xlat27.x = dot(u_xlat27.xy, u_xlat27.xy);

    ddy(worldPos.xz)
    u_xlat3.xy = dFdy(vs_TEXCOORD1.xz);
    u_xlat27.y = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlat27.xy = sqrt(u_xlat27.xy);


    //_PerlinOffsetAndScale.z
    u_xlat40 = u_xlat27.y * _PerlinOffsetAndScale.z;
    u_xlat41 = u_xlat40 * invscale.x;
    u_xlat41 = u_xlat41 * 64.0;
    u_xlat41 = log2(u_xlat41);
    //perlinForSkyCloudMipmap
    u_xlat41 = max(u_xlat41, 0.0);

    //_PerlinOffsetAndScale.w
    u_xlat40 = u_xlat40 * _PerlinOffsetAndScale.w;
    u_xlat40 = u_xlat40 * invscale.x;
    u_xlat40 = u_xlat40 * 128.0;
    u_xlat27.y = log2(u_xlat40);

    u_xlat27.x = u_xlat27.x * _CloudNoiseParam.y;
    u_xlat27.x = u_xlat27.x * invscale.x;
    u_xlat27.x = u_xlat27.x * 64.0;
    u_xlat27.x = log2(u_xlat27.x);
    //u_xlat27.x  worleyNoiseTexMipmap
    //u_xlat27.y  perlinToDilateWorleyMipmap
    //u_xlat41    perlinForSkyCloudMipmap
    u_xlat27.xy = max(u_xlat27.xy, vec2(0.0, 0.0));



    u_xlat3.x = scale.y / u_xlat0.y;



    //dot(fake normal, lightDir)
    u_xlat16 = dot(u_xlat2.xyz, _sunDir.xyz);
    u_xlat29 = (-u_xlat16);

#ifdef UNITY_ADRENO_ES3
    u_xlat29 = min(max(u_xlat29, 0.0), 1.0);
#else
    u_xlat29 = clamp(u_xlat29, 0.0, 1.0);
#endif

    u_xlat29 = log2(u_xlat29);
    u_xlat29 = u_xlat29 * _FakeCloudTransmittanceParam.y;
    u_xlat29 = exp2(u_xlat29);
    u_xlat29 = (-u_xlat29) * _FakeCloudTransmittanceParam.x + 1.0;

    //transmittanceWeight
    u_xlat29 = u_xlat29 * _subRayParam.y;

    u_xlat42 = _phaseParam.z * u_xlat16 + _phaseParam.y;
    u_xlat42 = log2(u_xlat42);
    u_xlat42 = u_xlat42 * 1.5;
    u_xlat42 = exp2(u_xlat42);
    u_xlat42 = _phaseParam.x / u_xlat42;


    u_xlat16 = _backPhaseParam.z * u_xlat16 + _backPhaseParam.y;
    u_xlat16 = log2(u_xlat16);
    u_xlat16 = u_xlat16 * 1.5;
    u_xlat16 = exp2(u_xlat16);
    u_xlat16 = _backPhaseParam.x / u_xlat16;

    //phaseValueTotal
    u_xlat16 = u_xlat16 + u_xlat42;


    //lightColor
    u_xlat4.xyz = vec3(u_xlat16) * _sunColor.xyz;


    u_xlat1.y = u_xlat1.x + u_xlat3.x;
    //osViewDirInCloud
    u_xlat3.xyw = u_xlat2.xyz * invscale.xyz;

    u_xlat5.xy = u_xlat1.xy * _sampleParam.xx + _sampleParam.yy;
    u_xlat5.xy = log2(u_xlat5.xy);
    u_xlat5.xy = u_xlat5.xy * vec2(0.693147182, 0.693147182);
    u_xlat5.xy = u_xlat5.xy / _sampleParam.xx;



    u_xlat18.xy = ceil(u_xlat5.xy);
    u_xlati14 = int(u_xlat18.x);
    
    u_xlat43 = u_xlat18.x * _sampleParam.x;
    u_xlat43 = u_xlat43 * 1.44269502;
    u_xlat43 = exp2(u_xlat43);

    u_xlat5.x = (-u_xlat5.x) + u_xlat18.x;
    u_xlat2.xyz = u_xlat2.xyz * u_xlat5.xxx;
    u_xlat2.xyz = u_xlat2.xyz * vec3(u_xlat43) + vs_TEXCOORD0.xyz;


    u_xlat5.x = min(u_xlat18.y, _sampleParam.w);
    u_xlati5 = int(u_xlat5.x);
    u_xlati14 = (-u_xlati14) + u_xlati5;

    u_xlat14.x = float(u_xlati14);
    u_xlat14.x = min(u_xlat14.x, _sampleParam.z);
    u_xlati14 = int(u_xlat14.x);

    u_xlat5.x = _sampleParam.x * 1.44269502;
    u_xlat5.x = exp2(u_xlat5.x);
    u_xlat2.xyz = u_xlat2.xyz * invscale.xyz;
#ifdef UNITY_ADRENO_ES3
    u_xlat2.xyz = min(max(u_xlat2.xyz, 0.0), 1.0);
#else
    u_xlat2.xyz = clamp(u_xlat2.xyz, 0.0, 1.0);
#endif

    u_xlat18.x = float(0.0);
    u_xlat18.y = float(0.0);
    u_xlat18.z = float(0.0);

    u_xlat6.xyz = u_xlat2.xyz;

    u_xlat45 = u_xlat43;

    u_xlat7 = float(1.0);
    u_xlati20 = int(0);
    while(true){
#ifdef UNITY_ADRENO_ES3
        u_xlatb33 = !!(u_xlati20<u_xlati14);
#else
        u_xlatb33 = u_xlati20<u_xlati14;
#endif
#ifdef UNITY_ADRENO_ES3
        u_xlatb46 = !!(0.00100000005<u_xlat7);
#else
        u_xlatb46 = 0.00100000005<u_xlat7;
#endif
        u_xlatb33 = u_xlatb46 && u_xlatb33;
        if(!u_xlatb33){break;}

        
        u_xlati20 = u_xlati20 + 1;



        u_xlat33.xy = u_xlat6.xz * _PerlinOffsetAndScale.zz + _PerlinOffsetAndScale.xy;
        u_xlat8.xy = u_xlat33.xy * _PerlinOffsetAndScale.ww;
        u_xlat16_33 = textureLod(_perlinForSkyCloudTex, u_xlat33.xy, u_xlat41).x;
        u_xlat16_46 = textureLod(_perlinToDilateWorley, u_xlat8.xy, u_xlat27.y).x;

        u_xlat33.x = u_xlat16_46 * _Worley2Param.x + u_xlat16_33;
        u_xlat33.x = u_xlat33.x * _Worley2Param.y;
        u_xlat33.x = log2(u_xlat33.x);
        u_xlat33.x = u_xlat33.x * _CloudNoiseParam.x;
        u_xlat33.x = exp2(u_xlat33.x);

        u_xlat8.xy = u_xlat6.xz * _CloudNoiseParam.yy;
        u_xlat8.z = u_xlat6.y * _WorleyOffsetAndScale.w;
        u_xlat8.xyz = u_xlat8.xyz + _WorleyOffsetAndScale.xzy;
        u_xlat16_46 = textureLod(_worleyNoiseTex, u_xlat8.xyz, u_xlat27.x).x;
        u_xlat46 = u_xlat16_46;
#ifdef UNITY_ADRENO_ES3
        u_xlat46 = min(max(u_xlat46, 0.0), 1.0);
#else
        u_xlat46 = clamp(u_xlat46, 0.0, 1.0);
#endif




        u_xlat33.x = (-u_xlat46) * _CloudNoiseParam.z + u_xlat33.x;
        u_xlat8.x = (-u_xlat46) * _CloudNoiseParam.z + 1.0;
        u_xlat8.x = max(u_xlat8.x, 9.99999997e-07);
        u_xlat33.x = u_xlat33.x / u_xlat8.x;
#ifdef UNITY_ADRENO_ES3
        u_xlat33.x = min(max(u_xlat33.x, 0.0), 1.0);
#else
        u_xlat33.x = clamp(u_xlat33.x, 0.0, 1.0);
#endif


        u_xlat21 = (-u_xlat6.y) + u_xlat33.x;
        u_xlat21 = u_xlat21 * _Worley2Param.z;
        u_xlat34 = u_xlat6.y * _Worley2Param.w;
        u_xlat34 = min(u_xlat34, 1.0);
        u_xlat34 = (-u_xlat34) + 1.0;
        u_xlat33.x = u_xlat33.x + (-u_xlat34);
        u_xlat33.x = max(u_xlat33.x, 0.0);
        u_xlat33.x = u_xlat33.x * u_xlat21;
        u_xlat33.x = max(u_xlat33.x, 0.0);
#ifdef UNITY_ADRENO_ES3
        u_xlatb21 = !!(9.99999997e-07<u_xlat33.x);
#else
        u_xlatb21 = 9.99999997e-07<u_xlat33.x;
#endif
        if(u_xlatb21){
            u_xlat33.x = (-u_xlat33.x) * _extraParam1.x;
            u_xlat33.x = u_xlat45 * u_xlat33.x;

            u_xlat33.x = u_xlat33.x * 1.44269502;
            u_xlat33.x = exp2(u_xlat33.x);
            u_xlat21 = u_xlat6.y * 0.0149999997;


            u_xlat9.xyz = u_xlat6.xyz + (-_subRayStep.xyz);
            u_xlat10.xyz = u_xlat9.xyz;
            u_xlat34 = float(1.0);
            u_xlati47 = int(1);
            while(true){
                u_xlat48 = float(u_xlati47);
#ifdef UNITY_ADRENO_ES3
                u_xlatb48 = !!(_subRayParam.x<u_xlat48);
#else
                u_xlatb48 = _subRayParam.x<u_xlat48;
#endif
                if(u_xlatb48){break;}


                u_xlat48 = u_xlat10.y;
#ifdef UNITY_ADRENO_ES3
                u_xlat48 = min(max(u_xlat48, 0.0), 1.0);
#else
                u_xlat48 = clamp(u_xlat48, 0.0, 1.0);
#endif


                u_xlat11.xy = u_xlat10.xz * _PerlinOffsetAndScale.zz + _PerlinOffsetAndScale.xy;
                u_xlat37.xy = u_xlat11.xy * _PerlinOffsetAndScale.ww;
                u_xlat16_49 = textureLod(_perlinForSkyCloudTex, u_xlat11.xy, u_xlat41).x;
                u_xlat16_11 = textureLod(_perlinToDilateWorley, u_xlat37.xy, u_xlat27.y).x;


                u_xlat49 = u_xlat16_11 * _Worley2Param.x + u_xlat16_49;
                u_xlat49 = u_xlat49 * _Worley2Param.y;
                u_xlat49 = log2(u_xlat49);
                u_xlat49 = u_xlat49 * _CloudNoiseParam.x;
                u_xlat49 = exp2(u_xlat49);

                u_xlat49 = (-u_xlat46) * _CloudNoiseParam.z + u_xlat49;
                u_xlat49 = u_xlat49 / u_xlat8.x;
#ifdef UNITY_ADRENO_ES3
                u_xlat49 = min(max(u_xlat49, 0.0), 1.0);
#else
                u_xlat49 = clamp(u_xlat49, 0.0, 1.0);
#endif



                u_xlat11.x = (-u_xlat48) + u_xlat49;
                u_xlat11.x = u_xlat11.x * _Worley2Param.z;
                u_xlat48 = u_xlat48 * _Worley2Param.w;
                u_xlat48 = min(u_xlat48, 1.0);


                u_xlat48 = (-u_xlat48) + 1.0;

                u_xlat48 = (-u_xlat48) + u_xlat49;
                u_xlat48 = max(u_xlat48, 0.0);

                u_xlat48 = u_xlat48 * u_xlat11.x;
                u_xlat48 = max(u_xlat48, 0.0);



                u_xlat48 = u_xlat29 * (-u_xlat48);
                u_xlat48 = u_xlat48 * 1.44269502;
                u_xlat48 = exp2(u_xlat48);


                u_xlat34 = u_xlat34 * u_xlat48;
                u_xlat10.xyz = u_xlat10.xyz + (-_subRayStep.xyz);
                u_xlati47 = u_xlati47 + 1;
            }
            u_xlat8.xyw = vec3(u_xlat21) * _envColor.xyz;
            u_xlat8.xyw = vec3(u_xlat34) * u_xlat4.xyz + u_xlat8.xyw;

            u_xlat46 = (-u_xlat33.x) + 1.0;
            u_xlat8.xyw = vec3(u_xlat46) * u_xlat8.xyw;
            u_xlat18.xyz = u_xlat8.xyw * vec3(u_xlat7) + u_xlat18.xyz;
            u_xlat7 = u_xlat33.x * u_xlat7;
        }
        u_xlat45 = u_xlat5.x * u_xlat45;
        u_xlat6.xyz = u_xlat3.xyw * vec3(u_xlat45) + u_xlat6.xyz;
    }
    u_xlat14.xyz = max(u_xlat18.xyz, vec3(0.0, 0.0, 0.0));
    u_xlat2.w = (-u_xlat7) + 1.0;
    u_xlat3.x = dot(u_xlat14.xyz, vec3(0.212599993, 0.715200007, 0.0722000003));
    u_xlat3.x = min(u_xlat3.x, 1.0);
    u_xlat3.x = (-u_xlat3.x) + 1.0;
    u_xlat3.x = u_xlat2.w * u_xlat3.x;


    u_xlat2.xyz = u_xlat3.xxx * _darkColor.xyz + u_xlat14.xyz;
    u_xlat1.x = u_xlat1.x * _FakeCloudTransmittanceParam.z;
    u_xlat14.xy = u_xlat0.xz * u_xlat1.xx;
    u_xlat1.x = u_xlat0.y * u_xlat1.x + _WorldSpaceCameraPos.xxyz.z;

    u_xlat16_12.x = (-u_xlat0.y) * u_xlat0.y + 1.0;
    u_xlat16_12.x = inversesqrt(u_xlat16_12.x);
    u_xlat0.w = (-u_xlat0.x);
    u_xlat16_25 = dot(u_xlat0.wz, g_AtmosphereLightDirection.xy);
    u_xlat0.x = u_xlat16_12.x * u_xlat16_25;
    u_xlat0.x = max(u_xlat0.x, -1.0);
    u_xlat0.x = min(u_xlat0.x, 1.0);

    u_xlat13 = abs(u_xlat0.x) * abs(u_xlat0.x);
    u_xlat26 = abs(u_xlat0.x) * u_xlat13;
    u_xlat39 = abs(u_xlat0.x) * -0.212114394 + 1.57072878;
    u_xlat13 = u_xlat13 * 0.0742610022 + u_xlat39;
    u_xlat13 = u_xlat26 * -0.0187292993 + u_xlat13;
    u_xlat26 = -abs(u_xlat0.x) + 1.0;
    u_xlat26 = sqrt(u_xlat26);
    u_xlat39 = u_xlat13 * u_xlat26;
#ifdef UNITY_ADRENO_ES3
    u_xlatb0 = !!(u_xlat0.x>=0.0);
#else
    u_xlatb0 = u_xlat0.x>=0.0;
#endif
    u_xlat13 = (-u_xlat26) * u_xlat13 + 3.14159274;
    u_xlat0.x = (u_xlatb0) ? u_xlat39 : u_xlat13;
    u_xlat0.x = u_xlat0.x * 0.318309873;
    u_xlat0.x = sqrt(u_xlat0.x);
    
    u_xlat39 = dot(u_xlat14.xy, u_xlat14.xy);
    u_xlat14.y = sqrt(u_xlat39);
    u_xlat14.x = u_xlat1.x + g_CameraAerialPerspectiveVolumeParam.x;
    u_xlat16_12.xy = u_xlat14.xy * g_CameraAerialPerspectiveVolumeParam.zy;
#ifdef UNITY_ADRENO_ES3
    u_xlat16_12.xy = min(max(u_xlat16_12.xy, 0.0), 1.0);
#else
    u_xlat16_12.xy = clamp(u_xlat16_12.xy, 0.0, 1.0);
#endif
    u_xlat16_13.xy = sqrt(u_xlat16_12.xy);
    u_xlat0.yz = u_xlat16_13.xy;
    u_xlat16_0 = textureLod(AtmosphereCameraScatteringVolume, u_xlat0.xyz, 0.0);
    u_xlat16_12.x = (-u_xlat16_0.w) + 1.0;
    u_xlat16_1 = u_xlat2 * u_xlat16_12.xxxx;
    u_xlat16_0 = u_xlat16_0 * u_xlat2.wwww + u_xlat16_1;
    SV_Target0 = u_xlat16_0;
    return;
}