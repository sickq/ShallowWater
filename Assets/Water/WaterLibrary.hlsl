#ifndef WATER_LIBRARY
#define WATER_LIBRARY

#include "UnityCG.cginc"

sampler2D _WaterNormal;
sampler2D _WaterFoam;
sampler2D _WaterFallEffect;

sampler2D _OpaqueDepthTexture;
sampler2D _CameraDepthTexture;
sampler2D _CameraOpaqueTexture;
sampler2D _CameraGrabTexture;

float4 _DeepColor;
float4 _ShalowColor;
float _MinWaterDepth;
float gEdgeDepth;
float3 _UnderWaterColor;

float gFinalAlpha;
float _WaterSmoothness;
float _WaterSpecularClose;
    
float _ShalowFalloffMultiply;
float _ShalowFalloffPower;
float _CleanFalloffMultiply;
float _CleanFalloffPower;
float _BackfaceAlpha;
    
float _BigCascadeAngle;
float _BigCascadeAngleFalloff;

float _SmallCascadeAngle;
float _SmallCascadeAngleFalloff;

float4 _TilingSpeedFoam;

float _WorldTiling;

float _IceIntensity;
float _GlobalTiling;

float4 _SlowWaterTiling;
float4 _SlowWaterSpeed;
float _NormalScale;
float _MicroWaveNormalScale;
float _MacroWaveNormalScale;
float4 _MicroWaveTiling;

float4 _WaterFallEffectTiling;
float4 _WaterFallEffectTiling2;
float4 _WaterFallColor;
float _WaterFallAlpha;
float _WaterFallEffectAlpha;

float _FoamIntensity;
float _ShadowDistort;
float _Distortion;

float _EnvIntensity;
float4 _AmbientColor;
float4 _EnvColor;


float calculateCascadeValue(float normalY, float cascadeAngle, float cascadeAngleFalloff)
{
    float tempCascadeAngle = cascadeAngle / 45.0;
    float tempCascadeAngle1 = clamp(normalY - (1 - cascadeAngle / 45.0), 0, 2);

    tempCascadeAngle1 = saturate(1 / tempCascadeAngle * tempCascadeAngle1);
    tempCascadeAngle1 = pow(1 - tempCascadeAngle1, cascadeAngleFalloff);
    tempCascadeAngle1 = min(tempCascadeAngle1, 1);

    return tempCascadeAngle1;
}

// assume compositing in tangent space
half3 BlendNormal(half3 n1, half3 n2)
{
    return normalize(half3(n1.xy * n2.z + n2.xy * n1.z, n1.z * n2.z));
}

void CalculateNormal(float2 uv, float bigCascade, out float3 outSlowWaveNormal, out float3 outFinalNormal)
{
    //TODO 冰面混合暂时不添加，冰面强度为0
    float iceIntensity = 0;
    float tilingParam = 1 / _GlobalTiling;
    float3 slowWaterSpeedParam = _Time.yyy * 0.15f + float3(1.0f, 1.5f, 0.5f);
    float tempSpeed = min(abs(slowWaterSpeedParam.z + slowWaterSpeedParam.z), 1.0f);

    float2 slowWaterUVOffset = uv * float2(_SlowWaterTiling.x, _SlowWaterTiling.y) * tilingParam;
    float4 slowWaterUV = _SlowWaterSpeed.xyxy * slowWaterSpeedParam.xxyy + slowWaterUVOffset.xyxy;

    slowWaterUVOffset.xy = _Time.yy * _SlowWaterSpeed.zw + slowWaterUVOffset.xy;
    float deIceNormalScale = (1 - iceIntensity) * _NormalScale;
    float2 deIceNormalMacroScale = (1 - iceIntensity) * float2(_MicroWaveNormalScale, _MacroWaveNormalScale);
    float3 slowWaveNormal = UnpackNormalWithScale(tex2D(_WaterNormal, slowWaterUV.xy), deIceNormalScale);
    float3 slowWaveNormal2 = UnpackNormalWithScale(tex2D(_WaterNormal, slowWaterUV.zw), deIceNormalScale);
    
    outSlowWaveNormal = lerp(slowWaveNormal, slowWaveNormal2, tempSpeed);

    float2 microUV = slowWaterUVOffset.xy * _MicroWaveTiling.xy;
    float3 microNormal = UnpackNormalWithScale(tex2D(_WaterNormal, microUV), deIceNormalMacroScale.x);

    float2 macroUV = slowWaveNormal.xy * 0.05 + slowWaterUVOffset.xy;
    float3 macroNormal = UnpackNormalWithScale(tex2D(_WaterNormal, macroUV), deIceNormalMacroScale.y);

    float3 croNormal = BlendNormal(microNormal, macroNormal);
    float3 finalNormal = BlendNormal(croNormal, slowWaveNormal);
    outFinalNormal = bigCascade * (finalNormal + float3(0, 0, 1)) + finalNormal;
}

