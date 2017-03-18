#version 330

uniform float iGlobalTime;
uniform vec2 iResolution;

#include "../libs/camera.glsl"
#include "3dHexgridRaymarch.glsl"
#include "PointsToSpheresCall.glsl"

void main()
{
	pointsToSpheres(gl_FragColor, gl_FragCoord.xy); 
}
