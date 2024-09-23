using UnityEngine;
using UnityEngine.Rendering;

public class PipelineUtils
{
    public static void ReleaseRT(ref RenderTexture rt)
    {
        if (rt != null)
        {
            rt.Release();
            rt = null;
        }
    }

    public static void ReleaseComputeBuffer(ref ComputeBuffer buffer)
    {
        if (buffer != null)
        {
            buffer.Release();
            buffer = null;
        }
    }

    public static void DestroyObject(Object obj)
    {
#if UNITY_EDITOR
        if (Application.isPlaying)
        {
            Object.Destroy(obj);
        }
        else
        {
            Object.DestroyImmediate(obj);
        }
#else
        Object.Destroy(obj);
#endif
    }

    public static void ReleaseMaterial(ref Material material)
    {
        if (material != null)
        {
            DestroyObject(material);
            material = null;
        }
    }
    
    public static void ReleaseCommandBuffer(ref CommandBuffer buffer)
    {
        if (buffer != null)
        {
            buffer.Release();
            buffer = null;
        }
    }
}
