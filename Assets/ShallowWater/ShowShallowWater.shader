Shader "Custom/ShowShallowDepth" {

    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    
    HLSLINCLUDE
    
    struct v2f {
        float4 vertex : SV_POSITION;
        float4 posWorld : TEXCOORD0;
    };

    #include "UnityCG.cginc"

    sampler2D _ShallowHeightMap;
    float4 _ShallowWaterParams;

    int _ShallowWaterSize;
    sampler2D _ShallowWaterHeightRT;
    
    v2f vert(appdata_base v)
    {
        v2f o;
        o.posWorld = mul(unity_ObjectToWorld, v.vertex);

        half2 offset = half2(1, 1);
        #if SHADER_API_D3D11
            offset = half2(1, -1);
        #endif
        
        //需要DX下的UV差异
        float2 uv = saturate((o.posWorld.xz - _ShallowWaterParams.xy) * _ShallowWaterParams.w * offset + float2(0.5, 0.5));
        
        float heightValue = tex2Dlod(_ShallowWaterHeightRT, float4(uv, 0, 0)).r;
        o.posWorld.y += heightValue;

        o.vertex = mul(UNITY_MATRIX_VP, o.posWorld);
        return o;
    }

    sampler2D _MainTex;
    
    half4 frag(v2f i) : SV_Target
    {
        return tex2D(_MainTex, i.posWorld.xz);
    }
    
    ENDHLSL

    SubShader{
        Tags{ "RenderType" = "Opaque" }
        CULL Off
        Pass{
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            ENDHLSL
        }
    }
}