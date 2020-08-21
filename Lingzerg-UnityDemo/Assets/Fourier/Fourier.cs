using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fourier : MonoBehaviour
{
    
    public ComputeShader _compute;
    
    public MeshRenderer forFourierSpectrumObj;
    public MeshRenderer forFourierPhaseObj;

    public MeshRenderer forFourierRevertObj;

    public MeshRenderer meshReal;

    public MeshRenderer meshImaginary;

    public Texture2D originalImg;

    [Range(16,512)]
    public int TextureSize = 512;

    void Start()
    {
        RenderTexture rtFourierSpectrum = CreateRenderTexture(TextureSize);
        //Spectrum
        //Phase

        RenderTexture rtFourierPhase = CreateRenderTexture(TextureSize);

        RenderTexture rtReal = CreateRenderTexture(TextureSize);
        RenderTexture rtImaginary = CreateRenderTexture(TextureSize);


        _compute.SetInt("TextureSize",TextureSize);

        int kernelHandle = _compute.FindKernel("Fourier");
        _compute.SetTexture(kernelHandle, "rtFourierSpectrum", rtFourierSpectrum);
        
        _compute.SetTexture(kernelHandle, "rtReal", rtReal);
        _compute.SetTexture(kernelHandle, "rtImaginary", rtImaginary);

        _compute.SetTexture(kernelHandle, "rtFourierPhase", rtFourierPhase);
        _compute.SetTexture(kernelHandle, "originalImg", originalImg);
        _compute.Dispatch(kernelHandle, 32, 32, 1);
        forFourierSpectrumObj.material.SetTexture("_MainTex",rtFourierSpectrum);
        forFourierPhaseObj.material.SetTexture("_MainTex", rtFourierPhase);
        meshReal.material.SetTexture("_MainTex", rtReal);
        meshImaginary.material.SetTexture("_MainTex", rtImaginary);

        //傅里叶逆变换

        RenderTexture rtFourierInverse = CreateRenderTexture(TextureSize);

        int kernelHandleFourierInverse = _compute.FindKernel("FourierInverse");
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierInverse", rtFourierInverse);
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierSpectrum", rtFourierSpectrum);
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierPhase", rtFourierPhase);
        _compute.Dispatch(kernelHandleFourierInverse, 32, 32, 1);
        forFourierRevertObj.material.SetTexture("_MainTex",rtFourierInverse);

    }

    RenderTexture CreateRenderTexture(int size) {
        
        RenderTexture rt = new RenderTexture(size,size,24);
        rt.format = RenderTextureFormat.ARGBFloat;
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
        rt.DiscardContents();
        return rt;
    }
}
