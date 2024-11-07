#ifndef RAY_PBR_BRDF
#define RAY_PBR_BRDF

#include "UnityStandardBRDF.cginc"	

#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

struct BRDFData
{
	half3 albedo;
	half3 diffuse;
	half3 specular;
	half reflectivity;
	half perceptualRoughness;
	half roughness;
	half roughness2;
	half grazingTerm;
	half indirectRoughness;

	// We save some light invariant BRDF terms so we don't have to recompute
	// them in the light loop. Take a look at DirectBRDF function for detailed explaination.
	half normalizationTerm;     // roughness * 4.0 + 2.0
	half roughness2MinusOne;    // roughness^2 - 1.0
};

// Must match BuiltIn ShaderGraph master node
struct SurfaceData
{
	half3 albedo;
	half3 specular;
	half  metallic;
	half  smoothness;
	half3 normalTS;
	half3 emission;
	half  occlusion;
	half  alpha;
	half  clearCoatMask;
	half  clearCoatSmoothness;
};

float PerceptualSmoothnessToPerceptualRoughness(float perceptualSmoothness)
{
	return (1.0 - perceptualSmoothness);
}

half3 ConvertF0ForAirInterfaceToF0ForClearCoat15Fast(half3 fresnel0)
{
	return saturate(fresnel0 * (fresnel0 * 0.526868 + 0.529324) - 0.0482256);
}

inline void InitializeBRDFDataDirect(half3 albedo, half3 diffuse, half3 specular, half reflectivity, half oneMinusReflectivity, half smoothness, inout half alpha, out BRDFData outBRDFData)
{
	outBRDFData = (BRDFData)0;
	outBRDFData.albedo = albedo;
	outBRDFData.diffuse = diffuse;
	outBRDFData.specular = specular;
	outBRDFData.reflectivity = reflectivity;

	outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	outBRDFData.roughness           = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
	outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
	outBRDFData.grazingTerm         = saturate(smoothness + reflectivity);
	outBRDFData.normalizationTerm   = outBRDFData.roughness * half(4.0) + half(2.0);
	outBRDFData.roughness2MinusOne  = outBRDFData.roughness2 - half(1.0);

	#ifdef _ALPHAPREMULTIPLY_ON
	outBRDFData.diffuse *= alpha;
	alpha = alpha * oneMinusReflectivity + reflectivity; // NOTE: alpha modified and propagated up.
	#endif
}


float3 Max3(float a, float b, float c)
{
	return max(max(a, b), c);
}

half ReflectivitySpecular(half3 specular)
{
	#if defined(SHADER_API_GLES)
	return specular.r; // Red channel - because most metals are either monocrhome or with redish/yellowish tint
	#else
	return Max3(specular.r, specular.g, specular.b);
	#endif
}

