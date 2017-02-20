// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// I've not seen anybody out there computing correct cell interior distances for Voronoi
// patterns yet. That's why they cannot shade the cell interior correctly, and why you've
// never seen cell boundaries rendered correctly. 

// However, here's how you do mathematically correct distances (note the equidistant and non
// degenerated grey isolines inside the cells) and hence edges (in yellow):

// http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D texLastFrame;
uniform float speed;

struct VoronoiResult
{
	float borderDist;
	vec2 nearestPointDir;
};

const float LARGENUM = 1000000;

const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;

float rand(float seed)
{
	return fract(sin(seed) * 1231534.9);
}

float rand(vec2 seed) { 
    return rand(dot(seed, vec2(12.9898, 783.233)));
}

vec2 rand2(vec2 seed)
{
	float r = rand(seed) * TWOPI;
	return vec2(cos(r), sin(r));
}

float gnoise(vec2 coord)
{
	vec2 i = floor(coord); // integer position

	//random gradient at nearest integer positions
	vec2 g00 = rand2(i);
	vec2 g10 = rand2(i + vec2(1, 0));
	vec2 g01 = rand2(i + vec2(0, 1));
	vec2 g11 = rand2(i + vec2(1, 1));

	vec2 f = fract(coord);
	float v00 = dot(g00, f);
	float v10 = dot(g10, f - vec2(1, 0));
	float v01 = dot(g01, f - vec2(0, 1));
	float v11 = dot(g11, f - vec2(1, 1));

	vec2 weight = f; // linear interpolation
	weight = smoothstep(0, 1, f); // cubic interpolation

	float x1 = mix(v00, v10, weight.x);
	float x2 = mix(v01, v11, weight.x);
	return mix(x1, x2, weight.y) + 0.5;
}

vec2 hash2( vec2 p )
{    
    float xValue = 0.5*step(0.5,fract(p.y / 2.0));
	return vec2(xValue, 0);
}

VoronoiResult voronoi( in vec2 pos )
{
	//Zerrung für Hexgrid
	pos*=vec2(1, sqrt(2));
    vec2 squarePos = floor(pos);
    vec2 posInSquare = fract(pos);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
	vec2 mg, nearestPointDir;

    float borderDist = LARGENUM;
    for( int j=-1; j<=1; j++ )
	{
		for( int i=-1; i<=1; i++ )
		{
			vec2 squareOffset = vec2(float(i),float(j));
			vec2 pointInSquarePos = hash2( squarePos + squareOffset );
			vec2 pointDirection = squareOffset + pointInSquarePos - posInSquare;
			float dist = dot(pointDirection,pointDirection);

			if( dist<borderDist )
			{
				borderDist = dist;
				nearestPointDir = pointDirection;
				mg = squareOffset;
			}
		}
	}

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    borderDist = LARGENUM;
    for( int j=-2; j<=2; j++ )
	{
		for( int i=-2; i<=2; i++ )
		{
			vec2 squareOffset = mg + vec2(float(i),float(j));
			vec2 pointInSquarePos = hash2( squarePos + squareOffset );
			vec2 r = squareOffset + pointInSquarePos - posInSquare;

			if( dot(nearestPointDir-r,nearestPointDir-r)>0.00001 )
			{
				borderDist = min( borderDist, dot( 0.5*(nearestPointDir+r), normalize(r-nearestPointDir) ) );
			}
		}
	}

    return VoronoiResult( borderDist, nearestPointDir );
}

vec3 Ring(vec2 pos)
{
	float aspect = iResolution.y/iResolution.x;
	pos = (pos-vec2(0.5,0.5*aspect))*2;
	float radius = fract(iGlobalTime*speed)*2;
	float dist = length(pos);
	float intensity = 1-smoothstep(radius,radius+0.01, dist);
	intensity -= (1-smoothstep(radius-0.11, radius-0.1, dist));
	vec3 color = vec3(0.0,intensity,0.0);
	if(speed >= 1.427)
	color = vec3(0.0,1.0,0.0);
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord.xy/iResolution.xx;

    VoronoiResult voronoiResult = voronoi( 16.0*p );


	
    // borders	
	vec3 color = gnoise(vec2(30*p+iGlobalTime*2))*vec3(1.0, 0.7, 1.0)+gnoise(vec2(10*p-iGlobalTime*3))*vec3(1.0, 0.7, 1.0)+gnoise(vec2(3*p+iGlobalTime*.5))*vec3(1.0, 0.7, 1.0);
    color = vec3(1)-min(max(color,0),1);
	color = Ring(p);
	vec3 col = mix(color, vec3(0.0), smoothstep( 0.00, 0.04, voronoiResult.borderDist ) );
	
	//ghosting
	vec2 uv = fragCoord.xy/iResolution.xy;
	
	col += 0.95 * texture2D(texLastFrame, uv).rgb;
	col -= 1.0 / 256.0; //dim over time to avoid leftovers
	col = clamp(col, vec3(0), vec3(1));
	fragColor = vec4(col,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
