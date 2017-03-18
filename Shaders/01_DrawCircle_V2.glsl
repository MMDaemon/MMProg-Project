//#extension GL_EXT_gpu_shader4 : enable

#include "HexagonDistField.glsl"
#include "../libs/Noise.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D texLastFrame;


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
		
	t = sphere(vec3(0, 0, 1), +((p.y/p.x)*sinh(22.43)*sinh(22.43)*sqrt(22.43)), camP, camDir);
	
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
//Draw circle
vec3 s01_drawCircle(float startTime){

	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);


	float time = iGlobalTime-startTime;
	
	float end_anim_1 = 1.79;				//above horizon
	float end_anim_2 = end_anim_1 +0.7255;  //below horizon
	

	
	vec2 dir = vec2(sin(time*time),cos(time*time));
	float angle = dot(dir,p);
	
	
	vec3 mask = vec3(0); //Background mask

	if(time>=0 && time<=end_anim_2){
		
		if(time<end_anim_1){
			if(angle<0 && p.y>0){
				mask = vec3(1)*0.6;
			}
		}
		else if(time< end_anim_2){
			angle = dot(p,dir);
			if(angle<0 || p.y>0){
				mask = vec3(1)*0.6;
			}
		}
		else{
			mask = vec3(1)*0.6;
		}
	}
	else{
		mask=vec3(1)*0.6;
	}

		
		
		
	

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	float rSphere = 0.4;
	float thickness = 0.01;
	float rSphere2 = rSphere-thickness;

	//intersection
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);

	vec3 posSphere2  =vec3(0, 0, 1);
	float t2 = sphere(posSphere2,/* rSphere-thickness*/rSphere2, camP, camDir);

	

	vec3 color;


	
	//color Spheres
	if(t < 0)
	{
		color = background();
	}
	else
	{
		if(t2<0 && time){
			float x=rSphere+p.x;
					
			if(p.y<.0)
				x=(rSphere*3)-p.x;
			color = background()+0.6*mask;
		}
		else{
			//sphere
			color = background();
		}

	}

	return color;
}

