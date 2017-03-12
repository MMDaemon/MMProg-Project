#version 330

#include "../libs/camera.glsl"
#include "../libs/operators.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

const float epsilon = 0.0001;
const int maxSteps = 512;
const float miss = -10000;

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float distField(vec3 point)
{
	float height = .42;
    float depth = .75;
    float t = 0.02;
    point.z = mod(point.z,depth*2.)-0.5*depth*2.;

   	float cyl = sdHexPrism( point, vec2(height-t, depth+t));
   	float scyl = sdHexPrism( point, vec2(height-t*2.0, depth+t+.001));
    
    return opS(scyl,cyl);

}

float sphereTracing(vec3 O, vec3 dir, float minT, float maxT, int maxSteps)
{
	float t = minT;
	//step along the ray 
    for(int steps = 0; (steps < maxSteps) && (t < maxT); ++steps)
    {
		//calculate new point
		vec3 point = O + t * dir;
		//check how far the point is from the nearest surface
        float dist = distField(point);
		//if we are very close
        if(epsilon > dist)
        {
			return t;
            break;
        }
		//screen error decreases with distance
		// dist = max(dist, t * 0.001);
		//not so close -> we can step at least dist without hitting anything
		t += dist;
    }
	return miss;
}

vec3 ambientDiffuse(vec3 material, vec3 normal)
{
	vec3 ambient = vec3(0);

	vec3 lightDir = normalize(vec3(1, -1, 1));
	vec3 toLight = -lightDir;
	float diffuse = max(0, dot(toLight, normal));
	
	return ambient + diffuse * material;
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = distField(aopos);
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

void main()
{
	vec3 camP = calcCameraPos();
	camP.z += iGlobalTime*2;
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);

	float maxT = 100;
	//start point is the camera position
	float t = sphereTracing(camP, camDir, 0, maxT, maxSteps);
	
	vec3 color = vec3(0);
	if(0 < t)
	{
		vec3 point = camP + t * camDir;
		vec3 normal = getNormal(point, 0.01);
		
		//// Ambient lighting
		//color = ambientDiffuse(vec3(1.0),normal);
		
		// AmbientOcclusion lighting
		color = vec3(0,1-calcAO(point, normal),0);
		color = mix(color, vec3(0),t/30);
	}
	gl_FragColor = vec4(color, 1);
}