uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float dist;

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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/iResolution.xx;

    VoronoiResult voronoiResult = voronoi( 16.0*pos );
	
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



