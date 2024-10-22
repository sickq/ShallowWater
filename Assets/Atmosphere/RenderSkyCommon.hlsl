// Copyright Epic Games, Inc. All Rights Reserved.


#include "./SkyAtmosphereCommon.hlsl"

Texture2D<float4>  TransmittanceLutTexture				: register(t1);
Texture2D<float4>  SkyViewLutTexture					: register(t2);

Texture2D<float4>  MultiScatTexture						: register(t4);
Texture3D<float4>  AtmosphereCameraScatteringVolume		: register(t5);

RWTexture2D<float4>  OutputTexture						: register(u0);
RWTexture2D<float4>  OutputTexture1						: register(u1);

#define RAYDPOS 0.00001f

#ifndef GROUND_GI_ENABLED
#define GROUND_GI_ENABLED 0
#endif
#ifndef TRANSMITANCE_METHOD
#define TRANSMITANCE_METHOD 2
#endif

#ifndef GAMEMODE_ENABLED 
#define GAMEMODE_ENABLED 0 
#endif


#ifndef MEAN_ILLUM_MODE 
#define MEAN_ILLUM_MODE 0 
#endif

#define RENDER_SUN_DISK 1

#if 1
#define USE_CornetteShanks
#define MIE_PHASE_IMPORTANCE_SAMPLING 0
#else
// Beware: untested, probably faulty code path.
// Mie importance sampling is only used for multiple scattering. Single scattering is fine and noise only due to sample selection on view ray.
// A bit more expenssive so off for now.
#define MIE_PHASE_IMPORTANCE_SAMPLING 1
#endif


#define PLANET_RADIUS_OFFSET 0.001f

struct Ray
{
	float3 o;
	float3 d;
};

Ray createRay(in float3 p, in float3 d)
{
	Ray r;
	r.o = p;
	r.d = d;
	return r;
}



////////////////////////////////////////////////////////////
// LUT functions
////////////////////////////////////////////////////////////



// Transmittance LUT function parameterisation from Bruneton 2017 https://github.com/ebruneton/precomputed_atmospheric_scattering
// uv in [0,1]
// viewZenithCosAngle in [-1,1]
// viewHeight in [bottomRAdius, topRadius]

// We should precompute those terms from resolutions (Or set resolution as #defined constants)
float fromUnitToSubUvs(float u, float resolution) { return (u + 0.5f / resolution) * (resolution / (resolution + 1.0f)); }
float fromSubUvsToUnit(float u, float resolution) { return (u - 0.5f / resolution) * (resolution / (resolution - 1.0f)); }

float2 fromUnitToSubUvs(float2 u, float2 resolution)
{
	return float2(fromUnitToSubUvs(u.x, resolution.x), fromUnitToSubUvs(u.y, resolution.y));
}

void UvToLutTransmittanceParams(AtmosphereParameters Atmosphere, out float viewHeight, out float viewZenithCosAngle, in float2 uv)
{
	//uv = float2(fromSubUvsToUnit(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromSubUvsToUnit(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
	float x_mu = uv.x;
	float x_r = uv.y;

	float H = sqrt(Atmosphere.TopRadius * Atmosphere.TopRadius - Atmosphere.BottomRadius * Atmosphere.BottomRadius);
	float rho = H * x_r;
	viewHeight = sqrt(rho * rho + Atmosphere.BottomRadius * Atmosphere.BottomRadius);

	float d_min = Atmosphere.TopRadius - viewHeight;
	float d_max = rho + H;
	float d = d_min + x_mu * (d_max - d_min);
	viewZenithCosAngle = d == 0.0 ? 1.0f : (H * H - rho * rho - d * d) / (2.0 * viewHeight * d);
	viewZenithCosAngle = clamp(viewZenithCosAngle, -1.0, 1.0);
}

#define NONLINEARSKYVIEWLUT 1

