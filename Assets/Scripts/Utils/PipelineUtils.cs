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
    
    public static void CheckOrCreateLUT(ref RenderTexture targetLUT, Vector2Int size, RenderTextureFormat format, int depth = 0)
    {
        if (targetLUT == null || (targetLUT.width != size.x || targetLUT.height != size.y))
        {
            if (targetLUT != null) targetLUT.Release();

            var rt = new RenderTexture(size.x, size.y, 0,
                format, RenderTextureReadWrite.Linear);
            if (depth > 0)
            {
                rt.dimension = TextureDimension.Tex3D;
                rt.volumeDepth = depth;
            }

            rt.useMipMap = false;
            rt.filterMode = FilterMode.Bilinear;
            rt.enableRandomWrite = true;
            rt.Create();
            targetLUT = rt;
        }
    }
    
    public static void CheckOrCreateRT(ref RenderTexture targetLUT, Vector2Int size, RenderTextureFormat format, RenderTextureReadWrite linear = RenderTextureReadWrite.Linear)
    {
        if (targetLUT == null || (targetLUT.width != size.x || targetLUT.height != size.y))
        {
            if (targetLUT != null) targetLUT.Release();

            var rt = new RenderTexture(size.x, size.y, 0, format, linear);
            rt.useMipMap = false;
            rt.filterMode = FilterMode.Bilinear;
            rt.Create();
            targetLUT = rt;
        }
    }

    public static void Dispatch(ComputeShader cs, int kernel, Vector2Int lutSize, int z = 1)
    {
        cs.GetKernelThreadGroupSizes(kernel, out var threadNumX, out var threadNumY, out var threadNumZ);
        cs.Dispatch(kernel, lutSize.x / (int)threadNumX,
            lutSize.y / (int)threadNumY, z);
    }
    
    public static void Dispatch(CommandBuffer buffer, ComputeShader cs, int kernel, Vector2Int lutSize, int z = 1)
    {
        cs.GetKernelThreadGroupSizes(kernel, out var threadNumX, out var threadNumY, out var threadNumZ);
        buffer.DispatchCompute(cs, kernel, lutSize.x / (int)threadNumX, lutSize.y / (int)threadNumY, z);
    }
}
