struct VoronoiResult
{
	float borderDist;
	vec2 nearestPointDir;
};

const float PI = 3.14159265359;
const float TWOPI = 2.0 * PI;
const float LARGENUM = 1000000.0;

vec2 getPoints( vec2 p )
{    
    float xValue = 0.5*step(0.5,fract(p.y / 2.0));
	return vec2(xValue, 0.0);
}

VoronoiResult voronoi( in vec2 pos )
{
	//Zerrung für Hexgrid
	pos*=vec2(1.0, 1.0/sqrt(0.75));
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
			pointDirection *= vec2 ( 1.0, sqrt(0.75));
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
			r*=vec2(1.0, sqrt(0.75));

			if( dot(nearestPointDir-r,nearestPointDir-r)>0.00001 )
			{
				borderDist = min( borderDist, dot( 0.5*(nearestPointDir+r), normalize(r-nearestPointDir) ) );
			}
		}
	}

    return VoronoiResult( borderDist, nearestPointDir );
}

float hexagonDistance(in vec2 pos){
	float r = length(pos); // radius of current pixel
    float a = atan(pos.y, pos.x) + PI; //angel of current pixel [0..2*PI] 
	
	float fact = TWOPI/6.0;
	return cos(a - floor(0.5 + a / fact) * fact) * r;
}