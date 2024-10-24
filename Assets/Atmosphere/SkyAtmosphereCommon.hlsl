// Copyright Epic Games, Inc. All Rights Reserved.

#include "./FastMathThirdParty.hlsl"

#define UNIFORM_PHASE 0.079577472f    // 1.0 / (4.0 * PI)
#define BOTTOM_RADIUS_SQR 40449600
#define TOP_RADIUS_SQR 41216400

SamplerState samplerLinearClamp : register(s0);

// MUST match SKYATMOSPHERE_BUFFER in SkyAtmosphereBruneton.hlsl
cbuffer SKYATMOSPHERE_BUFFER : register(b1)
{
	//
	// From AtmosphereData
	//

	// Radius of the planet (center to ground)
	float BottomRadius;
	// Maximum considered atmosphere height (center to atmosphere top)
	float TopRadius;

	// Rayleigh scattering exponential distribution scale in the atmosphere
	float RayleighDensityExpScale;
	// Rayleigh scattering coefficients
	float3 RayleighScattering;

	float MieFadeBegin;
	float MieDensity;
	float RayleighDensity;

	// Mie scattering exponential distribution scale in the atmosphere
	float MieDensityExpScale;
	// Mie scattering coefficients
	float3 MieScattering;
	// Mie extinction coefficients
	float3 MieExtinction;
	// Mie absorption coefficients
	float3 MieAbsorption;
	// Mie phase function excentricity
	float MiePhaseG;	//mie_phase_function_g

	// Another medium type in the atmosphere
	float AbsorptionDensity0LayerWidth;
	float AbsorptionDensity0ConstantTerm;
	float AbsorptionDensity0LinearTerm;
	float AbsorptionDensity1ConstantTerm;
	float AbsorptionDensity1LinearTerm;
	// This other medium only absorb light, e.g. useful to represent ozone in the earth atmosphere
	float3 AbsorptionExtinction;		//absorption_extinction

	// The albedo of the ground.
	float3 GroundAlbedo;

	int TRANSMITTANCE_TEXTURE_WIDTH;
	int TRANSMITTANCE_TEXTURE_HEIGHT;
	int IRRADIANCE_TEXTURE_WIDTH;
	int IRRADIANCE_TEXTURE_HEIGHT;

	int SCATTERING_TEXTURE_R_SIZE;
	int SCATTERING_TEXTURE_MU_SIZE;
	int SCATTERING_TEXTURE_MU_S_SIZE;
	int SCATTERING_TEXTURE_NU_SIZE;

	float4 CameraAerialPerspectiveVolumeParam;
	float4 CameraAerialPerspectiveVolumeParam2;
	float4 CameraAerialPerspectiveVolumeParam3;

	float4 AtmosParam;
	float4 AtmosParam1;
	float4 AtmosParam2; 
	
	//
	// Other globals
	//
	float4x4 gSkyInvViewMat;
	float4x4 gSkyInvProjMat;

	float3 gResolution;
	float4 gColor;
	float3 gSunIlluminance;
	int gScatteringMaxPathDepth;
	float3 RayMarchMinMaxSPP;

	float3 camera;	//CameraPos
	float3 sun_direction;
	float3 view_ray;

	float MultipleScatteringFactor;
	float MultiScatteringLUTRes;
};

struct AtmosphereParameters
{
	// Radius of the planet (center to ground)
	float BottomRadius;
	// Maximum considered atmosphere height (center to atmosphere top)
	float TopRadius;

	// Rayleigh scattering exponential distribution scale in the atmosphere
	float RayleighDensityExpScale;
	// Rayleigh scattering coefficients
	float3 RayleighScattering;

	float MieFadeBegin;
	float MieDensity;
	float RayleighDensity;

	// Mie scattering exponential distribution scale in the atmosphere
	float MieDensityExpScale;
	// Mie scattering coefficients
	float3 MieScattering;
	// Mie extinction coefficients
	float3 MieExtinction;
	// Mie absorption coefficients
	float3 MieAbsorption;
	// Mie phase function excentricity
	float MiePhaseG;

	// Another medium type in the atmosphere
	float AbsorptionDensity0LayerWidth;
	float AbsorptionDensity0ConstantTerm;
	float AbsorptionDensity0LinearTerm;
	float AbsorptionDensity1ConstantTerm;
	float AbsorptionDensity1LinearTerm;
	// This other medium only absorb light, e.g. useful to represent ozone in the earth atmosphere
	float3 AbsorptionExtinction;

	// The albedo of the ground.
	float3 GroundAlbedo;

	float3 OneIlluminance;
};

struct IntegrateScatteredParam
{
	bool MieRayPhase;
	float3 MiePhaseValue;
	float3 RayleighPhaseValue;
};

