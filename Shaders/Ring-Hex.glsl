#include "HexagonDistField.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D texLastFrame;
uniform float frequency;

vec3 Rings(vec2 pos)
{
	float aspect = iResolution.y/iResolution.x;
	pos = (pos-vec2(0.5,0.5*aspect))*2;
	
	
	float dist = fract(frequency*(length(pos)-iGlobalTime))-0.5;
	float intensity = 1-smoothstep(0.5, 0.5+0.01*frequency, dist);
	intensity -= (1-smoothstep(0.5-0.11*frequency, 0.5-0.1*frequency, dist));
	vec3 color = vec3(0.0,intensity,0.0);
	if(frequency >= 5){
		color = vec3(0.0,1.0,0.0);
	}
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/iResolution.xx;

    VoronoiResult voronoiResult = voronoi( 16.0*pos );
	
    // borders	
	vec3 color = mix(Rings(pos), vec3(0.0), smoothstep( 0.00, 0.04, voronoiResult.borderDist ) );
	
	//ghosting
	vec2 uv = fragCoord.xy/iResolution.xy;
	
	color += 0.6 * texture2D(texLastFrame, uv).rgb;
	color -= 1.0 / 256.0; //dim over time to avoid leftovers
	color = clamp(color, vec3(0), vec3(1));
	
	fragColor = vec4(color,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
