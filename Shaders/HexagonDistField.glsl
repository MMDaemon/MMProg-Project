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