#version 330

#include "../libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D iChannel0;
uniform float amplitude;

//----------------------
// Constants
const float PI = 3.14159;
const float SCALE = 1.0;
const float MAX_DIST = 1000.0;
const float X_REPEAT_DIST = 0.90*SCALE;
const float Z_REPEAT_DIST = 1.05*SCALE;
const float PRIM_HEIGHT    = 1.0;
const float HEX_HALF_WIDTH = 0.25*SCALE;

float fDEBUG = 0.1;

struct repeatInfo
{
    vec3 smpl; //object-space, cyclic
    vec3 anchor; //world space
};

vec3 RepeatHex(vec3 p)
{
    //Repetition
    float xRepeatDist = X_REPEAT_DIST;
    float zRepeatDist = Z_REPEAT_DIST*0.5;
    p.x = (fract(p.x/xRepeatDist+0.5)-0.5)*xRepeatDist;
    p.z = (fract(p.z/zRepeatDist+0.5)-0.5)*zRepeatDist;
    
    return p;
}

#define normalized_wave(a) (0.5*a+0.5)
float CalculateHeight(vec3 p)
{
    //Repetition
    float xRepeatDist = X_REPEAT_DIST;
    float zRepeatDist = Z_REPEAT_DIST*0.5;
    float latticeX = (fract(p.x/xRepeatDist+0.5)-0.5)*xRepeatDist;
    float latticeY = (fract(p.z/zRepeatDist+0.5)-0.5)*zRepeatDist;
    vec2 anchorPosXZ = p.xz-vec2(latticeX,latticeY);
    
    //Variation
    float period = fract(iGlobalTime/30.)*3.0;
    float theta = period*2.0*PI;
    float overallAmplitude = amplitude; //Overall amplitude modulation
    float waveAmplitude = normalized_wave(sin(anchorPosXZ.x+anchorPosXZ.y+theta*4.0));
    float primHeight = overallAmplitude*waveAmplitude;
    
    return primHeight;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}
    
//The distance field composition.
//::DF_composition
float DF_composition( in vec3 pos )
{
	pos.y = -abs(pos.y);
	vec3 repeat = RepeatHex(pos - vec3(0.0));
	float height = CalculateHeight(pos - vec3(0.0))-5.98;
    float distA = sdHexPrism( repeat.xzy-vec3(0,0,height),
	                         vec2(HEX_HALF_WIDTH, PRIM_HEIGHT) );
    
	repeat = RepeatHex(pos-vec3(X_REPEAT_DIST*0.5,0, Z_REPEAT_DIST*0.25));
	height = CalculateHeight(pos-vec3(X_REPEAT_DIST*0.5,0, Z_REPEAT_DIST*0.25))-5.98;
    float distB = sdHexPrism( repeat.xzy-vec3(0,0,height),
	                         vec2(HEX_HALF_WIDTH, PRIM_HEIGHT) );
    
    if(distA<distB)
        return distA;
    else
        return distB;
}

//The distance field gradient
vec3 DF_gradient( in vec3 p )
{
    //The field gradient is the distance derivative along each axis.
    //The surface normal follows the direction where this variation is strongest.
	const float d = 0.001;
	vec3 grad = vec3(DF_composition(p+vec3(d,0,0))-DF_composition(p-vec3(d,0,0)),
                     DF_composition(p+vec3(0,d,0))-DF_composition(p-vec3(0,d,0)),
                     DF_composition(p+vec3(0,0,d))-DF_composition(p-vec3(0,0,d)));
	return grad/(2.0*d);
}

//o = ray origin, d = direction, t = distance travelled along ray, starting from origin
float Raymarch( vec3 o, vec3 d)
{
    const float tolerance = 0.0001;
    float t = 0.0;
    float dist = MAX_DIST;

    for( int i=0; i<70; i++ )
    {
        dist = DF_composition( o+d*t );
        
        if( abs(dist)<tolerance ){
			break;
		}
        t += dist;
    }
    
    return t;
}

vec3 ambientDiffuse(vec3 material, vec3 normal)
{
	vec3 ambient = vec3(0);

	vec3 lightDir = normalize(vec3(1, -1, 1));
	vec3 toLight = -lightDir;
	float diffuse = max(0, dot(toLight, normal));
	
	return ambient + diffuse * material;
}

float calcAO(vec3 pos, vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/3.0;
        vec3 aopos =  nor * hr + pos;
        float dd = DF_composition(aopos);
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 TRACE_main( vec3 o, vec3 dir, vec2 uv)
{ 
    float rayLen = Raymarch(o, dir);
    vec3 dfHitPosition = o+rayLen*dir;
	
    vec3 normal = normalize(DF_gradient(dfHitPosition));
    
	vec3 color = vec3(0,1-calcAO(dfHitPosition, normal),0);
	color = mix(color, vec3(0),rayLen/30);
	
	color = mix(color,ambientDiffuse(vec3(.5),normal),0.1 );
	//color = ambientDiffuse(vec3(1),normal);
	
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    
    vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
    vec3 c = TRACE_main(camP, camDir, uv);
    
    fragColor = vec4(c,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}

