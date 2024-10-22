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
        #include "RenderSkyCommon.hlsl"


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
            float4  pos             : SV_POSITION;
            float3 vertex : TEXCOORD0;
            float3 posWorld : TEXCOORD1;

            UNITY_VERTEX_OUTPUT_STEREO
        };


        float4 g_AtmosphereLightDirection;

        sampler2D _SkyViewLutTextureL;
        
        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);
            OUT.posWorld = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
            
            OUT.vertex = v.vertex;
            
            return OUT;
        }

        // max absolute error 1.3x10^-3
        // Eberly's odd polynomial degree 5 - respect bounds
        // 4 VGPR, 14 FR (10 FR, 1 QR), 2 scalar
        // input [0, infinity] and output [0, PI/2]
        float FastATanPos(float x)
        {
            float t0 = (x < 1.0) ? x : 1.0 / x;
            float t1 = t0 * t0;
            float poly = 0.0872929;
            poly = -0.301895 + poly * t1;
            poly = 1.0 + poly * t1;
            poly = poly * t0;
            return (x < 1.0) ? poly : UNITY_HALF_PI - poly;
        }

        // 4 VGPR, 16 FR (12 FR, 1 QR), 2 scalar
        // input [-infinity, infinity] and output [-PI/2, PI/2]
        float FastATan(float x)
        {
            float t0 = FastATanPos(abs(x));
            return (x < 0.0) ? -t0 : t0;
        }

        float FastAtan2(float y, float x)
        {
            return FastATan(y / x) + (y >= 0.0 ? UNITY_PI : -UNITY_PI) * (x < 0.0);
        }

        
        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);

            float3 uniformVertPos = normalize(IN.vertex.xyz);
            float reverseY = (1 - uniformVertPos.y) * 0.5f;
            
            float xz = 1 - uniformVertPos.y * uniformVertPos.y;
            xz = sqrt(xz);

            float tempValue = dot(float2(-uniformVertPos.x, uniformVertPos.z), g_AtmosphereLightDirection.xy);
            tempValue = clamp(tempValue / xz, -1, 1);

            tempValue = acos(tempValue);
            tempValue = tempValue / UNITY_PI;
            tempValue = sqrt(tempValue);

            float2 tempUV = float2(tempValue, reverseY);
            tempUV = (tempUV + float2(0.00520833349, 0.00480769249)) * float2(0.989690721, 0.990476191);

            float maxXZ = max(abs(uniformVertPos.z), abs(uniformVertPos.x));
            float minXZ = min(abs(uniformVertPos.z), abs(uniformVertPos.x));

            float atan = FastAtan2(uniformVertPos.x, uniformVertPos.z);

            col = tex2D(_SkyViewLutTextureL, tempUV);

            return half4(col, 0.0);
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
        
        half4 fragUE(v2f IN) : SV_Target
        {
            float3 WorldPos = float3(0, 0, 6360.0f + CameraAerialPerspectiveVolumeParam.w);
            // float3 WorldDir = normalize(IN.vertex.xzy);
            float3 WorldDir = normalize(normalize((IN.posWorld.xzy - _WorldSpaceCameraPos.xzy) * 6420.0f - WorldPos));

            float viewHeight = length(WorldPos);
            float2 uv;
            float3 UpVector = normalize(WorldPos);
            float viewZenithCosAngle = dot(WorldDir, UpVector);

            // float IntersectGround = raySphereIntersectNearest(WorldPos, WorldDir, float3(0, 0, 0), 6360.0f);
            
            SkyViewLutParamsToUv(WorldDir.z, viewZenithCosAngle, WorldDir, viewHeight, 6360, float2(96.0f, 104.0f), uv);

            float4 col = tex2D(_SkyViewLutTextureL, uv);
            col.rgb += GetSunSunLuminance(WorldDir, -g_AtmosphereLightDirection.xzw, WorldDir.z);
            return col;
        }
        
        ENDCG
    }
}


Fallback Off
}
