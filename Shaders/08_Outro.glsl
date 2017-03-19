//#extension GL_EXT_gpu_shader4 : enable

#include "HexagonDistField.glsl"
#include "../libs/Noise.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float iStartTime;

const float maxSpheres = 20;

//fractal Brownian motion
float fBm(vec2 p,float time, float offset=0)
{
	// Properties
	int octaves = 10;//int(iMouse.x * 0.01);
	float lacunarity = .0;
	float gain = .0;
	// Initial values
	float amplitude = .01;
	float frequency = 10*smoothstep(.0,PI,time);
	float value = 0;
	// Loop of octaves
	for (int i = 0; i < octaves; ++i)
	{
		value += amplitude * noise(frequency*noise( ceil(noise(abs(p.x*time)))*frequency*time) * p.x );
		frequency += lacunarity;
		amplitude *= gain;
	}
	
	
	return frequency*(sin(value))-offset*0.05;
}

//draw function line		
float plotFunction(vec2 coord, float width, float time,float offset=1)
{
	float dist = abs(fBm(coord,time,offset) - coord.y);
	//dist+= abs(fBm(coord.y,time, offset) - coord.y);
	//dist += +(0.02*((coord.x*time*time)/**((coord.y*time*time))*/));
	return 1 - smoothstep(0, width, dist);
}


const float bigNumber = 10000.0;
const float eps = 0.001;

float quad(float a)
{
	return a * a;
}

//M = center of sphere
//r = radius of sphere
//O = origin of ray
//D = direction of ray
//return t of smaller hit point
float sphere(vec3 M, float r, vec3 O, vec3 D)
{
	vec3 MO = O - M;
	float root = quad(dot(D, MO))- quad(length(D)) * (quad(length(MO)) - quad(r));
	//does ray miss the sphere?
	if(root < eps)
	{
		//return something negative
		return -bigNumber;
	}
	//ray hits the sphere -> calc t of hit point(s)
	float p = -dot(D, MO);
	float q = sqrt(root);
    return (p - q) > 0.0 ? p - q : p + q;
}

//M = center of sphere
//P = some point in space
// return normal of sphere when looking from point P
vec3 sphereNormal(vec3 M, vec3 P)
{
	return normalize(P - M);
}

//N = normal of plane
//k = distance to origin
//O = origin of ray
//D = direction of ray
float plane(vec3 N, float k, vec3 O, vec3 D)
{
	float denominator = dot(N, D);
	if(abs(denominator) < eps)
	{
		//no intersection
		return -bigNumber;
	}
	return (-k - dot(N, O)) / denominator;
}	
float random(float seed)
{
	return fract(sin(seed) * 1231534.9);
}

float random(vec2 coord) { 
    return random(dot(coord, vec2(21.97898, 7809.33123)));
}

//background
vec3 background(float rotAngle=0, float time=.0){
	if(time == .0){
		time = iGlobalTime;
	}
	rotAngle+=0.0001;
	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	
	mat2 mRot = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	p = mRot*p;
	
	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	
	float value = random(p.y);
	//value = random(p.x*tanh((sinh(p.y))*time*time*time*time*time));
	
	float shiftX = 1.85;
	float shiftY = 0.62;
	
	value = random((p.x+shiftX*cos(p.x))*(p.y+shiftY*cos(p.y))/**sinh(0.8*(time+.0))*/);

	rotAngle=PI/4.0;
	
	mat2 mRot2 = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	
	//p = mRot2*p;
	//value += random((p.x*-cos(p.x))*(p.y*cos(p.y))*sinh(0.8*(time+2.0)));
	
	//value += random((p.x+1.0*cos(p.x)-1.3*tanh(p.x))*(p.y-.22*cos(p.y))*sinh(0.8*(time+2.0)));
	
	
	value += random((p.x+shiftX*-cos(p.x))*(p.y-shiftY*cos(p.y))/**sinh(0.8*(time+.0))*/);
	value += random((p.x+shiftX*-cos(p.x))*(p.y+shiftY*cos(p.y))*sinh(0.8*(time+.0)));
	value += random((p.x+shiftX*+cos(p.x))*(p.y-shiftY*cos(p.y))*sinh(0.8*(time+.0)));
	
	value/=3.0;

	return 1-value;
	

	//return vec3(0);
}



vec3 background2(float rotAngle=0){

	
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	

	
	mat2 mRot = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	p = mRot*p;



	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	float rSphere = 0.4;//*aspect;
	float thickness = 0.01/*+0.05*abs(sin(time))*/;
	float rSphere2 = (rSphere/*-thickness*/);

	//intersection
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);
		
	t = sphere(vec3(0, 0, 0), +((p.y/p.x)*sinh(22.43)*sinh(22.43)*sqrt(22.43)), camP, camDir);
	
	vec3 posSphere2  =vec3(0, 0, 1);
	float t2 = sphere(posSphere2,.0, camP, camDir);
	

	
	
	vec3 back  = background(rotAngle);//+background(rotAngle);
	vec3 color = back;//s02_(startTime*3);
	
	//color Spheres
	if(t < 0)
	{
			//background
			
			color = background();
	}
	else {
		if(t2<0){
	
			color = background()+0.3;
		}
	
			else{
				color = background();
			}

	}

	return color ;
}