float CalculateFoamIntensity(float2 uv, float smallCascade, float3 normal)
{
    float2 foamSpeed = _Time.yy * _TilingSpeedFoam.zw;
    float foamInstensity = sqrt(smallCascade) * _FoamIntensity;
    float3 realFoamSpeed = foamSpeed.xyy * float3(4.0f, 4.0f, 0.1736431f);
    float2 foamUVOffset = uv.xy * _TilingSpeedFoam.xy + realFoamSpeed.xy;
    foamUVOffset = foamUVOffset * 0.00390625f + normal.xy;
    float waterFoam = tex2D(_WaterFoam, foamUVOffset).r;
    foamUVOffset.x = foamSpeed.x * 0.984808624 - realFoamSpeed.z;
    foamUVOffset.y = dot(foamSpeed.xy, float2(0.173643112, 0.984808624));
    foamUVOffset = uv.xy * _TilingSpeedFoam.xy + foamUVOffset.xy;
    foamUVOffset = foamUVOffset * float2(0.0078125, 0.0078125) + float2(0.5, 0.5);
    float waterFoam1 = tex2D(_WaterFoam, foamUVOffset).r;
    float finalWaterFoam = 0.4 * waterFoam1 + 0.6 * waterFoam;
    foamInstensity = foamInstensity * finalWaterFoam;

    return foamInstensity;
}

float3 CalculateUnderWater(float3 normal, float pixelEyeDepth, float4 projPos, float mask)
{
    float2 distortionNormalXY = normal.xy * _Distortion;

    float2 sceneUV = mask * distortionNormalXY + projPos.xy / projPos.w;
    // float depth = tex2D(_OpaqueDepthTexture, sceneUV).r;
    float depth = tex2D(_CameraDepthTexture, sceneUV).r;
    float texEyeDepth = LinearEyeDepth(depth);

    float depthWeight = texEyeDepth > pixelEyeDepth ? 1.0 : 0.0;
    float2 opaqueColorUV = depthWeight * distortionNormalXY + projPos.xy / projPos.w;

    // float3 opaqueColor = tex2D(_CameraOpaqueTexture, opaqueColorUV).rgb;
    float3 opaqueColor = tex2D(_CameraGrabTexture, opaqueColorUV).rgb;

    float3 underWaterColor = opaqueColor * _UnderWaterColor.rgb;
    return underWaterColor;
}

float CalculateDepthDelta(float4 projPos, out float baseEyeTexDepth)
{
    // float baseTexDepth = tex2D(_OpaqueDepthTexture, i.projPos.xy / i.projPos.w).r;
    float baseTexDepth = tex2D(_CameraDepthTexture, projPos.xy / projPos.w).r;
	baseEyeTexDepth = LinearEyeDepth(baseTexDepth);

    float depthDelta = baseEyeTexDepth - projPos.z;
    depthDelta = max(abs(depthDelta), _MinWaterDepth);
    return depthDelta;
}

float3 CalculateScenePosition(float baseEyeTexDepth, float eyeDepth, float3 posWorld)
{
	float3 tempValue = posWorld.xyz - _WorldSpaceCameraPos.xyz;
	tempValue = tempValue / eyeDepth;
	float m_depth = baseEyeTexDepth;
	tempValue *= m_depth;
	tempValue += _WorldSpaceCameraPos.xyz;
	return tempValue;
}

float CalculateShalowFalloff(float depthDelta)
{
    float shalowFalloff = depthDelta * _ShalowFalloffMultiply;
    shalowFalloff = pow(shalowFalloff, -_ShalowFalloffPower);
    shalowFalloff = min(shalowFalloff, 1);
    return shalowFalloff;
}

float CalculateCleanFalloff(float depthDelta, float facing, float mask)
{
    float cleanFalloff = depthDelta * _CleanFalloffMultiply;
    cleanFalloff = pow(cleanFalloff, _CleanFalloffPower);
    cleanFalloff = min(cleanFalloff, 1);
    float backFaceCleanFalloff = cleanFalloff * _BackfaceAlpha;
    cleanFalloff = facing >= 0 ? cleanFalloff : backFaceCleanFalloff;
    cleanFalloff = mask * cleanFalloff;
    return cleanFalloff;
}

half3 Max3(half3 xyz)
{
    return max(max(xyz.x, xyz.y), xyz.z);
}

float3 MainLightColor()
{
    float maxLightTerm = Max3(_LightColor0.rgb);
    bool maxLightTermGreater1 = maxLightTerm > 1.0;
    float3 lightColor = maxLightTermGreater1 ? _LightColor0.rgb / maxLightTerm : _LightColor0.rgb;
    return lightColor;
}

