#include "HexagonDistField.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float dist;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/iResolution.xy;
	float aspect = iResolution.y/iResolution.x;
	pos = (2*pos-vec2(1.0,1.0)) * vec2(1,aspect);

    VoronoiResult voronoiResult = voronoi( 8.0*pos );
	
    // borders	
	vec3 color = mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist, dist + 0.04, voronoiResult.borderDist ) );
	color -= mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist - 0.04, dist , voronoiResult.borderDist ) );
	
	if(dist>0.4){
		dist = 0.5-dist;
	
		color = mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist, dist + 0.04, length(voronoiResult.nearestPointDir/vec2(1, sqrt(2))) ) );
		//color -= mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist - 0.04, dist , length(voronoiResult.nearestPointDir/vec2(1, sqrt(2))) ) );
	}
	
	fragColor = vec4(color,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}



