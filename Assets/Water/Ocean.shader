Shader "Scene/Ocean"
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
        
        _WaterSpecularClose("Water Specular Close", Range(0, 1)) = 0.287
        _WaterSmoothness("Water Smoothness", Range(0, 1)) = 1.0
        
        [Header(Normal)]
        _WaterNormal("Water Normal", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0, 2)) = 0.1
        _MicroWaveNormalScale("Micro Wave Normal Scale", Range(0, 2)) = 0.1
        _MacroWaveNormalScale("Macro Wave Normal Scale", Range(0, 2)) = 0.1
        _MicroWaveTiling("Micro Wave Tiling", Vector) = (3, 3, 1, 1)

        _SlowWaterSpeed("Slow Water Speed", Vector) = (-0.4, 0.0, -0.02, 0.00)
        _SlowWaterTiling("Slow Water Tiling(XY)", Vector) = (10.0, 10.0, 1, 1)
        
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
    #include "WaterLibrary.hlsl"

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

    half4 frag(v2f i, float facing : VFACE) : SV_Target
    {
        float3 V = normalize(UnityWorldSpaceViewDir(i.posWorld));
        float3 L = normalize(UnityWorldSpaceLightDir(i.posWorld));

        float3 normal = normalize(i.worldNormal.xyz);
        float3 tangent = i.worldTangent.xyz;
        float3 biTangent = i.worldBiTangent.xyz;


        bool branch = 0.5 < _WorldTiling;
        float2 uv = branch ? i.posWorld.xz : i.uv.xy;
        
        //TODO clip
        float mask = 1;

        float iceIntensity = saturate(_IceIntensity);

        float3 slowWaveNormal = 0;
        float3 finalNormal = 0;
        CalculateNormal(uv, 0, slowWaveNormal, finalNormal);
        
        //TODO DynamicWave 可以结合浅水方程来实现

        //TODO 当前值是通过顶点着色器插值差的结果，如果效果不好，可以改成Pixel计算
        float pixelEyeDepth = i.projPos.z;
        float baseEyeTexDepth = pixelEyeDepth;
        
        float3 normalWithWave = finalNormal;
        
        float3 underWaterColor = CalculateUnderWater(normalWithWave, pixelEyeDepth, i.projPos, mask);

        float depthDelta = CalculateDepthDelta(i.projPos, baseEyeTexDepth);
        float shalowFalloff = CalculateShalowFalloff(depthDelta);
        float3 mainLightColor = MainLightColor();

        float3 waterBaseColor = lerp(_DeepColor.rgb, _ShalowColor.rgb, shalowFalloff);
        waterBaseColor = lerp(waterBaseColor, waterBaseColor * mainLightColor, _EnvIntensity);

        float depthFade = smoothstep(0, 1, saturate(depthDelta / gEdgeDepth));
        float underWaterLerp = saturate((1 - shalowFalloff) * depthFade);
        waterBaseColor = lerp(underWaterColor, waterBaseColor, underWaterLerp);

        float3 ambientColor = lerp(_AmbientColor.rgb, mainLightColor, 1);
        ambientColor = lerp(float3(1, 1, 1), ambientColor, _EnvIntensity);
        ambientColor = saturate(ambientColor);

        float3 waterSpecularCloseColor = lerp(_WaterSpecularClose, _EnvColor.rgb * _WaterSpecularClose * _AmbientColor.rgb, _EnvIntensity);
        
        float3 normalWorld = normalize(tangent * slowWaveNormal.x + biTangent * slowWaveNormal.y + normal * slowWaveNormal.z);
        float3 tempNormalWorld = float3(0, 1, 0);

        float viewYParam = 1 - min(abs(V.y + V.y), 1);
        tempNormalWorld = lerp(normalWorld, tempNormalWorld, viewYParam);

        float3 finalNormalWorld = normalize(tangent * normalWithWave.x + biTangent * normalWithWave.y + normal * normalWithWave.z);

        float3 reflectColor = 0;
        if(0 < 1.0)
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

        float3 bakedColorTemp = waterBaseColor * (1 - waterSpecularCloseColor);

        half3 indirectDiffuse = SHEvalLinearL0L1(float4(finalNormalWorld,1 ));

        BRDFData brdfData = (BRDFData)0;
        half alpha = 0;
        InitializeBRDFData_Specular(half3(0, 0, 0), half3(0, 0, 0), _WaterSmoothness, alpha, brdfData);

        half NdotL = saturate(dot(finalNormalWorld, L));
	    half3 radiance = mainLightColor * NdotL;

        half brdf = DirectBRDFSpecular(brdfData, finalNormalWorld, L, V);
        
        half3 specular = (brdf * waterSpecularCloseColor + bakedColorTemp) * radiance;

        half3 resultColor = indirectDiffuse * bakedColorTemp + specular;
        
        float offsetNoV = saturate(dot(tempNormalWorld, V));
        float fresnelParam = pow(1 - offsetNoV, 4);
        resultColor = lerp(resultColor, reflectColor, fresnelParam);

        float resultAlpha = i.vertexColor.a * gFinalAlpha;

        float4 atmosphereColor = CalculateAtmosphere(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);

        resultColor.rgb = lerp(resultColor.rgb, atmosphereColor.rgb, atmosphereColor.a);
        
        return float4(resultColor, resultAlpha);
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
