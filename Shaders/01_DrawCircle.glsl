//#extension GL_EXT_gpu_shader4 : enable

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D texLastFrame;

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
vec3 background(){

	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	
	float value = random(p.y);
	//value = random(p.x*tanh((sinh(p.y))*iGlobalTime*iGlobalTime*iGlobalTime*iGlobalTime*iGlobalTime));
	value = random(p.y*p.x*tanh(0.9*iGlobalTime));
	
/*	if(length(p)>0.42){
		value=random(p.y*p.x*sinh(0.9*iGlobalTime));
	}*/
	
	return value;
	

	//return vec3(0);
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
	float dirOrth = dot(dir,p);
	
	
	vec3 mask = vec3(1); //Background mask

	if(time>=0 && time<=end_anim_2){
		
		if(time<end_anim_1){
			if(dirOrth<0 && p.y>0){
				mask = vec3(1);
			}
		}
		else if(time< end_anim_2){
			dirOrth = dot(p,dir);
			if(dirOrth<0 || p.y>0){
				mask = vec3(1);
			}
		}
	}

	
		
		
		
	

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	float rSphere = 0.4;
	float thickness = 0.01;
	float rSphere2 = rSphere-thickness;

	//intersection
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);

	vec3 posSphere2  =vec3(0, 0, 1);
	float t2 = sphere(posSphere2, rSphere2, camP, camDir);

	

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
			color = background()*0.6*mask;
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
		// t = sphere(vec3(0, 0, 1), rSphere+(sin((p.x/p.y+((p.x*time))/*+sin(p.x*time)*//**value*/)*sinh(time)*sinh(time))), camP, camDir);
		t = sphere(vec3(0, 0, 1), rSphere+((p.y/p.x)*sinh(time)*sinh(time)*sqrt(time)), camP, camDir);
		
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
		//	if(time <endScene02){
				if(t2<0 && time){
					float x=rSphere+p.x;
					
					if(p.y<.0)
						x=(rSphere*3)-p.x;
					color = background()+0.6;//*animColor;//+(x*(1-sinh(time))*animColor);
				}
				else{
					//sphere
					color = background();//vec3(0);
				}
		/*	}
			else{
				color = vec3(1);
			}*/
		}
	

	
	//color*= animColor;
	
	return color;
}

vec3 scene1_2_Backup(float startTime){
	
	//camera setup
	float fov = 90.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));
	
	
	float rSphere = 0.4;
	float thickness = 0.01;
	float rSphere2 = rSphere-thickness;
	
	
		
	
	//color Animation
	vec3 animColor = vec3(0);
	float start_anim = 2.0;
	float time = iGlobalTime-startTime;
	float end_anim_1 = /*start_anim+*/1.79;
	float end_anim_2 = end_anim_1 +0.7255;
	
	float startScene02  = end_anim_2+0.0;
	float endScene02  = startScene02+3.0;//+1.0;
	float endScene03  = endScene02+2.0;
	float endScene04  = endScene03+8.0;
	
	
	vec3 posSphere2  =vec3(0, 0, 1);
	
	vec2 dir = vec2(sin(time*time),cos(time*time));
	vec2 point = vec2(p.x,p.y);
	float angle = dot(dir,point);
	//Draw Circle
	if(time>=0 && time<startScene02){
		
		if(time<end_anim_1){
			if(angle<0 && p.y>0){
				animColor = vec3(1);
				}
			else{
				animColor = vec3(0);
			}

		}
		else if(time< end_anim_2){
			angle = dot(point,dir);
			if(angle<0 || p.y>0){
				animColor = vec3(1);
			}
			else{
				animColor = vec3(0);
			}
		}
		else{
			animColor = vec3(1);
		}
	}
	else if(time>startScene02 && time <endScene02){
		animColor = vec3(1);
		float speed = (1+abs(sin((time-startScene02)*(time-startScene02))));
		speed = 1+sin((time-startScene02))/**(time-startScene02))*/;
		rSphere = rSphere*speed;
		//rSphere2 = rSphere2*abs(cos((time-startScene02)*(time-startScene02)));
	}
	else if(time >endScene02 && time <= endScene03  ){
				animColor = vec3(1);

		rSphere = 0.7;
		rSphere2 = 0.2;
	}
	else if(time >endScene03 &&time <= endScene04){
		animColor = vec3(1);
		
		rSphere = 0.7;
		rSphere2 = 0.2;
		
		posSphere2.x = 0.7*sin((time-endScene03));
		posSphere2.y = 0.7*-abs(cos((time-endScene03)));
	}
/*	else if(time >endScene02){
		animColor = vec3(1);	
	}*/
	else{
		animColor = vec3(0);	
	}
	


	//intersection
	
	float t = sphere(vec3(0, 0, 1), rSphere, camP, camDir);

	float t2 = sphere(posSphere2,/* rSphere-thickness*/rSphere2, camP, camDir);

	
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
		//	if(time <endScene02){
				if(t2<0 && time){
					float x=rSphere+p.x;
					
					if(p.y<.0)
						x=(rSphere*3)-p.x;
					color = background()+0.6*animColor;//+(x*(1-sinh(time))*animColor);
				}
				else{
					//sphere
					color = background();//vec3(0);
				}
		/*	}
			else{
				color = vec3(1);
			}*/
		}
	

	
	//color*= animColor;
	
	return color;
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
	float endScene1_2 = endScene1_1+18.0;

	if(iGlobalTime<endScene1_0){
		color = background();
	}
	else if(iGlobalTime<endScene1_1){
		color = s01_drawCircle(endScene1_0);
	}
	else if(iGlobalTime<endScene1_2){
		color = s02_(endScene1_1);
	}
	else{
		color =scene1_5(endScene1_2);
	}
	
	gl_FragColor = vec4(vec3(1)-color, 1.0);
}