vec3 s02_(float startTime){
	
	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	
	float rSphere = 0.4;
	float thickness = 0.01;
	float rSphere2 = rSphere-thickness;
	

	float time = iGlobalTime-startTime;
	
	float end_part_01  = 3.5-0;//+13;//+1.0;
	float end_part_02  = end_part_01+3.5;
	float end_part_03  = end_part_02+8.0;
	
	
	vec3 posSphere2  =vec3(0, 0, 1);
	
	if( time <=end_part_01){

		float speed = (1+abs(sin((time)*(time))));
		speed = 1+sin(time);
		rSphere = rSphere;//*speed;
		//rSphere2 = rSphere2*abs(1-tanh(time*0.7));
	}


	//intersection

	float t = sphere(vec3(0, 0, 1), rSphere+(sin((p.y/p.x)*sinh(time)*sinh(time))), camP, camDir);
	float t2 = sphere(posSphere2,/* rSphere-thickness*/rSphere2, camP, camDir);
	if(time>end_part_01 && time<=end_part_02){
		time+=7.5;
		float value = random(p);
		 t = sphere(vec3(0, 0, 1), rSphere+(sin((p.x*p.y+sin(p.y*time)+sin(p.x*time)/**value*/)*sinh(time)*sinh(time))), camP, camDir);
		
	}
	else if(time>end_part_02){
		time-=7.0;
		float value = random(p);
//t = sphere(vec3(0, 0, 1), rSphere+(sin((p.x/p.y+((p.x*time))/*+sin(p.x*time)*//**value*/)*sinh(time)*sinh(time))), camP, camDir);
		t = sphere(vec3(0, 0, 1), rSphere+((p.y/p.x)*sinh(time)*sinh(time)*sqrt(time)), camP, camDir);
		t2 = sphere(posSphere2,(rSphere-thickness)*smoothstep(PI+PI/2,.0,time*time), camP, camDir);
	}
	
	
	//Guter übergang zu Kugel und Strich
	//float t = sphere(vec3(0, 0, 1), rSphere+((p.y/p.x)*sinh(time)*sinh(time)*sinh(time)), camP, camDir);
	
	//final color
	vec3 color;


	
	//color Spheres
	if(t < 0)
		{
			//background
			
			color = background();//vec3(0);
		}
		else
		{

				if(t2<0){

					color = /*vec3(1)-*/background()+0.3;
				}
				else{
					//sphere
					color = background();
				}

		}

	return color;
}
vec3 s03_3Sphere(float startTime){

	
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	

	float time = iGlobalTime-startTime;
	
	float rotAngle=PI/2;
	
/*	if(time>endScene3_0){
		float ang2 = PI/2*smoothstep(.0,PI/2,time-endScene3_0);
		rotAngle=ang2;//time-endScene3_0;//PI/2.0;
			
	
		mat2 mRot = mat2(
			cos(rotAngle),sin(rotAngle),
			-sin(rotAngle), cos(rotAngle)
		);
		p = mRot*p;
	}*/

	float mask=1;
/*
	if(time<endScene3_1){
		mask = step(-time*time,p.y);
		mask *=step(p.y,.0);

	}
	else{
		
		mask =step(p.y,.0);
		float st = time-endScene3_1;
		mask += step(p.y,st*st);

	}
	*/	

	


	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	float rSphere = 0.4;//*aspect;
	float thickness = 0.01/*+0.05*abs(sin(time))*/;
	float rSphere2 = (rSphere/*-thickness*/);

	//intersection
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);
		
	t = sphere(vec3(0, 0, 1), +((p.y/p.x)*sinh(22.43)*sinh(22.43)*sqrt(22.43)), camP, camDir);
	
	vec3 posSphere2  =vec3(0, 0, 1);
	float t2 = sphere(posSphere2,.0, camP, camDir);

	
	vec2 dir = vec2(-1.0,.0);
	
	float ang = dot(p,dir);

	float negTime = 14-time;

	float rLeft1 = (rSphere2+(0.5*thickness))*smoothstep(.0,PI/2,time)+(0.02*step(.0,negTime)*sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float tLeft1 = sphere(vec3(-(rSphere2), 0, 1),rLeft1, camP, camDir);
	
	float rLeft2 = smoothstep(.0,PI/2,time-0.4)*(rLeft1-+(0.5*thickness));

	float tLeft2 = sphere(vec3(-rSphere2, 0, 1),rLeft2, camP, camDir);
	
	float timeMid = time-1.5;
	float rMid1 = (rSphere2+(0.5*thickness)) *smoothstep(.0,PI/2,timeMid)+(0.02*step(.0,negTime)*sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float tMid1 = sphere(vec3(.0, .0, 1.0),rMid1, camP, camDir);
	
	float rMid2 = smoothstep(.0,PI/2,timeMid-0.4)*(rMid1-+(0.5*thickness));

	float tMid2 = sphere(vec3(.0, .0, 1.0),rMid2, camP, camDir);
	
	float timeRight = timeMid-1.5;
	float rRight1 = (rSphere2+(0.5*thickness)) *smoothstep(.0,PI/2,timeRight)+(0.02*step(.0,negTime)*sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float tRight1 = sphere(vec3((rSphere2), 0, 1),rRight1, camP, camDir);
	
	float rRight2 = smoothstep(.0,PI/2,timeRight-0.2)*(rRight1-+(0.5*thickness));
	float tRight2 = sphere(vec3(rSphere2, 0, 1),rRight2, camP, camDir);
	
	/*
	float timeLeft2 = timeRight-1.5;
	float rLeft21 = (rSphere2+(0.5*thickness)) *smoothstep(.0,PI/2,timeLeft2)+(0.02*step(.0,negTime)*sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float tLeft21 = sphere(vec3((-rSphere2*2), 0, 1),rLeft21, camP, camDir);
	
	float rLeft22 = smoothstep(.0,PI/2,timeLeft2-0.2)*(rLeft21-+(0.5*thickness));
	float tLeft22 = sphere(vec3(-rSphere2*2, 0, 1),rLeft22, camP, camDir);
	
	
	float rRight21 = (rSphere2+(0.5*thickness)) *smoothstep(.0,PI/2,timeLeft2)+(0.02*step(.0,negTime)*sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float tRight21 = sphere(vec3(.8, 0, 1),rRight21, camP, camDir);
	
	float rRight22 = smoothstep(.0,PI/2,timeLeft2-0.2)*(rRight21-+(0.5*thickness));
	float tRight22 = sphere(vec3(.8, 0, 1),rRight22, camP, camDir);
	*/
	
	//t = sphere(vec3(0, 0, 1), rSphere+centerHexDist*(p.y+p.x-centerHexBorder)/**-sin(time-endScene3_0)*sinh(time-endScene3_0*/), camP, camDir);
	
	
	

	
	
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
	float timeOffset = 16.0;
	vec3 sphereCol = -vec3(0.7);
	if(tLeft1>.0){

			color +=smoothstep(.0,PI/2,(1-p.x)-time+timeOffset)*sphereCol;

	}
	if(tLeft2>.0){

			color -= smoothstep(.0,PI/2,(1-p.x)-time+timeOffset)*sphereCol;


	}
	if(tMid1>.0){

		color +=smoothstep(.0,PI,(2-p.x)-time+timeOffset)*sphereCol;


	}
	if(tMid2>.0){

			color -= smoothstep(.0,PI,(2-p.x)-time+timeOffset)*sphereCol;


	}
	if(tRight1>.0){

		color +=smoothstep(.0,PI/2,(1-p.x)-time+timeOffset)*sphereCol;


	}
	if(tRight2>.0){

			color -= smoothstep(.0,PI/2,(1-p.x)-time+timeOffset)*sphereCol;


	}

	
	float func = .01*sin(p.x+50+time)- p.y;//(0.02*sin(sin(p.x*time*time)*(sin(p.x*time*time))));
		func = 0.1*sin((1-p.x)*time)*(sin(sin(p.x*negTime*negTime)*(sin(p.y*negTime*negTime))));
	float thick =0.005;

	float line = smoothstep(func+0.5*thick,p.y,time);
	
	float line2 = smoothstep(func*sin(p.x)-0.5*thick,p.y,time);
		//line -= line2;

	
	
	float graph = plotFunction(p, 0.005,(14-time)+0, 0);
	//color += vec3(.0,.7,.0)*(line);
	//color -= vec3(.0,.7,.0)*(line2);
	
	//color+= smoothstep(.0,PI/2,time-25.0);//cut
	
	
/*	for(float i=.0;i<10.0;i+=1.0){
		float graph = plotFunction(p, 0.005,(14-time)+i, i);
		color += vec3(.0,-1.0,.0) * graph;
	
	}*/
	
	

	return color ;

}

vec3 s03_3Sphere_rotbackup(float startTime){
	float endScene3_0 = 2.1; //rotation
	float endScene3_1 = 3.6; //mask move right
	float endScene3_2 = 1.6;
	
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	
	
	float time = iGlobalTime-startTime;
	
	float rotAngle=0;
	
	if(time>endScene3_0){
		float ang = PI/2*smoothstep(.0,PI/2,time-endScene3_0);
		rotAngle=ang;//time-endScene3_0;//PI/2.0;
			
	
		mat2 mRot = mat2(
			cos(rotAngle),sin(rotAngle),
			-sin(rotAngle), cos(rotAngle)
		);
		p = mRot*p;
	}

	float mask=1;

	if(time<endScene3_1){
		mask = step(-time*time,p.y);
		mask *=step(p.y,.0);

	}
	else{
		
		mask =step(p.y,.0);
		float st = time-endScene3_1;
		mask += step(p.y,st*st);

	}
	

	


	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	float rSphere = 0.4;
	float thickness = 0.01;
	float rSphere2 = rSphere-thickness;

	//intersection
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);
		//t = sphere(vec3(0, 0, 1), rSphere+((p.y/p.x)*sinh(iGlobalTime)*sinh(iGlobalTime)*sqrt(iGlobalTime)), camP, camDir);
		t = sphere(vec3(0, 0, 1), rSphere+((p.y/p.x)*sinh(22)*sinh(22)*sqrt(22)), camP, camDir);
	vec3 posSphere2  =vec3(0, 0, 1);
	float t2 = sphere(posSphere2,/* rSphere-thickness*/rSphere2, camP, camDir);
	//if(time>endScene3_0)
	//t = sphere(vec3(0, 0, 1), cos((time-endScene3_0))+(((p.y*p.x))*acosh(time-endScene3_0)), camP, camDir);
	
	

	
	//t = sphere(vec3(0, 0, 1), rSphere+centerHexDist*(p.y+p.x-centerHexBorder)*-sin(time-endScene3_0)*sinh(time-endScene3_0), camP, camDir);
	
	
	vec3 back  = background(rotAngle/*, time+time*/);//+background(rotAngle);
	vec3 color = back;//s02_(startTime*3);
	
	//color Spheres
	if(t < 0)
	{

		color = background(rotAngle,22);

		
	}
	else
	{


		if(t2<0 ){
			mask = -1*(mask-1);
			//background
			//if(p.y<.0){

				

			/*}
			else{
				color = background(rotAngle);
			}*/
		}
		else{
			//sphere
			/*if(p.y<.0){
				
				color = vec3(1)-back)*mask;//background(rotAngle);
			}
			else{
				*/
				
				color = vec3(1)-back*(1-mask);
			//}
		}

	}
	if(mask<=.0){
		color = (vec3(1)-back);
		}
	/*else if(time<endScene3_2){
		color =back+0.3;
		}*/
		else{
		color = back;
		}
	return color ;

}

vec3 s04_3SphereToHexPoints(float startTime){

	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);


	
	
		vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	float time = iGlobalTime-startTime;
	
	
	
//	p = (2.0*p-vec2(1.0, 1.0)) * vec2(1.0, aspect);
	
	float rotAngle=PI/2.0;
	
	mat2 mRot = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	p = mRot*p;
	
		
	vec3 color=vec3(0);
	float scale=2.6;//+smoothstep(2.0,5.0,time)*(16.0-2.5);
	
	float centerHexDist = hexagonDistance( scale*p );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	centerHexBorder += 1.0-smoothstep( 0.95, 0.99, centerHexDist );
	//color= mix(vec3(0.0, 1.0, 0.0), color, centerHexBorder );
	
	
	float time1 = .6;
	float time2 = 1.2;
	float time3 = 1.8;
	float time4 = 2.4;
	float time5 = 3.0;
	float time6 = 3.6;
	
	float r = 0.035;//0.033;
	float waveMaxR = 0.1;
	float rWave = waveMaxR-waveMaxR*smoothstep(.0,PI/2,time);
	float rWave2 = waveMaxR-waveMaxR*smoothstep(time1,time1+PI/2,time);
	float rWave3 = waveMaxR-waveMaxR*smoothstep(time2,time2+PI/2,time);
	float rWave4 = waveMaxR-waveMaxR*smoothstep(time3,time3+PI/2,time);
	float rWave5 = waveMaxR-waveMaxR*smoothstep(time4,time4+PI/2,time);
	float rWave6 = waveMaxR-waveMaxR*smoothstep(time5,time5+PI/2,time);
	float posR = 0.44;
	


	float t1 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),r, camP, camDir);
	float t11 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave), camP, camDir);
	float t12 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave-0.002), camP, camDir);
	float t13 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave-0.012), camP, camDir);
	float t14 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave-0.014), camP, camDir);
	float t15 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave-0.024), camP, camDir);
	float t16 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),(rWave-0.026), camP, camDir);
	
	float t2 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),r, camP, camDir);
	float t21 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2, camP, camDir);
	float t22 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2-0.002, camP, camDir);
	float t23 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2-0.012, camP, camDir);
	float t24 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2-0.014, camP, camDir);
	float t25 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2-0.024, camP, camDir);
	float t26 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),rWave2-0.026, camP, camDir);
	
	float t3 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),r, camP, camDir);
	float t31 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3, camP, camDir);
	float t32 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3-0.002, camP, camDir);
	float t33 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3-0.012, camP, camDir);
	float t34 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3-0.014, camP, camDir);
	float t35 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3-0.024, camP, camDir);
	float t36 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),rWave3-0.026, camP, camDir);
	
	float t4 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),r, camP, camDir);
	float t41 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4, camP, camDir);
	float t42 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4-0.002, camP, camDir);
	float t43 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4-0.012, camP, camDir);
	float t44 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4-0.014, camP, camDir);
	float t45 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4-0.024, camP, camDir);
	float t46 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),rWave4-0.026, camP, camDir);
	
	float t5 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),r, camP, camDir);
	float t51 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5, camP, camDir);
	float t52 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5-0.002, camP, camDir);
	float t53 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5-0.012, camP, camDir);
	float t54 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5-0.014, camP, camDir);
	float t55 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5-0.024, camP, camDir);
	float t56 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),rWave5-0.026, camP, camDir);
	
	float t6 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),r, camP, camDir);
	float t61 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6, camP, camDir);
	float t62 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6-0.002, camP, camDir);
	float t63 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6-0.012, camP, camDir);
	float t64 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6-0.014, camP, camDir);
	float t65 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6-0.024, camP, camDir);
	float t66 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),rWave6-0.026, camP, camDir);


	
	if(t1>.0  ){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/ vec3(1.0,1.0,1.0)*step(.0,time);
		
	}
	else if(t2>.0){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/vec3(1.0,1.0,1.0)*step(0.6,time);
	}
	else if(t3>.0){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/vec3(1.0,1.0,1.0)*step(1.2,time);
	}
	else if(t4>.0){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/vec3(1.0,1.0,1.0)*step(1.8,time);
	}
	else if(t5>.0){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/vec3(1.0,1.0,1.0)*step(2.4,time);
	}
	else if(t6>.0){
		color =/*mix(vec3(1.0, 1.0, 1.0),  color, centerHexBorder )**/vec3(1.0,1.0,1.0)*step(3.0,time);
	}
	else{
	vec3 col = vec3(1.0);
		if(time >.0){
			vec2 center = vec2(posR,0.0);
		
			if(t16>.0){
				color = vec3(.0);
			}
			else if(t15>.0){
				color =col*0.3;
			}
			else if(t14>.0){
				
				color = vec3(.0);
			}
			else if(t13>.0){
				color =col*0.6;
			}
			else if(t12>.0){
				
				color = vec3(.0);
			}
			else if(t11>.0){
				color =col;
			}

		}
		if(time > time1){
			if(t26>.0){
				color = vec3(.0);
			}
			else if(t25>.0){
				color =col*0.3;
			}
			else if(t24>.0){
				
				color = vec3(.0);
			}
			else if(t23>.0){
				color =col*0.6;
			}
			else if(t22>.0){
				
				color = vec3(.0);
			}
			else if(t21>.0){
				color =col;
			}

		}
		if(time > time2  ){
			if(t36>.0){
				color = vec3(.0);
			}
			else if(t35>.0){
				color =col*0.3;
			}
			else if(t34>.0){
				
				color = vec3(.0);
			}
			else if(t33>.0){
				color =col*0.6;
			}
			else if(t32>.0){
				
				color = vec3(.0);
			}
			else if(t31>.0){
				color =col;
			}

		}
		if(time > time3 ){
			if(t46>.0){
				color = vec3(.0);
			}
			else if(t45>.0){
				color =col*0.3;
			}
			else if(t44>.0){
				
				color = vec3(.0);
			}
			else if(t43>.0){
				color =col*0.6;
			}
			else if(t42>.0){
				
				color = vec3(.0);
			}
			else if(t41>.0){
				color =col;
			}

		}
		 if(time > time4){
			if(t56>.0){
				color = vec3(.0);
			}
			else if(t55>.0){
				color =col*0.3;
			}
			else if(t54>.0){
				
				color = vec3(.0);
			}
			else if(t53>.0){
				color =col*0.6;
			}
			else if(t52>.0){
				
				color = vec3(.0);
			}
			else if(t51>.0){
				color =col;
			}

		}

		if(time > time5){
			if(t66>.0){
				color = vec3(.0);
			}
			else if(t65>.0){
				color = col*0.3;
			}
			else if(t64>.0){
				
				color = vec3(.0);
			}
			else if(t63>.0){
				color =col*0.6;
			}
			else if(t62>.0){
				
				color = vec3(.0);
			}
			else if(t61>.0){
				color =col;
			}
		}

	}

	
	return color;

}
vec3 s05_HexPointsToHex(float startTime){


		float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

		vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	float time = iGlobalTime-startTime;
	

//	p = (2.0*p-vec2(1.0, 1.0)) * vec2(1.0, aspect);
	
	float rotAngle=PI/2.0;
	
	mat2 mRot = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	p = mRot*p;
	
		
	vec3 color=vec3(0);
	float scale=2.6;//+smoothstep(2.0,5.0,time)*(16.0-2.5);
	
	float centerHexDist = hexagonDistance( scale*p );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	centerHexBorder += 1.0-smoothstep( 0.95, 0.99, centerHexDist );
	//color= mix(vec3(0.0, 1.0, 0.0), color, centerHexBorder );
	
		float r = 0.035;//0.033;
		
		
		float posR = 0.44;
	


	float t1 = sphere(vec3(posR*cos(.0), posR*sin(.0), 1),r, camP, camDir);

	
	float t2 = sphere(vec3(posR*cos(PI*0.333), posR*sin(PI*0.333), 1),r, camP, camDir);

	
	float t3 = sphere(vec3(posR*cos(PI*0.666), posR*sin(PI*0.666), 1),r, camP, camDir);

	float t4 = sphere(vec3(posR*cos(PI), posR*sin(PI), 1),r, camP, camDir);

	
	float t5 = sphere(vec3(posR*cos(PI*1.333), posR*sin(PI*1.333), 1),r, camP, camDir);

	
	float t6 = sphere(vec3(posR*cos(PI*1.666), posR*sin(PI*1.666), 1),r, camP, camDir);



	vec3 colorDots = vec3(1.0);
	if(t1>.0  ){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/ colorDots*smoothstep(1.1,.0,time);
		
	}
	else if(t2>.0){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/colorDots*smoothstep(2.2,.0,time);
	}
	else if(t3>.0){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/colorDots*smoothstep(3.3,.0,time);
	}
	else if(t4>.0){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/colorDots*smoothstep(4.4,.0,time);
	}
	else if(t5>.0){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/colorDots*smoothstep(5.5,.0,time);
	}
	else if(t6>.0){
		color =/*mix(vec3(0.0, 1.0, 0.0),  color, centerHexBorder )**/colorDots*smoothstep(6.6,.0,time);
	}
	
	
	
	float end_anim_1 = PI/2;				//above horizon
	float end_anim_2 = end_anim_1+PI/2;  //below horizon
	
	float ang2 = -PI*0.16666;
	mat2 mRot2 = mat2(
		cos(ang2),sin(ang2),
		-sin(ang2), cos(ang2)
	);
	p = mRot2*p;
	
	vec2 dir = vec2(-sin(time*2.0),cos(time*2.0));
	float angle = dot(dir,p);
	
	
	vec3 mask = vec3(0); //Background mask

	if(time>=0 && time<=end_anim_2){
		
		if(time<end_anim_1){
			if(angle<0 && p.y>0){
				mask = vec3(1);//*0.6;
			}
		}
		else if(time< end_anim_2){
			angle = dot(p,dir);
			if(angle<0 || p.y>0){
				mask = vec3(1);//*0.6;
			}
		}
		else{
			mask = vec3(1);//*0.6;
		}
	}
	else{
		mask=vec3(1);//*0.6;
	}

	color = mix(mask,  color, centerHexBorder )+color;
	
	

	color = background2()-color;

	
	return color;
}
vec3 s06_HexRot(float startTime){

	float endScene3_0 = 1.6; //rotation once
	float endScene3_1 = 3.3; //mask move right
	float endScene3_2 = endScene3_1+1.0; //rotation
	
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);
	
	float time = iGlobalTime-startTime;
	
	float rotAngle=0;
	
	if(time>endScene3_0){
		float ang = PI/2*smoothstep(.0,PI/2,time-endScene3_0);
		if( time >endScene3_2){
			ang+=((time-endScene3_2)+0.7*(time-endScene3_2));
		}
		rotAngle=ang;//time-endScene3_0;//PI/2.0;
			
	
		mat2 mRot = mat2(
			cos(rotAngle),sin(rotAngle),
			-sin(rotAngle), cos(rotAngle)
		);
		p = mRot*p;
	}
	
	

	float mask=1;

	if(time<endScene3_1){
		mask = step(-time*time,p.y);
		mask *=step(p.y,.0);

	}
	else{
		
		mask =step(p.y,.0);
		float st = time-endScene3_1;
		mask += step(p.y,st*st);

	}
	
		vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	
	float rotAngle2=PI/2.0;
	
	mat2 mRot = mat2(
		cos(rotAngle2),sin(rotAngle2),
		-sin(rotAngle2), cos(rotAngle2)
	);
	p = mRot*p;
	
		
	vec3 color=vec3(0);
	float scale=2.6;
	if(	 time >endScene3_2){
		scale +=smoothstep(0.0,1.8,time-endScene3_2)*(-1.5);
		scale +=-(smoothstep(1.8,2.2,time-endScene3_2))*(16.0);//-2.5);
	}
	float centerHexDist = hexagonDistance( scale*p );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	centerHexBorder += 1.0-smoothstep( 0.95, 0.99, centerHexDist );
	//color= mix(vec3(0.0, 1.0, 0.0), color, centerHexBorder );


	color = mix(vec3(1.0),  color, centerHexBorder )+color;
	if(mask<0.9){
		color = background2(rotAngle)-color;
	}
	else{
		color = vec3(1)-color*vec3(.0,1.0,.0);
	}
	
	
	
	return color;
}





