// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Skybox/AtmosphereSky" {
Properties {
    [KeywordEnum(None, Simple, High Quality)] _SunDisk ("Sun", Int) = 2
    _SunSize ("Sun Size", Range(0,1)) = 0.04
    _SunSizeConvergence("Sun Size Convergence", Range(1,10)) = 5

    _AtmosphereThickness ("Atmosphere Thickness", Range(0,5)) = 1.0
    _SkyTint ("Sky Tint", Color) = (.5, .5, .5, 1)
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)

    _Exposure("Exposure", Range(0, 8)) = 1.3
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        // #include "RenderSkyCommon.hlsl"
        #include "Assets/Shaders/Atmosphere.hlsl"

        #pragma multi_compile _ SKY_CLOUD_ENABLED
        
        uniform half _Exposure;     // HDR exposure
        uniform half3 _GroundColor;
        uniform half _SunSize;
        uniform half _SunSizeConvergence;
        uniform half3 _SkyTint;
        uniform half _AtmosphereThickness;

        struct appdata_t
        {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4 pos             : SV_POSITION;
            float3 vertex : TEXCOORD0;
            float3 posWorld : TEXCOORD1;
            float4 screenPos : TEXCOORD2;
            
            UNITY_VERTEX_OUTPUT_STEREO
        };
        
        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);
            OUT.posWorld = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
            
            OUT.vertex = v.vertex;
            OUT.screenPos = ComputeScreenPos(OUT.pos);
            
            return OUT;
        }

        half4 frag (v2f IN) : SV_Target
        {
            half4 col = half4(0.0, 0.0, 0.0, 0.0);

            float3 uniformVertPos = normalize(IN.vertex.xyz);

            col = CalculateSky(uniformVertPos);

            #if defined(SKY_CLOUD_ENABLED)
            float2 screenPos = IN.screenPos.xy / IN.screenPos.w;
            col = AppendSkyCloud(col, uniformVertPos, screenPos);
            #endif
            
            return col;
        }

        float3 GetSunSunLuminance(float3 WorldDir, float3 sunDir, float intersectGround)
        {
	        if (dot(WorldDir, sunDir) > cos(3*1.505*3.14159 / 180.0))
	        {
		        if (intersectGround > 0.0f) // no intersection
		        {
			        const float3 SunLuminance = 1; // arbitrary. But fine, not use when comparing the models
			        return SunLuminance * 1;
		        }
	        }
	        return 0;
        }
        
        // half4 fragUE(v2f IN) : SV_Target
        // {
        //     float3 WorldPos = float3(0, 0, 6360.0f + CameraAerialPerspectiveVolumeParam.w);
        //     // float3 WorldDir = normalize(IN.vertex.xzy);
        //     float3 WorldDir = normalize(normalize((IN.posWorld.xzy - _WorldSpaceCameraPos.xzy) * 6420.0f - WorldPos));
        //
        //     float viewHeight = length(WorldPos);
        //     float2 uv;
        //     float3 UpVector = normalize(WorldPos);
        //     float viewZenithCosAngle = dot(WorldDir, UpVector);
        //
        //     // float IntersectGround = raySphereIntersectNearest(WorldPos, WorldDir, float3(0, 0, 0), 6360.0f);
        //     
        //     SkyViewLutParamsToUv(WorldDir.z, viewZenithCosAngle, WorldDir, viewHeight, 6360, float2(96.0f, 104.0f), uv);
        //
        //     float4 col = tex2D(_SkyViewLutTextureL, uv);
        //     col.rgb += GetSunSunLuminance(WorldDir, -g_AtmosphereLightDirection.xzw, WorldDir.z);
        //     return col;
        // }
        
        ENDCG
    }
}


Fallback Off
}
