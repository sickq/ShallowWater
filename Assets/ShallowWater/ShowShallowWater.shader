Shader "Custom/ShowShallowDepth" {

    Properties
    {
    }
    
    HLSLINCLUDE
    
    struct v2f {
        float4 vertex : SV_POSITION;
        float4 posWorld : TEXCOORD0;
    };

    #include "UnityCG.cginc"

    sampler2D _ShallowHeightMap;
    float4 _ShallowWaterParams;

    uniform StructuredBuffer<float> _ShallowWaterBuffer;
    int _ShallowWaterSize;
    
    v2f vert(appdata_base v)
    {
        v2f o;
        o.posWorld = mul(unity_ObjectToWorld, v.vertex);

        //需要注意View空间左右手坐标系的转换
        // float2 uv = (o.posWorld.xz - _ShallowHeightMapOffset.xy) * _ShallowHeightMapOffset.w * float2(1, -1) + float2(0.5, 0.5);
        // uv = uv * float2(_ShallowWaterWidth, _ShallowWaterHeight);
        // float heightValue = _ShallowWaterBuffer[uv.y * _ShallowWaterWidth + uv.x];
        // o.posWorld.y += heightValue;

        o.vertex = mul(UNITY_MATRIX_VP, o.posWorld);
        return o;
    }


    float ValidIndex(int index, int totalIndex)
    {
        float valid = 1;
        if(index < 0 && index >= totalIndex)
        {
            valid = 0;
        }
        return valid;
    }
    
    half4 frag(v2f i) : SV_Target
    {
        //需要注意View空间左右手坐标系的转换
        float2 uv = (i.posWorld.xz - _ShallowWaterParams.xy) * _ShallowWaterParams.w * float2(1, -1) + float2(0.5, 0.5);
        uv = saturate(uv);

        uv = saturate(uv);
        float inShowBound = uv.x > 0 && uv.y > 0 && uv.x < 1 && uv.y < 1;
        float inArea = inShowBound ? 1 : 0;
        int uvXInt = floor(uv.x * _ShallowWaterSize);
        int uvYInt = floor(uv.y * _ShallowWaterSize);
        int index = uvYInt * _ShallowWaterSize + uvXInt;
        float heightValue = -_ShallowWaterBuffer[index] * inArea;

        int totalIndex = _ShallowWaterSize * _ShallowWaterSize;
        
        // int uvXInt = floor(uv.x * _ShallowWaterSize);
        // int uvYInt = floor(uv.y * _ShallowWaterSize);
        // int index = uvYInt * _ShallowWaterSize + uvXInt;
        // float heightValue = -_ShallowWaterBuffer[index] * ValidIndex(index, totalIndex);

        // int uvXInt = floor(uv.x * _ShallowWaterSize);
        // int uvYInt = floor(uv.y * _ShallowWaterSize);
        // int index = uvYInt * _ShallowWaterSize + uvXInt;
        // int index1 = uvYInt * _ShallowWaterSize + uvXInt + 1;
        // int index2 = uvYInt * _ShallowWaterSize + uvXInt - 1;
        // int index3 = (uvYInt + 1) * _ShallowWaterSize + uvXInt;
        // int index4 = (uvYInt - 1) * _ShallowWaterSize + uvXInt;
        //
        // float heightValue = -_ShallowWaterBuffer[index] * ValidIndex(index, totalIndex);
        // heightValue += -_ShallowWaterBuffer[index1] * ValidIndex(index1, totalIndex);
        // heightValue += -_ShallowWaterBuffer[index2] * ValidIndex(index2, totalIndex);
        // heightValue += -_ShallowWaterBuffer[index3] * ValidIndex(index3, totalIndex);
        // heightValue += -_ShallowWaterBuffer[index4] * ValidIndex(index4, totalIndex);
        // heightValue *= 0.2;
        
        return heightValue;
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