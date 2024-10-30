using UnityEngine;

[CreateAssetMenu(fileName = "SkyCloudData", menuName = "配置文件/SkyCloudData")]
public class SkyCloudData : ScriptableObject
{
    public Shader SkyCloudShader;
    
    [Header("云RT渲染比例")]
    [Range(0, 10)] public int SkyCloudDownScale = 4;
    
    [Header("天空云的高度"), Range(0, 2000)]public float SkyCloudHeight = 211;
    public Vector3 SkyCloudScale = new Vector3(20000, 100, 20000);

    public Texture2DArray WorleyNoiseTex;
    public Texture2D PerlinForSkyCloudTex;
    public Texture2D PerlinToDilateWorley;
    
    [ColorUsage(false, true)] public Color SunColor = new Color(7.5f, 7.5f, 7.5f, 7.5f);
    [ColorUsage(false, true)] public Color EnvColor = new Color(72.3f, 72.3f, 72.3f, 72.3f);
    [ColorUsage(false, true)] public Color DarkColor = new Color(0.13512f, 0.20625f, 0.30227f, 0.19805f);

    [Range(0, 20)] public float perlinForSkyCloudNoiseScale = 6.5f;
    [Range(0, 20)] public float perlinToDilateWorleyNoiseScale = 10.0f;
    
    [Header("云形状")]
    public Vector2 perlinNoiseDir = new Vector2(0.7f, -0.7f);
    [Range(-20, 20)] public float perlinNoiseSpeed = 0.002f;

    [Range(-2, 2)] public float perlinToDilateWorleyWeight = 0.66f;
    [Range(-2, 2)] public float perlinNoiseWeight = 0.61865f;
    [Range(-2, 2)] public float perlinNoiseYWeight = 1.0f;
    [Range(-10, 10)] public float perlinNoiseYParam = 2.0f;

    [Range(0.001f, 2)] public float perlinNoisePow = 0.838f;
    
    public Vector3 worleyNoiseDir = new Vector3(-0.4f, 0.0f, 0.6f);
    [Range(-5, 5)] public float worleyNoiseSpeed = 0.01f;
    
    [Range(-5, 5)] public float WorleyNoiseYScale = 1.30667f;
    
    [Range(0.001f, 2)] public float WorleyNoiseWeight = 0.55f;


    [Header("云形状步进参数")]
    [Header("最大步进次数"), Range(0, 50)] public int maxRayStep = 20;
    [Header("步进偏移"), Range(0, 2)] public float rayOffset = 1.0f;
    [Range(0.0001f, 1)] public float rayScale = 0.03f;

    [Header("光照步进参数")]
    [Header("光照步进次数"), Range(0, 10)] public int SubRayStepCount = 2;
    [Header("光照步进距离"), Range(0, 20)] public int SubRayStepLength = 14;
    [Header("光照传输"), Range(0, 20)] public int SubRayLightTrans = 15;
    
    [Header("光照噪声Param"), Range(-1, 1)] public float lightNoiseParam = 0.24f;
    
    [Header("云透射Pow,伪造"), Range(0, 10)] public float _FakeCloudTransmittancePow = 0.10f;
    [Header("云透射权重,伪造"), Range(0, 10)] public float _FakeCloudTransmittanceWeight = 0.30f;
    [Header("云透射权重,伪造"), Range(0, 2)] public float _FakeCloudTransmittanceOffset = 0.50f;

    [Header("Front Phase Param")]
    [Range(0, 2)]public float PhaseScale = 0.406f;
    [Range(-5, 5)]public float PhaseOffset = 1.04121f;
    [Range(0, 1)]public float PhaseInvParam = 0.03815f;
        
    [Header("Back Phase Param")]
    [Range(0, 2)]public float BackPhaseScale = 0.80f;
    [Range(-5, 5)]public float BackPhaseOffset = 1.16f;
    [Range(0, 1)]public float BackPhaseInvParam = 0.03342f;
}