vec3 s05_Hex(float startTime){
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 pos = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

/*	
	vec2 pos = gl_FragCoord.xy/iResolution.xy;
	float aspect = iResolution.y/iResolution.x; 
	*/
	float time = iGlobalTime-startTime;
	
	
	
//	pos = (2.0*pos-vec2(1.0, 1.0)) * vec2(1.0, aspect);
	
/*	float rotAngle=PI/2.0;
	
	mat2 mRot = mat2(
		cos(rotAngle),sin(rotAngle),
		-sin(rotAngle), cos(rotAngle)
	);
	pos = mRot*pos;*/
	
		
	vec3 color=vec3(0);
	float scale=2.7+smoothstep(2.0,5.0,time)*(16.0-2.5);
	
	float centerHexDist = hexagonDistance( scale*pos );
	float centerHexBorder = smoothstep( 0.99, 1.03, centerHexDist );
	centerHexBorder += 1.0-smoothstep( 0.95, 0.99, centerHexDist );
	color= mix(vec3(0.0, 1.0, 0.0), color, centerHexBorder );
	
	return vec3(1)-color;

}

vec3 scene1_4(float startTime){
	float time = iGlobalTime-startTime;

	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	float rSphere = 0.4;
	float z = 1.0;
	float x =sin(time);
	
	
	
	if(time>1.0 && iGlobalTime <9.0){
		z = 1+sin(time-1.0);
	}
	/*else if(iGlobalTime >=9.0){
		z = 2.0;
		x=0;
	}*/
	
	
	float t1 = sphere(vec3(x, 0, z), rSphere, camP, camDir);
	float t2 = sphere(vec3(0, 0, z), rSphere, camP, camDir);
	float t3 = sphere(vec3(-x, 0, z), rSphere, camP, camDir);
	
	if(t1>0.0||t2>.0||t3>.0){
		return vec3(1.0);
	}
	
	return vec3(.0);
}
vec3 scene1_5(float startTime){
	float time = iGlobalTime-startTime;

	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	float rSphere = 0.4;
	float z = 1.0;
	float x =.5;


	float t1 = sphere(vec3(-x, 0, z), rSphere, camP, camDir);
	float t1b = sphere(vec3(-x, 0, z), rSphere-0.01, camP, camDir);
	float t2 = sphere(vec3(0, 0, z), rSphere, camP, camDir);
	float t2b = sphere(vec3(0, 0, z), rSphere-0.01, camP, camDir);
	float t3 = sphere(vec3(x, 0, z), rSphere, camP, camDir);
	float t3b = sphere(vec3(x, 0, z), rSphere-0.01, camP, camDir);
	
	float mask = step(p.x,.0);
	float mask2 = step(0.0,p.y);//.0,cos(time*time));
	
	if(mask!=mask2){
		mask=1.0;
	}
	else{
		mask=0.0;
	}
	
	
	if(t2b>.0){
		return vec3(1.0)-mask;
	}
	if(t2>.0){
		return vec3(0.0)+mask;
	}

	
	if(t3b>.0 || t1b>.0){
		return vec3(1.0)-mask;
	}
	
	if( t3>0.0 || t1>.0){
		return vec3(.0)+mask;
	}
	
	if(t3b>.0){
		return vec3(1.0)-mask;
	}
	if(t3>.0){
		return vec3(0.0)+mask;
	}
	
	return vec3(1.0)-mask;
}