float4 CalculateWaterFallEffect(float2 uv)
{
    float waterFallTime = _Time.y * 0.1f;
    float waterFallEffectTiling1 = waterFallTime * _WaterFallEffectTiling.w;
    float waterFallEffectTiling2 = waterFallTime * _WaterFallEffectTiling2.w;
    
    float2 waterFallUV = 0;
    waterFallUV.y = uv.x * _WaterFallEffectTiling.y;
    waterFallUV.x = uv.y * _WaterFallEffectTiling.x + _WaterFallEffectTiling.z;
    waterFallUV = waterFallUV + float2(0, waterFallEffectTiling1);
    float4 waterFallEffect1 = tex2D(_WaterFallEffect, waterFallUV.xy);

    waterFallUV.y = uv.x * _WaterFallEffectTiling2.y;
    waterFallUV.x = uv.y * _WaterFallEffectTiling2.x + _WaterFallEffectTiling2.z;
    waterFallUV = waterFallUV + float2(0, waterFallEffectTiling2);
    float4 waterFallEffect2 = tex2D(_WaterFallEffect, waterFallUV.xy);

    float4 waterFallEffect = waterFallEffect1.xyzw + waterFallEffect2.xyzw;
    waterFallEffect.w = clamp(waterFallEffect.w, 0, 1);
    return waterFallEffect;
}

float3 CalculateWaterFallPosWord(float4 waterFallEffect, float foamIntensity, float bigCascade, float3 posWorld)
{
    float3 waterFallPosWorld = 0;
    waterFallPosWorld.x = dot(waterFallEffect.ww, waterFallEffect.xx);
    waterFallPosWorld.y = waterFallEffect.y + waterFallEffect.y;
    waterFallPosWorld.xy = float2(waterFallPosWorld.x, waterFallPosWorld.y) - 1;
    waterFallPosWorld.xy = waterFallPosWorld.xy * float2(_ShadowDistort, _ShadowDistort);
    float tempC = dot(waterFallPosWorld.xy, waterFallPosWorld.xy);
    waterFallPosWorld.z = sqrt(1 - min(tempC, 1));
    waterFallPosWorld = foamIntensity * _ShadowDistort + waterFallPosWorld;
    waterFallPosWorld = bigCascade * waterFallPosWorld + posWorld.xyz;
    return waterFallPosWorld;
}

UNITY_DECLARE_TEX2D(_CausticsTexture);
float _Caustics;
float _CausticsFocalDepth;
float _CausticsDepthOfField;
float _CausticsTextureScale;
float _CausticsStrength;
float _CausticsTextureAverage;
float _CausticsEdgeSmooth;

void ApplyCaustics(float eyeDepthTex, float3 scenePos, float3 posWorld, float3 lightDir, inout float3 waterColor)
{
	if(_Caustics > 0.5)
	{
	    float sceneDepth = posWorld.y - scenePos.y;
	
	    // Compute mip index manually, with bias based on sea floor depth. We compute it manually because if it is computed automatically it produces ugly patches
	    // where samples are stretched/dilated. The bias is to give a focusing effect to caustics - they are sharpest at a particular depth. This doesn't work amazingly
	    // well and could be replaced.
	    float mipLod = log2(eyeDepthTex) + abs(sceneDepth - _CausticsFocalDepth) / _CausticsDepthOfField;

	    // project along light dir, but multiply by a fudge factor reduce the angle bit - compensates for fact that in real life
	    // caustics come from many directions and don't exhibit such a strong directonality
	    // Removing the fudge factor (4.0) will cause the caustics to move around more with the waves. But this will also
	    // result in stretched/dilated caustics in certain areas. This is especially noticeable on angled surfaces.
	    float2 lightProjection = lightDir.xz * sceneDepth / (4.0 * lightDir.y);
	    float _CrestTime = _Time.y;
	
	
	    float3 cuv1 = 0.0; float3 cuv2 = 0.0;
	    {
	        float2 surfacePosXZ = scenePos.xz;
	        float surfacePosScale = 1.37;

	        surfacePosXZ += lightProjection;

	        cuv1 = float3(surfacePosXZ / _CausticsTextureScale + float2(0.044 * _CrestTime + 17.16, -0.169 * _CrestTime), mipLod);
	        cuv2 = float3(surfacePosScale * surfacePosXZ / _CausticsTextureScale + float2(0.248 * _CrestTime, 0.117 * _CrestTime), mipLod);
	    }

	    float3 causticsColor =  _CausticsStrength *
        (
            0.5 * UNITY_SAMPLE_TEX2D_LOD(_CausticsTexture, cuv1.xy, cuv1.z).xyz +
            0.5 * UNITY_SAMPLE_TEX2D_LOD(_CausticsTexture, cuv2.xy, cuv2.z).xyz -
            _CausticsTextureAverage
        );


	    half edgeSmooth = saturate((10.1000004 - _CausticsEdgeSmooth) * sceneDepth);
	    waterColor *= causticsColor * edgeSmooth + 1.0;
	}
}

#endif

