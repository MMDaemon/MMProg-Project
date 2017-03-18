#include "HexagonDistField.glsl"

uniform vec2 iResolution;
uniform float dist;
uniform float zoom;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/iResolution.xy;
	float aspect = iResolution.y/iResolution.x;
	pos += vec2(-0.005,0.09)*zoom;
	pos *= 1+((vec2(sqrt(0.66),1)-1)*zoom);
	pos = (2*(pos)-vec2(1.0,1.0)) * vec2(1,aspect);

    VoronoiResult voronoiResult = voronoi( (8-zoom*2.9)*pos );
	
    // borders	
	vec3 color = mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist, dist + 0.04, voronoiResult.borderDist ) );
	color -= mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( dist - 0.04, dist , voronoiResult.borderDist ) );
	
	if(dist>0.4){
		dist = 0.5-dist+(zoom*0.145);
		vec3 pointColor = mix(vec3(0.0,1.0,0.0), vec3(1.0), zoom);
		color = mix(pointColor, vec3(0.0), smoothstep( dist, dist + 0.04*(1-zoom), length(voronoiResult.nearestPointDir/vec2(1, 1/sqrt(0.66))) ) );
	}
	
	fragColor = vec4(color,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}



