using UnityEditor;
using UnityEngine;

public class SkyCloudTools : Editor
{
    [MenuItem("工具/拆分天空云纹理")]
    public static void SplitTexture2Single()
    {
        var texture = Selection.objects[0] as Texture2D;
        int width = 128;

        for (int i = 0; i < 32; i++)
        {
            int indexY = 5 - i / 6;
            int indexX = i % 6;
            var pixels = texture.GetPixels(indexX * width, indexY * width, width, width);
            var texture2D = new Texture2D(width, width, texture.format, false);
            texture2D.SetPixels(pixels);
            texture2D.Apply();

            var bytes = texture2D.EncodeToTGA();
            System.IO.File.WriteAllBytes($"Assets/SkyCloud/{i}.tga", bytes);
        }
        AssetDatabase.Refresh();
    }
}
