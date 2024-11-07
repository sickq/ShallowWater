Shader "Unlit/DefaultLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("_Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            ZWrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Atmosphere.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 posWorld : TEXCOORD1;
                float4 viewDir : TEXCOORD2;
                float4 customValue : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            
            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));

                o.viewDir.xyz = o.posWorld - _WorldSpaceCameraPos.xyz;
                float2 atmosVertData = PrepareAtmosphereVertex(o.viewDir.xyz);
                o.viewDir.w = atmosVertData.y;
                o.customValue.x = atmosVertData.x;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv) * _Color;

                float3 viewDir = i.posWorld - _WorldSpaceCameraPos.xyz;

                float4 atmosphereColor = CalculateAtmosphere(viewDir);

                // float4 atmosphereColor = CalculateAtmosphereVertex(viewDir.y, i.viewDir.w, i.customValue.x);

                col.rgb = lerp(col.rgb, atmosphereColor.rgb, atmosphereColor.a);
                col.a = 1 - atmosphereColor.a;
                return col;
            }
            ENDCG
        }
        
        Pass 
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
    }
}
