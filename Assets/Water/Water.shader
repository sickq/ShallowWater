Shader "Unlit/Water"
{
    Properties
    {
        [Header(Water Color)]
        _ShalowColor("Shalow Color", Color) = (0.01445, 0.05117, 0.06956, 1.00)
        _ShalowFalloffMultiply("Shalow Falloff Multiply", Range(0, 5)) = 0.5
        _ShalowFalloffPower("Shalow Falloff Power", Range(0, 5)) = 0.5
        _DeepColor("Deep Color", Color) = (0.02624, 0.06458, 0.06956, 1.00)
        _UnderWaterColor("Under Water Color", Color) = (0.17431, 0.20584, 0.25193, 1.00)
        _Distortion("Distortion", Range(0, 1)) = 0.1

        [Header(Global Alpha)]
        gFinalAlpha("gFinalAlpha", Range(0, 1)) = 1
        
        [Header(Depth)]
        _MinWaterDepth("Min Water Depth", Range(0, 50)) = 0.0
        gEdgeDepth("Edge Depth", Range(0, 50)) = 30.0
        
        [Header(Near Clean FallOff)] 
        _CleanFalloffMultiply("Clean Falloff Multiply", Range(0, 5)) = 2.91
        _CleanFalloffPower("Clean Falloff Power", Range(0, 5)) = 3.29
        _BackfaceAlpha("Backface Alpha", Range(0, 1)) = 0.85
        
        _WaterSpecularClose("Water Specular Close", Range(0, 1)) = 0.287
        _WaterSmoothness("Water Smoothness", Range(0, 1)) = 1.0
        
        [Header(Normal)]
        _WaterNormal("Water Normal", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0, 2)) = 0.1
        _MicroWaveNormalScale("Micro Wave Normal Scale", Range(0, 2)) = 0.1
        _MacroWaveNormalScale("Macro Wave Normal Scale", Range(0, 2)) = 0.1
        _MicroWaveTiling("Micro Wave Tiling", Vector) = (3, 3, 1, 1)
        [Toggle] _WorldTiling("World Tiling", Range(0, 1)) = 1
        _GlobalTiling("Global Tiling", Range(0.001, 5)) = 3

        _SlowWaterSpeed("Slow Water Speed", Vector) = (-0.4, 0.0, -0.02, 0.00)
        _SlowWaterTiling("Slow Water Tiling(XY)", Vector) = (10.0, 10.0, 1, 1)
        
        _BigCascadeAngle("Big Cascade Angle", Range(0, 360)) = 45
        _BigCascadeAngleFalloff("Big Cascade Angle Falloff", Range(0, 10)) = 1
        
        _SmallCascadeAngle("Small Cascade Angle", Range(0, 360)) = 1
        _SmallCascadeAngleFalloff("Small Cascade Angle Falloff", Range(0, 10)) = 1
        
        [Header(WaterFallEffect)]
        _WaterFallEffect("Water Fall Effect", 2D) = "black" {}
        _WaterFallEffectTiling("Water Fall Effect Tiling", Vector) = (1, 1, 0, 0)
        _WaterFallEffectTiling2("Water Fall Effect Tiling2", Vector) = (1, 1, 0, 0)
        _WaterFallColor("Water Fall Color", Color) = (1, 1, 1, 1)
        _WaterFallAlpha("Water Fall Alpha", Range(0, 1)) = 1
        _WaterFallEffectAlpha("Water Fall Effect Alpha", Range(0, 1)) = 1
        
        [Header(Foam)]
        _WaterFoam("Water Foam", 2D) = "black" {}
        _TilingSpeedFoam("Tiling Speed Foam", Vector) = (100, 100, 1, 1)
        _FoamIntensity("Foam Intensity", Range(0, 1)) = 1.0
        _ShadowDistort("Shadow Distort", Range(0, 1)) = 0.3
        
        [Header(Environment)]
        _EnvIntensity("Env Intensity", Range(0, 1)) = 1.0
        _AmbientColor("Ambient Color", Color) = (0.53894, 0.64524, 0.64887, 1.00)
        _EnvColor("Env Color", Color) = (0.12794, 0.15877, 0.23585, 0.00)
    }
    
    CGINCLUDE

    #include "UnityCG.cginc"
    #include "SSR.cginc"
    #include "RayBRDF.cginc"
    #include "Assets/Shaders/Atmosphere.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float4 texcoord : TEXCOORD0;
        float4 color : COLOR;
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;
        float4 posWorld : TEXCOORD1;
        float3 viewDir : TEXCOORD2;
        float3 worldNormal : TEXCOORD3;
        float4 worldTangent : TEXCOORD4;
        float3 worldBiTangent : TEXCOORD5;
        float4 projPos : TEXCOORD6;
        float4 vertexColor : TEXCOORD7;
    };

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

    v2f vert(appdata v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord;
        o.posWorld = mul(unity_ObjectToWorld, v.vertex);
        o.viewDir.xzy = WorldSpaceViewDir(v.vertex);
        o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
        o.worldTangent.xyz = normalize(UnityObjectToWorldDir(v.tangent.xyz));
        o.worldTangent.w = v.tangent.w * unity_WorldTransformParams.w;
        o.worldBiTangent = normalize(cross(o.worldNormal, o.worldTangent.xyz) * v.tangent.w);
        o.projPos = ComputeScreenPos (o.pos);
        COMPUTE_EYEDEPTH(o.projPos.z);
        o.vertexColor = v.color;
        return o;
    }

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

    float CalculateDepthDelta(float4 projPos)
    {
        // float baseTexDepth = tex2D(_OpaqueDepthTexture, i.projPos.xy / i.projPos.w).r;
        float baseTexDepth = tex2D(_CameraDepthTexture, projPos.xy / projPos.w).r;
        float baseEyeTexDepth = LinearEyeDepth(baseTexDepth);

        float depthDelta = baseEyeTexDepth - projPos.z;
        depthDelta = max(abs(depthDelta), _MinWaterDepth);
        return depthDelta;
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

    
    half4 frag(v2f i, float facing : VFACE) : SV_Target
    {
        float3 V = normalize(UnityWorldSpaceViewDir(i.posWorld));
        float3 L = normalize(UnityWorldSpaceLightDir(i.posWorld));

        float3 normal = normalize(i.worldNormal.xyz);
        float3 tangent = i.worldTangent.xyz;
        float3 biTangent = i.worldBiTangent.xyz;

        float normalY = saturate(normal.y);

        float bigCascade = calculateCascadeValue(normalY, _BigCascadeAngle, _BigCascadeAngleFalloff);
        float smallCascade = calculateCascadeValue(normalY, _SmallCascadeAngle, _SmallCascadeAngleFalloff);

        bool branch = 0.5 < _WorldTiling;
        float2 uv = branch ? i.posWorld.xz : i.uv.xy;
        
        //TODO clip
        float mask = 1;

        float iceIntensity = saturate(_IceIntensity);

        float3 slowWaveNormal = 0;
        float3 finalNormal = 0;
        CalculateNormal(uv, bigCascade, slowWaveNormal, finalNormal);
        
        float foamIntensity = CalculateFoamIntensity(i.uv.xy, smallCascade, slowWaveNormal);

        float4 waterFallEffect = CalculateWaterFallEffect(i.uv.xy);

        float3 waterFallPosWorld = CalculateWaterFallPosWord(waterFallEffect, foamIntensity, bigCascade, i.posWorld.xyz);

        //TODO bakedWaterShadowMap 需要使用waterFallPosWorld
        float bakedWaterShadowMap = 1;
        
        //TODO DynamicWave 可以结合浅水方程来实现

        //TODO 当前值是通过顶点着色器插值差的结果，如果效果不好，可以改成Pixel计算
        float pixelEyeDepth = i.projPos.z;
        
        float3 normalWithWave = finalNormal;
        
        float3 underWaterColor = CalculateUnderWater(normalWithWave, pixelEyeDepth, i.projPos, mask);

        float depthDelta = CalculateDepthDelta(i.projPos);
        float shalowFalloff = CalculateShalowFalloff(depthDelta);
        float3 mainLightColor = MainLightColor();

        float3 waterBaseColor = lerp(_DeepColor.rgb, _ShalowColor.rgb, shalowFalloff);
        waterBaseColor = lerp(waterBaseColor, waterBaseColor * mainLightColor, _EnvIntensity);

        float depthFade = smoothstep(0, 1, saturate(depthDelta / gEdgeDepth));
        float underWaterLerp = saturate((1 - shalowFalloff) * depthFade);
        waterBaseColor = lerp(underWaterColor, waterBaseColor, underWaterLerp);

        //TODO bakedWaterShadowMap 预烘焙的水阴影
        float3 ambientColor = lerp(_AmbientColor.rgb, mainLightColor, bakedWaterShadowMap);
        ambientColor = lerp(float3(1, 1, 1), ambientColor, _EnvIntensity);
        ambientColor = saturate(ambientColor);

        waterBaseColor = lerp(waterBaseColor, ambientColor * waterFallEffect.xyz, bigCascade);

        float cleanFalloff = CalculateCleanFalloff(depthDelta, facing, mask);
        
        float3 waterSpecularCloseColor = lerp(_WaterSpecularClose, _EnvColor.rgb * _WaterSpecularClose * _AmbientColor.rgb, _EnvIntensity);
        
        float3 normalWorld = normalize(tangent * slowWaveNormal.x + biTangent * slowWaveNormal.y + normal * slowWaveNormal.z);
        float3 tempNormalWorld = bigCascade * float3(0, -1, 1) + float3(0, 1, 0);

        float viewYParam = 1 - min(abs(V.y + V.y), 1);
        tempNormalWorld = lerp(normalWorld, tempNormalWorld, viewYParam);

        float3 finalNormalWorld = normalize(tangent * normalWithWave.x + biTangent * normalWithWave.y + normal * normalWithWave.z);

        float3 reflectColor = 0;
        if(bigCascade < 1.0)
        {
            float3 reflectDir = reflect(-V, tempNormalWorld);

            reflectDir.y = max(reflectDir.y, 0.0);
            float3 norm_reflectDir = normalize(reflectDir);

            float NoV = dot(V, tempNormalWorld);
            float3 ssrUVZ = GetSSRUVZ(i.pos, i.posWorld, norm_reflectDir, NoV);
            // reflectColor = tex2D(_CameraOpaqueTexture, ssrUVZ.xy);
            reflectColor = tex2D(_CameraGrabTexture, ssrUVZ.xy);

            float3 uniformVertPos = norm_reflectDir.xyz;
            half4 skyCol = CalculateSky(uniformVertPos);

            float ssrWeight = saturate(ssrUVZ.y * 5.5 - 5);
            ssrWeight = dot(float2(ssrWeight, ssrWeight), float2(ssrWeight, ssrWeight));
            ssrWeight = max(1 - ssrWeight, 0);

            //TODO SSR Weight
            ssrWeight = ssrWeight * ssrUVZ.z;

            reflectColor = lerp(skyCol.rgb, reflectColor, ssrWeight);
        }

        reflectColor = lerp(reflectColor, waterBaseColor * 0.5, bigCascade);

        float3 bakedColorTemp = (bakedWaterShadowMap * waterBaseColor) * (1 - waterSpecularCloseColor);


        half3 indirectDiffuse = SHEvalLinearL0L1(float4(finalNormalWorld,1 ));

        BRDFData brdfData = (BRDFData)0;
        half alpha = 0;
        InitializeBRDFData_Specular(half3(0, 0, 0), half3(0, 0, 0), _WaterSmoothness, alpha, brdfData);

        half NdotL = saturate(dot(finalNormalWorld, L));
	    half3 radiance = mainLightColor * NdotL;

        half brdf = DirectBRDFSpecular(brdfData, finalNormalWorld, L, V);
        
        half3 specular = (brdf * waterSpecularCloseColor + bakedColorTemp) * radiance;

        specular = (1 - bigCascade) * specular;

        half3 resultColor = indirectDiffuse * bakedColorTemp + specular;
        
        float offsetNoV = saturate(dot(tempNormalWorld, V));
        float fresnelParam = pow(1 - offsetNoV, 4);
        resultColor = lerp(resultColor, reflectColor, fresnelParam);

        resultColor = underWaterColor * bigCascade + resultColor;
        
        foamIntensity = foamIntensity * (1 - bigCascade) * (1 - iceIntensity);

        resultColor = lerp(resultColor, foamIntensity * mainLightColor, foamIntensity);

        float3 waterFallColor1 = waterBaseColor * _WaterFallColor.xyz;
        float3 waterFallColor2 = bigCascade * waterFallColor1;

        resultColor = waterFallColor2 * cleanFalloff + resultColor;

        waterFallColor1 = lerp(cleanFalloff * waterFallColor1, resultColor, bakedWaterShadowMap);
        resultColor = lerp(resultColor, waterFallColor1, bigCascade);

        float waterFallEffectAlpha = bigCascade * _WaterFallEffectAlpha;
        waterFallEffectAlpha = lerp(cleanFalloff, waterFallEffect.w, waterFallEffectAlpha);
        waterFallEffectAlpha = waterFallEffectAlpha * cleanFalloff;
        waterFallEffectAlpha = lerp(waterFallEffectAlpha, waterFallEffectAlpha * _WaterFallAlpha, bigCascade);
        waterFallEffectAlpha = waterFallEffectAlpha * i.vertexColor.a * gFinalAlpha;

        float4 atmosphereColor = CalculateAtmosphere(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);

        resultColor.rgb = lerp(resultColor.rgb, atmosphereColor.rgb, atmosphereColor.a);
        
        return float4(resultColor, waterFallEffectAlpha);
    }

    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZWrite Off
        
        GrabPass{ "_CameraGrabTexture" }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
