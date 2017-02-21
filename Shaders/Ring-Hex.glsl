uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D texLastFrame;
uniform float frequency;

struct VoronoiResult
{
	float borderDist;
	vec2 nearestPointDir;
};

const float LARGENUM = 1000000;

vec2 getPoints( vec2 p )
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
			vec2 pointInSquarePos = getPoints( squarePos + squareOffset );
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
			vec2 pointInSquarePos = getPoints( squarePos + squareOffset );
			vec2 r = squareOffset + pointInSquarePos - posInSquare;

			if( dot(nearestPointDir-r,nearestPointDir-r)>0.00001 )
			{
				borderDist = min( borderDist, dot( 0.5*(nearestPointDir+r), normalize(r-nearestPointDir) ) );
			}
		}
	}

    return VoronoiResult( borderDist, nearestPointDir );
}

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
