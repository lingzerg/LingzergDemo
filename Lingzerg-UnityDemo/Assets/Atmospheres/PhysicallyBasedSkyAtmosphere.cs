using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class PhysicallyBasedSkyAtmosphere : MonoBehaviour
{
    protected Shader _ppShader;
    protected Material _ppMaterial;

    public Light Sun;


    [Range(1, 512)]
    public int SampleCount = 16;
    public float MaxRayLength = 400;

    [ColorUsage(false, true, 0, 10, 0, 10)]
    public Color IncomingLight = new Color(4, 4, 4, 4);
    [Range(0, 10.0f)]
    public float RayleighScatterCoef = 1;
    [Range(0, 10.0f)]
    public float RayleighExtinctionCoef = 1;
    [Range(0, 10.0f)]
    public float MieScatterCoef = 1;
    [Range(0, 10.0f)]
    public float MieExtinctionCoef = 1;
    [Range(0.0f, 0.999f)]
    public float MieG = 0.76f;
    public float DistanceScale = 1;


    private Color _sunColor;

    private const float AtmosphereHeight = 80000.0f;
    private const float PlanetRadius = 6371000.0f;
    private readonly Vector4 DensityScale = new Vector4(7994.0f, 1200.0f, 0, 0);
    private readonly Vector4 RayleighSct = new Vector4(5.8f, 13.5f, 33.1f, 0.0f) * 0.000001f;
    private readonly Vector4 MieSct = new Vector4(2.0f, 2.0f, 2.0f, 0.0f) * 0.00001f;

    //shadow
    private CommandBuffer _cascadeShadowCommandBuffer;


    void Start()
    {
        _InitPPShader();

        _ppMaterial = new Material(_ppShader);
        _ppMaterial.hideFlags = HideFlags.HideAndDontSave;
    }

    void Update()
    {
        
    }

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (_ppShader != null)
        {
            _SetPPShaderParam();
            Graphics.Blit(sourceTexture, destTexture, _ppMaterial);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

    public void EnableLightShafts()
    {
        if (_cascadeShadowCommandBuffer == null)
            InitializeLightShafts();

        Sun.RemoveCommandBuffer(LightEvent.AfterShadowMap, _cascadeShadowCommandBuffer);

        Sun.AddCommandBuffer(LightEvent.AfterShadowMap, _cascadeShadowCommandBuffer);
    }

    public void InitializeLightShafts()
    {
        if (_cascadeShadowCommandBuffer == null)
        {
            _cascadeShadowCommandBuffer = new CommandBuffer();
            _cascadeShadowCommandBuffer.name = "CascadeShadowCommandBuffer";
            _cascadeShadowCommandBuffer.SetGlobalTexture("_CascadeShadowMapTexture", new UnityEngine.Rendering.RenderTargetIdentifier(UnityEngine.Rendering.BuiltinRenderTextureType.CurrentActive));
        }
    }

    protected void _InitPPShader()
    {
        _ppShader = Shader.Find("Woody/PhysicallyBasedSky-Atmosphere");
        EnableLightShafts();
    }

    protected void _SetPPShaderParam()
    {
        _SetClipToWorldMatrixToMaterial();


    }

    void _SetClipToWorldMatrixToMaterial()
    {

        var projectionMatrix = GL.GetGPUProjectionMatrix(Camera.current.projectionMatrix, false);

        _ppMaterial.SetMatrix("_InverseViewMatrix", Camera.current.worldToCameraMatrix.inverse);
        _ppMaterial.SetMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);

        _ppMaterial.SetFloat("_AtmosphereHeight", AtmosphereHeight);
        _ppMaterial.SetFloat("_PlanetRadius", PlanetRadius);
        _ppMaterial.SetVector("_DensityScaleHeight", DensityScale);

        Vector4 scatteringR = new Vector4(5.8f, 13.5f, 33.1f, 0.0f) * 0.000001f;
        Vector4 scatteringM = new Vector4(2.0f, 2.0f, 2.0f, 0.0f) * 0.00001f;

        _ppMaterial.SetVector("_ScatteringR", RayleighSct * RayleighScatterCoef);
        _ppMaterial.SetVector("_ScatteringM", MieSct * MieScatterCoef);
        _ppMaterial.SetVector("_ExtinctionR", RayleighSct * RayleighExtinctionCoef);
        _ppMaterial.SetVector("_ExtinctionM", MieSct * MieExtinctionCoef);
        
        _ppMaterial.SetColor("_IncomingLight", IncomingLight);
        _ppMaterial.SetFloat("_MieG", MieG);
        _ppMaterial.SetFloat("_DistanceScale", DistanceScale);
        _ppMaterial.SetColor("_SunColor", _sunColor);

        _ppMaterial.SetInt("_SampleCount", SampleCount);
        
        
        //---------------------------------------------------
        
        _ppMaterial.SetVector("_LightDir", new Vector4(Sun.transform.forward.x, Sun.transform.forward.y, Sun.transform.forward.z, 1.0f / (Sun.range * Sun.range)));
        _ppMaterial.SetVector("_LightColor", Sun.color * Sun.intensity);
    }

}
