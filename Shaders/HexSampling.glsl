#include "HexagonDistField.glsl"
#include "../libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float hexagonize;

#include "3dHexgridRaymarch.glsl"
#include "PointsToSpheresCall.glsl"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord/iResolution.xy;
	float aspect = iResolution.y/iResolution.x; 
	pos = (2.0*pos-vec2(1.0, 1.0)) * vec2(1.0, aspect);

    // HexSampling	
	float zoom = (1-hexagonize)*248+8.0;
	pos *= zoom;
	VoronoiResult voronoiResult = voronoi( pos );
	
	vec2 centerPos = (pos + voronoiResult.nearestPointDir)/zoom;
	vec2 uvCenterPos = (centerPos / vec2(1.0, aspect) + vec2(1.0, 1.0))/2;
	vec4 traceColor;
	
	pointsToSpheres(traceColor, uvCenterPos*iResolution.xy); 
	
	vec3 color = mix(traceColor.rgb, vec3(0.0),max(0.0,10*(hexagonize-0.9)));
	color = mix(vec3(0.0, 1.0, 0.0), color, 1-hexagonize*(1-smoothstep( 0.0, 0.04, voronoiResult.borderDist )) );
	
	fragColor = vec4(color, 1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}