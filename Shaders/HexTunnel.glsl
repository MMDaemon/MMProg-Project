#version 330

#include "../libs/camera.glsl"
#include "../libs/operators.glsl"
#include "HexagonDistField.glsl"

uniform vec2 iResolution;
uniform float spherePos;
uniform float zoom;

const float epsilon = 0.0001;
const int maxSteps = 512;
const float miss = -10000;
const float bigNumber = 10000.0;
const float eps = 0.001;

float quad(float a)
{
	return a * a;
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float sphere(vec3 M, float r, vec3 O, vec3 d)
{
	vec3 MO = O - M;
	float root = quad(dot(d, MO))- quad(length(d)) * (quad(length(MO)) - quad(r));
	if(root < eps)
	{
		return -bigNumber;
	}
	float p = -dot(d, MO);
	float q = sqrt(root);
    return (p - q) > 0.0 ? p - q : p + q;
}

vec3 sphereNormal(vec3 M, vec3 P)
{
	return normalize(P - M);
}

float distField(vec3 point)
{
	float height = .42;
    float depth = .75;
    float t = 0.02;
	if(point.z<=90){
		point.z = mod(point.z,depth*2.)-0.5*depth*2.;
	}

   	float cyl = sdHexPrism( point, vec2(height-t, depth+t));
   	float scyl = sdHexPrism( point, vec2(height-t*2.0, depth+t+.001));
    
    return opS(scyl,cyl);
}

float sphereTracing(vec3 origin, vec3 dir, float minT, float maxT, int maxSteps)
{
	float t = minT;
	//step along the ray 
    for(int steps = 0; (steps < maxSteps) && (t < maxT); ++steps)
    {
		//calculate new point
		vec3 point = origin + t * dir;
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

struct Intersection
{
	bool exists;
	vec3 normal;
	vec3 intersectP;
};

Intersection rayCastScene(vec3 origin, vec3 dir)
{
	float t = bigNumber;
	vec3 M = vec3(-bigNumber);
	vec3 normal = vec3(0.0, 0.0, 0.0);
	vec3 newM = vec3(0, 0, spherePos);
	float newT = sphere(newM, 0.1, origin, dir);
	if (0.0 < newT && newT < t)
	{	
		t = newT;
		M = newM;
	}
	Intersection obj;
	obj.exists = t < bigNumber;
	if(obj.exists){
		obj.intersectP = origin + t * dir;
		obj.normal = sphereNormal(M, obj.intersectP);
	}
	return obj;
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
        float dd = distField(aopos);
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

void main()
{
	vec3 camP = calcCameraPos();

	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec2 pos = gl_FragCoord.xy/iResolution.xy;
	float aspect = iResolution.y/iResolution.x; 
	pos = (2.0*pos-vec2(1.0, 1.0)) * vec2(1.0, aspect);

	float maxT = 100;
	//start point is the camera position
	float sphereTraceDist = sphereTracing(camP, camDir, 0, maxT, maxSteps);
	
	// Hexgrid	
	VoronoiResult voronoiResult = voronoi( 8.0/(1+15*zoom*zoom*zoom*zoom)*pos );
	vec3 color = mix(vec3(0.0,1.0,0.0), vec3(0.0), smoothstep( 0.00, 0.04, voronoiResult.borderDist ) );
	
	vec3 tunnelColor = vec3(0.0);
	if(0 < sphereTraceDist)
	{
		vec3 point = camP + sphereTraceDist * camDir;
		vec3 normal = getNormal(point, 0.01);
	
		tunnelColor = vec3(0,1-calcAO(point, normal),0);
		tunnelColor = mix(tunnelColor, vec3(0),sphereTraceDist/30);
	}
	
	// center Hexagon
	float centerHexDist = hexagonDistance( 16.0/(1+15*zoom*zoom*zoom*zoom)*pos );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	vec3 innerColor= mix(tunnelColor, color, centerHexBorder );
	
	Intersection rayTraceIntersection = rayCastScene(camP, camDir);
	
	if(rayTraceIntersection.exists && (distance(camP, rayTraceIntersection.intersectP)<sphereTraceDist || 0 >= sphereTraceDist)){
		innerColor = ambientDiffuse(vec3(1.0), rayTraceIntersection.normal);
		
		// calculate reflection
		vec3 reflectOrigin = rayTraceIntersection.intersectP;
		vec3 reflectDir = reflect(camDir, rayTraceIntersection.normal);
		float reflectionDist = sphereTracing(reflectOrigin, reflectDir, 0, maxT, maxSteps);
		vec3 reflectionColor = vec3(0.0);
		
		if(0 < reflectionDist){
			vec3 point = reflectOrigin + reflectionDist * reflectDir;
			vec3 normal = getNormal(point, 0.01);

			reflectionColor = vec3(0, 1-calcAO(point, normal),0);
		}
		innerColor=mix(innerColor, reflectionColor, 0.2);
	}
	
	color = mix(color,innerColor,max(0,(min(1,1+camP.z))));
	
	gl_FragColor = vec4(color, 1);
}


