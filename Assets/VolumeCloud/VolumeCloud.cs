using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VolumeCloud : MonoBehaviour
{
    public Texture2D fragmentTexture0;
    public Texture2D fragmentTexture1;
    public Texture2D fragmentTexture2;
    public Texture2D fragmentTexture5;

    public Shader VolumeCloudShader;
    
    //CameraPos 以及 Camera相关矩阵
    private static readonly Vector4[] fragmentGlobals =
    {
        new Vector4(601.33655f, 1646.8042f, 72.98492f, 0.00f),
        new Vector4(0.00f, 0.23989f, -601.23633f, 602.24615f),
        new Vector4(1.02498f, 6.72653E-14f, -1646.52979f, 1646.8042f),
        new Vector4(0.00f, 0.52515f, -72.97276f, 72.56947f),
        new Vector4(0.00f, 0.00f, -0.99983f, 1.00f),
    };
    
    private static readonly Vector4[] fragmentParams =
    {
        new Vector4(0.89906f, 0.74114f, 0.48176f, 698.00f ),
        new Vector4( 2000.00f, 2000.00f, -2.00f, 71.40f    ),
        new Vector4( 2.00f, 8.00f, 5.00f, 0.66f            ),
        new Vector4( 0.81176f, 0.70588f, 0.59608f, 1.00f   ),
        new Vector4( 0.67059f, 0.48235f, 0.36471f, 4.00f   ),
        new Vector4( 2.00f, 8.00f, 0.02f, 25.00f           ),
        new Vector4(0.4995f, 0.06f, 0.00f, 1.00f          ),
        new Vector4(1.00f, 1.10f, 1.50f, 2.00f            ),
        new Vector4(1.00f, -0.37279f, -0.73165f, -0.57071f),
        new Vector4(494.00f, 256.00f, 256.00f, 1.30f      ),
        new Vector4(35.4924f, 1280.00f, 721.00f, 0.0773f  ),
        new Vector4(0.06f, 0.40f, 2.00f, 3.00f            ),
        new Vector4(4.00f, 7.00f, 1.00f, 1.00f            ),
    };
    
    private CommandBuffer cmdBuffer;

    private Camera curCamera;

    private Material VolumeCloudMaterial;

    private Light mainLight;

    private void OnEnable()
    {
        if (VolumeCloudShader != null)
        {
            VolumeCloudMaterial = new Material(VolumeCloudShader);
        }
        
        if (cmdBuffer == null)
        {
            cmdBuffer = new CommandBuffer { name = "VolumeCloud" };
        }

        curCamera = GetComponent<Camera>();
        curCamera.RemoveCommandBuffers(CameraEvent.BeforeImageEffects);
        curCamera.AddCommandBuffer(CameraEvent.BeforeImageEffects, cmdBuffer);
        curCamera.depthTextureMode = DepthTextureMode.Depth;

        mainLight = GameObject.FindObjectOfType<Light>();
    }
    
    private void OnDisable()
    {
        if (curCamera != null)
        {
            curCamera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, cmdBuffer);
        }
        cmdBuffer.Clear();
        cmdBuffer.Release();
        curCamera.depthTextureMode = DepthTextureMode.None;
    }

    private static int _VolumeTempRT = Shader.PropertyToID("_VolumeTempRT");
    private void OnPreRender()
    {
        // Shader.SetGlobalTexture("fragmentTextures0", fragmentTexture0);
        // Shader.SetGlobalTexture("fragmentTextures1", fragmentTexture1);
        // Shader.SetGlobalTexture("fragmentTextures2", fragmentTexture2);
        // Shader.SetGlobalTexture("fragmentTextures5", fragmentTexture5);
        
        if (cmdBuffer == null) return;
        cmdBuffer.Clear();
        
        cmdBuffer.SetGlobalTexture("fragmentTextures0", fragmentTexture0);
        cmdBuffer.SetGlobalTexture("fragmentTextures1", fragmentTexture1);
        cmdBuffer.SetGlobalTexture("fragmentTextures2", fragmentTexture2);
        cmdBuffer.SetGlobalTexture("fragmentTextures5", fragmentTexture5);
        cmdBuffer.SetGlobalVector("_LightDir", mainLight.transform.forward);
        cmdBuffer.SetGlobalVector("_LightColor", mainLight.color.linear);
        cmdBuffer.SetGlobalVectorArray("fragmentGlobals", fragmentGlobals);
        cmdBuffer.SetGlobalVectorArray("fragmentParams", fragmentParams);
        
        cmdBuffer.GetTemporaryRT(_VolumeTempRT, curCamera.pixelWidth, curCamera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        cmdBuffer.Blit(BuiltinRenderTextureType.CameraTarget, _VolumeTempRT, VolumeCloudMaterial);
        cmdBuffer.Blit(_VolumeTempRT, BuiltinRenderTextureType.CameraTarget);
    }
}