void UvToSkyViewLutParams(AtmosphereParameters Atmosphere, out float3 ViewDir, in float ViewHeight, in float2 UV)
{
	// Constrain uvs to valid sub texel range (avoid zenith derivative issue making LUT usage visible)
	UV.x = fromSubUvsToUnit(UV.x, 96.0f);
	UV.y = fromSubUvsToUnit(UV.y, 104.0f);

	float Vhorizon = sqrt(ViewHeight * ViewHeight - Atmosphere.BottomRadius * Atmosphere.BottomRadius);
	float CosBeta = Vhorizon / ViewHeight;				// cos of zenith angle from horizon to zeniht
	float Beta = acos(CosBeta);
	float ZenithHorizonAngle = PI - Beta;

	float ViewZenithAngle;
	if (UV.y < 0.5f)
	{
		float Coord = 2.0f * UV.y;
		Coord = 1.0f - Coord;
		Coord *= Coord;
		Coord = 1.0f - Coord;
		ViewZenithAngle = ZenithHorizonAngle * Coord;
	}
	else
	{
		float Coord = UV.y * 2.0f - 1.0f;
		Coord *= Coord;
		ViewZenithAngle = ZenithHorizonAngle + Beta * Coord;
	}
	float CosViewZenithAngle = cos(ViewZenithAngle);
	float SinViewZenithAngle = sqrt(1.0 - CosViewZenithAngle * CosViewZenithAngle) * (ViewZenithAngle > 0.0f ? 1.0f : -1.0f); // Equivalent to sin(ViewZenithAngle)

	float LongitudeViewCosAngle = UV.x * 2.0f * PI;

	// Make sure those values are in range as it could disrupt other math done later such as sqrt(1.0-c*c)
	float CosLongitudeViewCosAngle = cos(LongitudeViewCosAngle);
	float SinLongitudeViewCosAngle = sqrt(1.0 - CosLongitudeViewCosAngle * CosLongitudeViewCosAngle) * (LongitudeViewCosAngle <= PI ? 1.0f : -1.0f); // Equivalent to sin(LongitudeViewCosAngle)
	ViewDir = float3(
		SinViewZenithAngle * CosLongitudeViewCosAngle,
		SinViewZenithAngle * SinLongitudeViewCosAngle,
		CosViewZenithAngle
		);
}

void SkyViewLutParamsToUv(
	in float IntersectGround, in float ViewZenithCosAngle, in float3 ViewDir, in float ViewHeight, in float BottomRadius, in float2 SkyViewLutSizeAndInvSize,
	out float2 UV)
{
	float Vhorizon = sqrt(ViewHeight * ViewHeight - BottomRadius * BottomRadius);
	float CosBeta = Vhorizon / ViewHeight;				// GroundToHorizonCos
	float Beta = acosFast4(CosBeta);
	float ZenithHorizonAngle = PI - Beta;
	float ViewZenithAngle = acosFast4(ViewZenithCosAngle);

	if (IntersectGround >= 0)
	{
		float Coord = ViewZenithAngle / ZenithHorizonAngle;
		Coord = 1.0f - Coord;
		Coord = sqrt(Coord);
		Coord = 1.0f - Coord;
		UV.y = Coord * 0.5f;
	}
	else
	{
		float Coord = (ViewZenithAngle - ZenithHorizonAngle) / Beta;
		Coord = sqrt(Coord);
		UV.y = Coord * 0.5f + 0.5f;
	}

	{
		UV.x = (atan2Fast(-ViewDir.y, -ViewDir.x) + PI) / (2.0f * PI);
	}

	// Constrain uvs to valid sub texel range (avoid zenith derivative issue making LUT usage visible)
	UV = fromUnitToSubUvs(UV, SkyViewLutSizeAndInvSize);
}

////////////////////////////////////////////////////////////
// Participating media
////////////////////////////////////////////////////////////



float getAlbedo(float scattering, float extinction)
{
	return scattering / max(0.001, extinction);
}
float3 getAlbedo(float3 scattering, float3 extinction)
{
	return scattering / max(0.001, extinction);
}


struct MediumSampleRGB
{
	float3 scattering;
	float3 absorption;
	float3 extinction;

	float3 scatteringMie;
	float3 absorptionMie;
	float3 extinctionMie;

	float3 scatteringRay;
	float3 absorptionRay;
	float3 extinctionRay;

