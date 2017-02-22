#version 330

#include "../libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float dimensionality;

const float epsilon = 0.0001;
const int maxSteps = 128;

float sPlane(vec3 point, vec3 normal, float d) {
    return dot(point, normal) - d;
}

float sSphere(vec3 point, vec3 center, float radius) {
    return length(point - center) - radius;
}

vec3 opCoordinateRepetition(vec3 point, vec3 c)
{
	vec3 result = mod(point, c) -0.5 * c;
	if(mod(point.y,2*c.y)>=c.y){
	result.x = mod(point.x+c.x/2, c.x) -0.5 * c.x;
	}
	if(point.z<0){
	result.z=point.z;
	}
    return result;
}


float distScene(vec3 point)
{
	point = opCoordinateRepetition(point, vec3(1.0, 1/sqrt(2), 1/sqrt(2)));
	float distSphere = sSphere(point, vec3(0.0, 0.0, 0.0), 0.2);
	return distSphere;
}

//by numerical gradient
vec3 getNormal(vec3 point)
{
	float d = epsilon;
	//get points a little bit to each side of the point
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);
	//calc difference of distance function values == numerical gradient
	vec3 gradient = vec3(distScene(right) - distScene(left),
		distScene(up) - distScene(down),
		distScene(behind) - distScene(before));
	return normalize(gradient);
}

void main()
{
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec3 point = camP; 	
	bool objectHit = false;
	float t = 0.0;
    for(int steps = 0; steps < maxSteps; ++steps)
    {
        float dist = distScene(point);
        if(epsilon > dist)
        {
			objectHit = true;
            break;
        }
        t += dist;
        point = camP + t * camDir;
    }
	vec3 color = vec3(0.0, 0.0, 0.0);
	if(objectHit)
	{
		vec3 lightDir = normalize(vec3(cos(iGlobalTime), 1.0, sin(iGlobalTime)));
		vec3 normal = getNormal(point);
		float lambert = max(0.2 ,dot(normal, lightDir));
		color = mix(vec3(1.0),lambert * vec3(1.0, 1.0, 1.0),dimensionality);
	}
	//fog
	float tmax = 5.0 + dimensionality*5;
	float yFactor =	step(0.99,(t * camDir).z/tmax);
	float depthFactor = t/tmax;
	float factor = mix(yFactor, depthFactor, dimensionality);
	// factor = clamp(factor, 0.0, 1.0);
	color = mix(color, vec3(0.0, 0.0, 0.0), factor);
	
	gl_FragColor = vec4(color, 1.0);
}