half OneMinusReflectivityMetallic(half metallic)
{
	// We'll need oneMinusReflectivity, so
	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
	// store (1-dielectricSpec) in kDielectricSpec.a, then
	//   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
	//                  = alpha - metallic * alpha
	half oneMinusDielectricSpec = kDielectricSpec.a;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline void InitializeBRDFData(half3 albedo, half metallic, half3 specular, half smoothness, inout half alpha, out BRDFData outBRDFData)
{
#ifdef _SPECULAR_SETUP
	half reflectivity = ReflectivitySpecular(specular);
	half oneMinusReflectivity = half(1.0) - reflectivity;
	half3 brdfDiffuse = albedo * (half3(1.0, 1.0, 1.0) - specular);
	half3 brdfSpecular = specular;
#else
	half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
	half reflectivity = half(1.0) - oneMinusReflectivity;
	half3 brdfDiffuse = albedo * oneMinusReflectivity;
	half3 brdfSpecular = lerp(kDielectricSpec.rgb, albedo, metallic);
#endif

	InitializeBRDFDataDirect(albedo, brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, smoothness, alpha, outBRDFData);
}

inline void InitializeBRDFData_Specular(half3 albedo, half3 specular, half smoothness, inout half alpha, out BRDFData outBRDFData)
{
	half reflectivity = ReflectivitySpecular(specular);
	half oneMinusReflectivity = half(1.0) - reflectivity;
	half3 brdfDiffuse = albedo * (half3(1.0, 1.0, 1.0) - specular);
	half3 brdfSpecular = specular;
	InitializeBRDFDataDirect(albedo, brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, smoothness, alpha, outBRDFData);
}

inline void InitializeBRDFDataClearCoat(half clearCoatMask, half clearCoatSmoothness, inout float3 specColor, out BRDFData outBRDFData)
{
    outBRDFData = (BRDFData)0;
    outBRDFData.albedo = half(1.0);

    // Calculate Roughness of Clear Coat layer
    outBRDFData.diffuse             = kDielectricSpec.aaa; // 1 - kDielectricSpec
    outBRDFData.specular            = kDielectricSpec.rgb;
    outBRDFData.reflectivity        = kDielectricSpec.r;

    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(clearCoatSmoothness);
    outBRDFData.roughness           = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
    outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
    outBRDFData.normalizationTerm   = outBRDFData.roughness * half(4.0) + half(2.0);
    outBRDFData.roughness2MinusOne  = outBRDFData.roughness2 - half(1.0);
    outBRDFData.grazingTerm         = saturate(clearCoatSmoothness + kDielectricSpec.x);

    // Darken/saturate base layer using coat to surface reflectance (vs. air to surface)
    specColor = lerp(specColor, ConvertF0ForAirInterfaceToF0ForClearCoat15Fast(specColor), clearCoatMask);
    // TODO: what about diffuse? at least in specular workflow diffuse should be recalculated as it directly depends on it.
}

BRDFData CreateClearCoatBRDFData(half clearCoatMask, half clearCoatSmoothness, inout float3 specColor)
{
	BRDFData brdfDataClearCoat = (BRDFData)0;

	#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
	InitializeBRDFDataClearCoat(clearCoatMask, clearCoatSmoothness, specColor, brdfDataClearCoat);
	#endif

	return brdfDataClearCoat;
}

#define FLT_MIN  1.175494351e-38 // Minimum normalized positive floating-point number

// Normalize that account for vectors with zero length
float3 SafeNormalize(float3 inVec)
{
	float dp3 = max(FLT_MIN, dot(inVec, inVec));
	return inVec * rsqrt(dp3);
}

// Computes the scalar specular term for Minimalist CookTorrance BRDF
// NOTE: needs to be multiplied with reflectance f0, i.e. specular color to complete
half DirectBRDFSpecular(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
	float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
	float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));

	float NoH = saturate(dot(float3(normalWS), halfDir));
	half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// BRDFspec = (D * V * F) / 4.0
	// D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
	// V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155

	// Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
	// We further optimize a few light invariant terms
	// brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
	float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
	float d2 = d * d;
	half LoH2 = LoH * LoH;
	half specularTerm = brdfData.roughness2 / (d2 * max(half(0.1), LoH2) * brdfData.normalizationTerm);

	// On platforms where half actually means something, the denominator has a risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
	#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
	specularTerm = specularTerm - HALF_MIN;
	// specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
	#endif

	return specularTerm;
}

float D_GGXMagic( float a2, float2 roughness, float NoH2, float VoH2 )
{
	a2 = max(a2, 0.01);
	float d = a2 * NoH2 - NoH2 + 1;
	float d2 = d * d;
	d2 = roughness * d2;
	float magicNum9 = VoH2 * d2;
	magicNum9 = a2 / magicNum9;
	return magicNum9;
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float D_GGX( float a2, float NoH )
{
	float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
	return a2 / ( UNITY_PI*d*d );					// 4 mul, 1 rcp
}

// Smith term for GGX
// [Smith 1967, "Geometrical shadowing of a random rough surface"]
float Vis_Smith( float a2, float NoV, float NoL )
{
	float Vis_SmithV = NoV + sqrt( NoV * (NoV - NoV * a2) + a2 );
	float Vis_SmithL = NoL + sqrt( NoL * (NoL - NoL * a2) + a2 );
	return rcp( Vis_SmithV * Vis_SmithL );
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
float3 F_Schlick( float3 SpecularColor, float VoH )
{
	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	//return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
}

half3 DirectBRDFSpecularSmith(float roughness, float3 specularColor, float3 normalWS, half3 lightDirectionWS, float3 viewDirectionWS)
{
	float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
	float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + viewDirectionWS);

	float NoH = saturate(dot(float3(normalWS), halfDir));
	half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));
	half NoL = saturate(dot(normalWS, lightDirectionWS));
	half NoV = saturate(dot(normalWS, viewDirectionWS));

	float D = D_GGX(roughness * roughness * roughness * roughness, NoH);
	float V = Vis_Smith(roughness * roughness, NoV, NoL);
	float3 F = F_Schlick(specularColor, LoH);	//LoH == VoH

	float3 result = D * V * F * NoL;
	return result;
}

#endif