	float3 scatteringOzo;
	float3 absorptionOzo;
	float3 extinctionOzo;

	float3 albedo;
};

MediumSampleRGB sampleMediumRGB(in float3 WorldPos, in AtmosphereParameters Atmosphere)
{
	float viewHeight = length(WorldPos) - Atmosphere.BottomRadius;
	viewHeight = max(viewHeight, 0);
	
	float mieStart = max(viewHeight - Atmosphere.MieFadeBegin, 0);

	const float densityMie = exp(Atmosphere.MieDensityExpScale * mieStart);
	const float densityRay = exp(Atmosphere.RayleighDensityExpScale * viewHeight);
	const float densityOzo = saturate(viewHeight < Atmosphere.AbsorptionDensity0LayerWidth ?
		Atmosphere.AbsorptionDensity0LinearTerm * viewHeight + Atmosphere.AbsorptionDensity0ConstantTerm :
		Atmosphere.AbsorptionDensity1LinearTerm * viewHeight + Atmosphere.AbsorptionDensity1ConstantTerm);

	MediumSampleRGB s;

	s.scatteringMie = densityMie * Atmosphere.MieScattering;
	s.absorptionMie = densityMie * Atmosphere.MieAbsorption;
	s.extinctionMie = densityMie * Atmosphere.MieExtinction;

	s.scatteringRay = densityRay * Atmosphere.RayleighScattering;
	s.absorptionRay = 0.0f;
	s.extinctionRay = s.scatteringRay + s.absorptionRay;

	s.scatteringOzo = 0.0;
	s.absorptionOzo = densityOzo * Atmosphere.AbsorptionExtinction;
	s.extinctionOzo = s.scatteringOzo + s.absorptionOzo;

	s.scattering = s.scatteringMie + s.scatteringRay + s.scatteringOzo;
	s.absorption = s.absorptionMie + s.absorptionRay + s.absorptionOzo;
	s.extinction = s.extinctionMie + s.extinctionRay + s.extinctionOzo;
	s.albedo = getAlbedo(s.scattering, s.extinction);

	return s;
}



////////////////////////////////////////////////////////////
// Sampling functions
////////////////////////////////////////////////////////////



// Generates a uniform distribution of directions over a sphere.
// Random zetaX and zetaY values must be in [0, 1].
// Top and bottom sphere pole (+-zenith) are along the Y axis.
float3 getUniformSphereSample(float zetaX, float zetaY)
{
	float phi = 2.0f * 3.14159f * zetaX;
	float theta = 2.0f * acos(sqrt(1.0f - zetaY));
	float3 dir = float3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi));
	return dir;
}

// Generate a sample (using importance sampling) along an infinitely long path with a given constant extinction.
// Zeta is a random number in [0,1]
float infiniteTransmittanceIS(float extinction, float zeta)
{
	return -log(1.0f - zeta) / extinction;
}
// Normalized PDF from a sample on an infinitely long path according to transmittance and extinction.
float infiniteTransmittancePDF(float extinction, float transmittance)
{
	return extinction * transmittance;
}

// Same as above but a sample is generated constrained within a range t,
// where transmittance = exp(-extinction*t) over that range.
float rangedTransmittanceIS(float extinction, float transmittance, float zeta)
{
	return -log(1.0f - zeta * (1.0f - transmittance)) / extinction;
}

float RayleighPhase(float cosTheta)
{
	// float factor = 3.0f / (16.0f * PI);
	float factor = 0.0596830994f;
	return factor * (1.0f + cosTheta * cosTheta);
}

float CornetteShanksMiePhaseFunction(float g, float cosTheta)
{
	float k = 3.0 / (8.0 * PI) * (1.0 - g * g) / (2.0 + g * g);
	return k * (1.0 + cosTheta * cosTheta) / pow(1.0 + g * g - 2.0 * g * -cosTheta, 1.5);
}

