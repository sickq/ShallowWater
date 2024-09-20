using System;
using UnityEditor;
using UnityEngine;

public class EditorTools
{
    [MenuItem("工具/将CSV数据转换为高精度纹理RGBAHalf")]
    public static void ConvertRawData2Texture()
    {
        var csvObj = Selection.objects[0];
        string path = AssetDatabase.GetAssetPath(csvObj);
        var csv = System.IO.File.ReadAllText(path);
        
        var line_splitor = new string[] { "\n" };
        var line_element_splitor = new string[] { "," };
        
        var lines = csv.Split(line_splitor, StringSplitOptions.RemoveEmptyEntries);
        var semanticTitles = lines[0].Split(line_element_splitor, StringSplitOptions.RemoveEmptyEntries);

        int sizeWidth = (semanticTitles.Length - 1) / 4;
        int sizeHeight = lines.Length - 1;

        Texture2D resultTexture2D = new Texture2D(sizeWidth, sizeHeight, TextureFormat.RGBAHalf, false);

        var pixels = resultTexture2D.GetPixels();
        for (int i = 0; i < sizeHeight; i++)
        {
            var line = lines[i + 1];
            var spliteValue = line.Split(line_element_splitor, StringSplitOptions.RemoveEmptyEntries);
            
            for (int j = 0; j < sizeWidth; j++)
            {
                Color color = new Color(float.Parse(spliteValue[j * 4 + 1]), float.Parse(spliteValue[j * 4 + 1 + 1]), float.Parse(spliteValue[j * 4 + 2 + 1]), float.Parse(spliteValue[j * 4 + 3 + 1]));
                pixels[j + i * sizeWidth] = color;
            }
        }

        resultTexture2D.SetPixels(pixels);
        resultTexture2D.Apply();
        string resultPath = path.Replace(".csv", ".asset");
        AssetDatabase.CreateAsset(resultTexture2D, resultPath);
    }

    [MenuItem("工具/将CSV数据转换为高精度纹理RFloat")]
    public static void Convert2Texture2D()
    {
        var csvObj = Selection.objects[0];
        string path = AssetDatabase.GetAssetPath(csvObj);
        var csv = System.IO.File.ReadAllText(path);
        
        var line_splitor = new string[] { "\n" };
        var line_element_splitor = new string[] { "," };
        
        var lines = csv.Split(line_splitor, StringSplitOptions.RemoveEmptyEntries);
        var semanticTitles = lines[0].Split(line_element_splitor, StringSplitOptions.RemoveEmptyEntries);

        int sizeWidth = semanticTitles.Length - 1;
        int sizeHeight = lines.Length - 1;

        Texture2D resultTexture2D = new Texture2D(sizeWidth, sizeHeight, TextureFormat.RFloat, false);

        var pixels = resultTexture2D.GetPixels();
        for (int i = 0; i < sizeHeight; i++)
        {
            var line = lines[i + 1];
            var spliteValue = line.Split(line_element_splitor, StringSplitOptions.RemoveEmptyEntries);
            
            for (int j = 0; j < sizeWidth; j++)
            {
                Color color = new Color(float.Parse(spliteValue[j + 1]), 0, 0, 0);
                pixels[j + i * sizeWidth] = color;
            }
        }

        resultTexture2D.SetPixels(pixels);
        resultTexture2D.Apply();
        string resultPath = path.Replace(".csv", ".asset");
        AssetDatabase.CreateAsset(resultTexture2D, resultPath);
    }
}