void main()
{
	vec3 color = vec3(0);
	
	float endScene1_0 = 9.0;
	float endScene1_1 = endScene1_0+3.6;//+6.0;
	float endScene1_2 = endScene1_1+10.0;
	float endScene1_3 = endScene1_2+14.0;//;+14.0;
	float endScene1_4 = endScene1_3+3.5;
	float endScene1_5 = endScene1_4+3.5;
	float endScene1_6 = endScene1_5+6.74262;

	if(iGlobalTime<endScene1_0){
		color = /*vec3(1.0)-*/background();
	}
	else if(iGlobalTime<endScene1_1){
		color = /*vec3(1.0)-*/s01_drawCircle(endScene1_0);
	}
	else if(iGlobalTime <endScene1_2){
		color = /*vec3(1.0)-*/s02_(endScene1_1);
	}
	else if(iGlobalTime < endScene1_3){
		color = s03_3Sphere(endScene1_2);
		//color+= -s04_3SphereToHex(endScene1_3);
	}
	else if(iGlobalTime < endScene1_4){
		color = s03_3Sphere(endScene1_2);
		color+= -s04_3SphereToHexPoints(endScene1_3);
	}
	else if(iGlobalTime< endScene1_5){

		color = s05_HexPointsToHex(endScene1_4);
	}
	else if(iGlobalTime< endScene1_6){

		color = s06_HexRot(endScene1_5);
	}
	else {
		
		color = s05_Hex(endScene1_3);
	}
	
	gl_FragColor = vec4(vec3(1)-color, 1.0);
}


