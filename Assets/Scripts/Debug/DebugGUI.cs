using System;
using UnityEngine;

public class DebugGUI : MonoBehaviour
{
    private ShallowWater shallowWater;

    private void Awake()
    {
        if (shallowWater == null)
        {
            shallowWater = GameObject.Find("ShallowWater").GetComponent<ShallowWater>();
        }
    }

    private void OnGUI()
    {
        if (GUILayout.Button("Active ResetShallowWater", GUILayout.Width(200), GUILayout.Height(100)))
        {
            shallowWater.enabled = !shallowWater.enabled;
        }
        
        if (GUILayout.Button("Frame60", GUILayout.Width(200), GUILayout.Height(100)))
        {
            Application.targetFrameRate = 60;
        }

        GUILayout.Space(10);
        shallowWater.Damping = GUILayout.HorizontalSlider(shallowWater.Damping, 0, 1.0f, GUILayout.Width(200), GUILayout.Height(30));
        shallowWater.Damping = float.Parse(GUILayout.TextArea(shallowWater.Damping.ToString(), GUILayout.Width(200), GUILayout.Height(30)));
        GUILayout.Space(10);
        shallowWater.TravelSpeed = GUILayout.HorizontalSlider(shallowWater.TravelSpeed, 0, 0.5f, GUILayout.Width(200), GUILayout.Height(30));
        shallowWater.TravelSpeed = float.Parse(GUILayout.TextArea(shallowWater.TravelSpeed.ToString(), GUILayout.Width(200), GUILayout.Height(30)));
        
        GUILayout.Space(10);
        shallowWater.ShallowWaterMaxDepth = GUILayout.HorizontalSlider(shallowWater.ShallowWaterMaxDepth, 0, 5f, GUILayout.Width(200), GUILayout.Height(30));
        shallowWater.ShallowWaterMaxDepth = float.Parse(GUILayout.TextArea(shallowWater.ShallowWaterMaxDepth.ToString(), GUILayout.Width(200), GUILayout.Height(30)));
        GUILayout.Space(10);

        GUILayout.Label($"SystemInfo.supportsComputeShaders {SystemInfo.supportsComputeShaders}");
        GUILayout.Label($"SystemInfo.supportedRandomWriteTargetCount {SystemInfo.supportedRandomWriteTargetCount}");
        GUILayout.Label($"SystemInfo.supportsIndirectArgumentsBuffer {SystemInfo.supportsIndirectArgumentsBuffer}");
        GUILayout.Label($"SystemInfo.maxComputeBufferInputsVertex {SystemInfo.maxComputeBufferInputsVertex}");
        GUILayout.Label($"SystemInfo.graphicsDeviceName {SystemInfo.graphicsDeviceName}");
        GUILayout.Label($"SystemInfo.graphicsDeviceType {SystemInfo.graphicsDeviceType}");
        GUILayout.Label($"SystemInfo.graphicsDeviceVendor {SystemInfo.graphicsDeviceVendor}");
        GUILayout.Label($"SystemInfo.graphicsDeviceVersion {SystemInfo.graphicsDeviceVersion}");
        GUILayout.Label($"SystemInfo.graphicsShaderLevel {SystemInfo.graphicsShaderLevel}");
    }
}