struct Hit{
	bool exists;
	vec2 dist;
	vec3 color;
};

Hit rayMarch(float time){

	float end1 = 6.0;
	float end2 = end1+6.0;
	float end3 = end2+6.0;
	float end4 = end3+4.0;
	float end5 = end4+4.0;
	
	vec3 color =  vec3(.0);//background2();
	
	float scale = 0.3-0.230*smoothstep(.0,end1,time);
	time+=scale;
	
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	
	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	
	float r= 0.12;
	float dist = -10000.0;
	
	for(float i=221-1;i>=0;i--){
		vec3 pos = vec3(smoothstep(.0,16.0,time)*vec2(0.4*-cos(0.6*time),0.4*sin(time)),1.0);
	//	vec3 pos = vec3(.0,.0,1.0);
		
		//float r2 =  max((i*0.1)+0.3*time,.0);
		float r2 =  max(-(i*scale)+0.5*time,.0);
	
		
		if(time>= end1&& time <end2){
			float thickness = 0.01;
			r2 = (r2) +(.05*smoothstep(.0,2.0,time-end1)*smoothstep(end1-end2,end1-end2+2.0,-time+end1)*-sin(p.x*sin(p.y*time))*(cos(p.x*time)));
		

		}
		else if (time >= end2 && time <=end3){
		float thickness = 0.01;
		float startEnd = smoothstep(.0,2.0,time-end2)*smoothstep(end2-end3,end2-end3+2.0,-time+end2);
			r2 = (r2+(0.5*thickness)) *smoothstep(.0,PI/2,time)+(0.03*startEnd*step(.0,time)*sin(sin(p.x*time*time)*(sin(p.y*time*time))));

		}
		else if (time >= end3 && time <end4){
				float thickness = 0.01;
				
			float startEnd = smoothstep(.0,2.0,time-end3)*smoothstep(end3-end4,end3-end4+2.0,-time+end3);
			r2 = r2 +(startEnd*((-sin(p.y*atan(time)))-(cos(p.x*tanh(time)))));
			
			if(mod(i,2.0)==.0){
				r2 = r2+-(.9*thickness*sin(p.y*time));
			}
		}
		else if (time >= end4 && time<end5){
			float thickness = .0001;
			float startEnd = smoothstep(.0,2.0,time-end3)*smoothstep(end3-end4,end3-end4+2.0,-time+end3);
			r2 = r2 +(.7*((-cos(p.y*time)*-sin(p.x+time)))*sin(-cos(p.x*time)))*smoothstep(-3.0,-4.0,-time+end4);

			if(mod(i,2.0)==.0){
				r2 = r2-((0.01*thickness));
			}
		
		}
		else if (time >= end5){
			float thickness = .0001;
			r2 = r2 +(.1*smoothstep(.0,2.0,time-end5)*((-cos(p.y*time)*-sin(p.x+time)))*sin(-cos(p.x*time)));
			//pos+=abs(sin(time-end4));
			if(mod(i,2.0)==.0){
				r2 = r2-((0.01*thickness));
			}
		
		}
	//	 r2 =  max(-(i*.21)+rfunc,.0);

		//(mod(i,2.0)>.0) ? color = vec3(1.0) : color = vec3(1.0);
		
		float t = sphere(pos, r2, camP, camDir);
		//color= vec3(1.0);
		if(t<=.0){
			
			dist = t;
			color = vec3(1.0);
			if(mod(i,2.0)==.0){
				color = vec3(.0)+t;
			}
			else{
				color= vec3(1.0)-t*0.5;
			}
			
			vec3 mask = vec3(0.0);
			if(t == -10000.0){
				mask = vec3(1.0);//background();
			}
			else{
				color = background(.0,time);
			}
			
		}

	}


	float r2 = .0;
	
	float t = sphere(vec3(0, 0, 1), time, camP, camDir);
	float t2 = sphere(vec3(0, 0, 1), r2, camP, camDir);
	
	
/*	if(t>.0){
		color = vec3(1.0);
	}*/
	
	return Hit(dist>=.0,dist,color);
}



vec3 s01_Point(float time){
	
	vec3 color = vec3(.0);
	

	
	Hit hit = rayMarch(time);
	
	return hit.color;

}


void main()
{
	vec3 color = vec3(0);
	
	color = s01_Point(iGlobalTime/*-120.0*/);

	gl_FragColor = vec4(color, 1.0);
}



