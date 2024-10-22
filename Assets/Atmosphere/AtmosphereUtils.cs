using System;
using System.Reflection;
using UnityEngine.Rendering;

namespace Atmosphere
{
    using UnityEngine;

    public class AtmosphereUtils
    {
        public static void CheckOrCreateLUT(ref RenderTexture targetLUT, Vector2Int size, RenderTextureFormat format,
            int depth = 0)
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

        public static void Dispatch(ComputeShader cs, int kernel, Vector2Int lutSize, int z = 1)
        {
            cs.GetKernelThreadGroupSizes(kernel, out var threadNumX, out var threadNumY, out var threadNumZ);
            cs.Dispatch(kernel, lutSize.x / (int)threadNumX,
                lutSize.y / (int)threadNumY, z);
        }
        
        public static int SetConstant(ComputeShader computeShader, Type structType, object cb)
        {
            FieldInfo[] fields = structType.GetFields(BindingFlags.Public | BindingFlags.Instance);
            int size = 0;
            foreach (FieldInfo field in fields)
            {
                var value = field.GetValue(cb);
                if (field.FieldType == typeof(float))
                {
                    computeShader.SetFloat(field.Name, (float)value);
                    size++;
                }
                else if (field.FieldType == typeof(int))
                {
                    computeShader.SetInt(field.Name, (int)value);
                    size++;
                }
                else if (field.FieldType == typeof(float[]))
                {
                    computeShader.SetFloats(field.Name, (float[])value);
                    size += ((float[])value).Length;
                }
                else if (field.FieldType == typeof(Vector3))
                {
                    computeShader.SetVector(field.Name, (Vector3)value);
                    size += 3;
                }
                else if (field.FieldType == typeof(Vector4))
                {
                    computeShader.SetVector(field.Name, (Vector4)value);
                    size += 4;
                }
                else if (field.FieldType == typeof(Color))
                {
                    computeShader.SetVector(field.Name, (Vector4)((Color)value));
                    size += 4;
                }
                else if (field.FieldType == typeof(Matrix4x4))
                {
                    computeShader.SetMatrix(field.Name, (Matrix4x4)value);
                    size += 16;
                }
                else
                {
                    throw new Exception("not find type:" + field.FieldType);
                }
            }

            return size;
        }
        
        public static int SetConstant(Material material, Type structType, object cb)
        {
            FieldInfo[] fields = structType.GetFields(BindingFlags.Public | BindingFlags.Instance);
            int size = 0;
            foreach (FieldInfo field in fields)
            {
                var value = field.GetValue(cb);
                if (field.FieldType == typeof(float))
                {
                    material.SetFloat(field.Name, (float)value);
                    size++;
                }
                else if (field.FieldType == typeof(int))
                {
                    material.SetInt(field.Name, (int)value);
                    size++;
                }
                else if (field.FieldType == typeof(float[]))
                {
                    material.SetFloatArray(field.Name, (float[])value);
                    size += ((float[])value).Length;
                }
                else if (field.FieldType == typeof(Vector3))
                {
                    material.SetVector(field.Name, (Vector3)value);
                    size += 3;
                }
                else if (field.FieldType == typeof(Vector4))
                {
                    material.SetVector(field.Name, (Vector4)value);
                    size += 4;
                }
                else if (field.FieldType == typeof(Color))
                {
                    material.SetVector(field.Name, (Vector4)((Color)value));
                    size += 4;
                }
                else if (field.FieldType == typeof(Matrix4x4))
                {
                    material.SetMatrix(field.Name, (Matrix4x4)value);
                    size += 16;
                }
                else
                {
                    throw new Exception("not find type:" + field.FieldType);
                }
            }

            return size;
        }
        
        public static float GetHgPhaseK(float g)
        {
            float k = 3.0f / (8.0f * Mathf.PI) * (1.0f - g * g) / (2.0f + g * g);
            return k;
        }
    }
}