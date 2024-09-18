using UnityEngine;

public class DebugGUI : MonoBehaviour
{
    private GameObject shallowWater;
    private void OnGUI()
    {
        if (GUILayout.Button("Reset ResetShallowWater", GUILayout.Width(200), GUILayout.Height(100)))
        {
            if (shallowWater == null)
            {
                shallowWater = GameObject.Find("ShallowWater");
            }
            var ShallowWater = shallowWater.GetComponent<ShallowWater>();

            ShallowWater.enabled = !ShallowWater.enabled;
        }
        
        if (GUILayout.Button("Active ShallowWater", GUILayout.Width(200), GUILayout.Height(100)))
        {
            if (shallowWater == null)
            {
                shallowWater = GameObject.Find("ShallowWater");
            }
            shallowWater.SetActive(!shallowWater.activeSelf);
        }
        
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