float hgPhase(float g, float cosTheta)
{
#ifdef USE_CornetteShanks
	return CornetteShanksMiePhaseFunction(g, cosTheta);
#else
	// Reference implementation (i.e. not schlick approximation). 
	// See http://www.pbr-book.org/3ed-2018/Volume_Scattering/Phase_Functions.html
	float numer = 1.0f - g * g;
	float denom = 1.0f + g * g + 2.0f * g * cosTheta;
	return numer / (4.0f * PI * denom * sqrt(denom));
#endif
}

float hgPhaseSimple(float g, float k, float cosTheta)
{
	return k * (1.0 + cosTheta * cosTheta) / pow(1.0 + g * g - 2.0 * g * -cosTheta, 1.5);
}

float dualLobPhase(float g0, float g1, float w, float cosTheta)
{
	return lerp(hgPhase(g0, cosTheta), hgPhase(g1, cosTheta), w);
}

float uniformPhase()
{
	return 1.0f / (4.0f * PI);
}



////////////////////////////////////////////////////////////
// Misc functions
////////////////////////////////////////////////////////////



// From http://jcgt.org/published/0006/01/01/
void CreateOrthonormalBasis(in float3 n, out float3 b1, out float3 b2)
{
	float sign = n.z >= 0.0f ? 1.0f : -1.0f; // copysignf(1.0f, n.z);
	const float a = -1.0f / (sign + n.z);
	const float b = n.x * n.y * a;
	b1 = float3(1.0f + sign * n.x * n.x * a, sign * b, -sign * n.x);
	b2 = float3(b, sign + n.y * n.y * a, -n.y);
}

float mean(float3 v)
{
	return dot(v, float3(1.0f / 3.0f, 1.0f / 3.0f, 1.0f / 3.0f));
}

float whangHashNoise(uint u, uint v, uint s)
{
	uint seed = (u * 1664525u + v) + s;
	seed = (seed ^ 61u) ^ (seed >> 16u);
	seed *= 9u;
	seed = seed ^ (seed >> 4u);
	seed *= uint(0x27d4eb2d);
	seed = seed ^ (seed >> 15u);
	float value = float(seed) / (4294967296.0);
	return value;
}

bool MoveToTopAtmosphere(inout float3 WorldPos, in float3 WorldDir, in float AtmosphereTopRadius)
{
	float viewHeight = length(WorldPos);
	if (viewHeight > AtmosphereTopRadius)
	{
		float tTop = raySphereIntersectNearest(WorldPos, WorldDir, float3(0.0f, 0.0f, 0.0f), AtmosphereTopRadius);
		if (tTop >= 0.0f)
		{
			float3 UpVector = WorldPos / viewHeight;
			float3 UpOffset = UpVector * -PLANET_RADIUS_OFFSET;
			WorldPos = WorldPos + WorldDir * tTop + UpOffset;
		}
		else
		{
			// Ray is not intersecting the atmosphere
			return false;
		}
	}
	return true; // ok to start tracing
}

float3 GetSunLuminance(float3 WorldPos, float3 WorldDir, float3 sunDir, float PlanetRadius)
{
#if RENDER_SUN_DISK
	if (dot(WorldDir, sunDir) > cos(0.5*1.505*3.14159 / 180.0))
	{
		float t = raySphereIntersectNearest(WorldPos, WorldDir, float3(0.0f, 0.0f, 0.0f), PlanetRadius);
		if (t < 0.0f) // no intersection
		{
			const float3 SunLuminance = 1000000.0; // arbitrary. But fine, not use when comparing the models
			return SunLuminance * 1;
		}
	}
#endif
	return 0;
}

float3 GetMultipleScattering(AtmosphereParameters Atmosphere, float3 scattering, float3 extinction, float3 worlPos, float viewZenithCosAngle)
{
	float2 uv = saturate(float2(viewZenithCosAngle*0.5f + 0.5f, (length(worlPos) - Atmosphere.BottomRadius) / (Atmosphere.TopRadius - Atmosphere.BottomRadius)));
	uv = float2(fromUnitToSubUvs(uv.x, MultiScatteringLUTRes), fromUnitToSubUvs(uv.y, MultiScatteringLUTRes));

	float3 multiScatteredLuminance = MultiScatTexture.SampleLevel(samplerLinearClamp, uv, 0).rgb;
	return multiScatteredLuminance;
}