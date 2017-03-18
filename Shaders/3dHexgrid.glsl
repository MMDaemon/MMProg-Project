#version 330

uniform vec2 iResolution;

#include "../libs/camera.glsl"
#include "3dHexgridRaymarch.glsl"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    
    vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
    vec3 c = TRACE_main(camP, camDir);
    
    fragColor = vec4(c,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy); 
}

