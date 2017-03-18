#include "HexagonDistField.glsl"

uniform vec2 iResolution;
uniform sampler2D texLastFrame;
uniform float waveTime;
uniform float frequency;

vec3 Rings(vec2 pos)
{
	float dist = fract(frequency*(length(pos)-waveTime*10))-0.5;
	float intensity = 1.0 -smoothstep(0.5, 0.5+0.01*frequency, dist);
	intensity -= (1.0 -smoothstep(0.5-0.11*frequency, 0.5-0.1*frequency, dist));
	vec3 color = vec3(0.0, intensity,0.0);
	if(frequency >= 5.0){
		color = vec3(0.0,1.0,0.0);
	}
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/iResolution.xy;
	float aspect = iResolution.y/iResolution.x; 
	pos = (2.0*pos-vec2(1.0, 1.0)) * vec2(1.0, aspect);

    
	
    // Hexgrid	
	VoronoiResult voronoiResult = voronoi( 8.0*pos );
	vec3 color = mix(Rings(pos), vec3(0.0), smoothstep( 0.00, 0.04, voronoiResult.borderDist ) );
	
	// center Hexagon
	
	float centerHexDist = hexagonDistance( 16.0*pos );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	centerHexBorder += 1.0-smoothstep( 0.95, 0.99, centerHexDist );
	color= mix(vec3(0.0, 1.0, 0.0), color, centerHexBorder );
	
	//ghosting
	float intensity = 0.2 - max(0.0,frequency-4.8);
	vec2 uv = fragCoord.xy/iResolution.xy;
	//color += intensity * 0.6 * texture2D(texLastFrame, uv).rgb;
	//color -= 1.0 / 256.0; //dim over time to avoid leftovers
	//color = clamp(color, vec3(0.0), vec3(1.0));
	
	fragColor = vec4(color, 1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
