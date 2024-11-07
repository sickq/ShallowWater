using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugGUI1 : MonoBehaviour
{
    [ContextMenu("ActiveDepthTexture")]
    public void ActiveDepthTexture()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }
}