AtmosphereParameters GetAtmosphereParameters()
{
	AtmosphereParameters Parameters;
	Parameters.AbsorptionExtinction = AbsorptionExtinction;

	// Traslation from Bruneton2017 parameterisation.
	Parameters.RayleighDensityExpScale = RayleighDensityExpScale;
	Parameters.MieDensityExpScale = MieDensityExpScale;
	Parameters.MieFadeBegin = MieFadeBegin;
	Parameters.MieDensity = MieDensity;
	Parameters.RayleighDensity = RayleighDensity;

	Parameters.OneIlluminance = float3(1.0f, 1.0f, 1.0f);
	
	Parameters.AbsorptionDensity0LayerWidth = AbsorptionDensity0LayerWidth;
	Parameters.AbsorptionDensity0ConstantTerm = AbsorptionDensity0ConstantTerm;
	Parameters.AbsorptionDensity0LinearTerm = AbsorptionDensity0LinearTerm;
	Parameters.AbsorptionDensity1ConstantTerm = AbsorptionDensity1ConstantTerm;
	Parameters.AbsorptionDensity1LinearTerm = AbsorptionDensity1LinearTerm;

	Parameters.MiePhaseG = MiePhaseG;
	Parameters.RayleighScattering = RayleighScattering;
	Parameters.MieScattering = MieScattering;
	Parameters.MieAbsorption = MieAbsorption;
	Parameters.MieExtinction = MieExtinction;
	Parameters.GroundAlbedo = GroundAlbedo;
	Parameters.BottomRadius = BottomRadius;
	Parameters.TopRadius = TopRadius;
	return Parameters;
}

// - r0: ray origin
// - rd: normalized ray direction
// - s0: sphere center
// - sR: sphere radius
// - Returns distance from r0 to first intersecion with sphere,
//   or -1.0 if no intersection.
float raySphereIntersectNearest(float3 r0, float3 rd, float3 s0, float sR)
{
	float a = dot(rd, rd);
	float3 s0_r0 = r0 - s0;
	float b = 2.0 * dot(rd, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sR * sR);
	float delta = b * b - 4.0*a*c;
	if (delta < 0.0 || a == 0.0)
	{
		return -1.0;
	}
	float sol0 = (-b - sqrt(delta)) / (2.0*a);
	float sol1 = (-b + sqrt(delta)) / (2.0*a);
	if (sol0 < 0.0 && sol1 < 0.0)
	{
		return -1.0;
	}
	if (sol0 < 0.0)
	{
		return max(0.0, sol1);
	}
	else if (sol1 < 0.0)
	{
		return max(0.0, sol0);
	}
	return max(0.0, min(sol0, sol1));
}


// void LutTransmittanceParamsToUv(AtmosphereParameters Atmosphere, in float viewHeight, in float viewZenithCosAngle, out float2 uv)
// {
// 	float H = sqrt(max(0.0f, Atmosphere.TopRadius * Atmosphere.TopRadius - Atmosphere.BottomRadius * Atmosphere.BottomRadius));
// 	float rho = sqrt(max(0.0f, viewHeight * viewHeight - Atmosphere.BottomRadius * Atmosphere.BottomRadius));
//
// 	float discriminant = viewHeight * viewHeight * (viewZenithCosAngle * viewZenithCosAngle - 1.0) + Atmosphere.TopRadius * Atmosphere.TopRadius;
// 	float d = max(0.0, (-viewHeight * viewZenithCosAngle + sqrt(discriminant))); // Distance to atmosphere boundary
//
// 	float d_min = Atmosphere.TopRadius - viewHeight;
// 	float d_max = rho + H;
// 	float x_mu = (d - d_min) / (d_max - d_min);
// 	float x_r = rho / H;
//
// 	uv = float2(x_mu, x_r);
// 	//uv = float2(fromUnitToSubUvs(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromUnitToSubUvs(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
// }

void LutTransmittanceParamsToUv(AtmosphereParameters Atmosphere, in float viewHeight, in float viewZenithCosAngle, out float2 uv)
{
	// float H = sqrt(TOP_RADIUS_SQR - BOTTOM_RADIUS_SQR);
	float H = 875.671171f;
	float rho = sqrt(max(0.0f, viewHeight * viewHeight - BOTTOM_RADIUS_SQR));

	float discriminant = viewHeight * viewHeight * (viewZenithCosAngle * viewZenithCosAngle - 1.0) + TOP_RADIUS_SQR;
	float d = max(0.0, (-viewHeight * viewZenithCosAngle + sqrt(discriminant))); // Distance to atmosphere boundary

	float d_min = 6420 - viewHeight;
	float d_max = rho + H;
	float x_mu = (d - d_min) / (d_max - d_min);
	float x_r = rho / H;

	uv = float2(x_mu, x_r);
}