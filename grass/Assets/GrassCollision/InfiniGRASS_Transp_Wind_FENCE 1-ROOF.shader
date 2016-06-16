Shader "InfiniGRASS/InfiniGrass Directional Wind ROOF" {
	Properties {
		_Diffuse ("Diffuse", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5

		_BulgeScale ("Bulge Scale", Float ) = 0.2
		_BulgeShape ("Bulge Shape", Float ) = 5

		_WaveControl1("Waves", Vector) = (1, 0.01, 0.001, 0.41) // _WaveControl1.w controls interaction power
		_TimeControl1("Time", Vector) = (1, 1, 1, 100)
		_OceanCenter("Ocean Center", Vector) = (0, 0, 0, 0)

		//INFINIGRASS - hero position for fading and lowering dynamics to reduce jitter while interacting  
		_InteractPos("Interact Position", Vector) = (0, 0, 0) //for lowering motion when interaction item is near
		_InteractSpeed("Interact Speed", Vector) = (0, 0, 0) //v1.5
		_FadeThreshold ("Fade out Threshold", Float ) = 100
		_StopMotionThreshold ("Stop motion Threshold", Float ) = 10

		_ColorGlobal ("Global tint", Color) = (0.5,0.5,0.5,0) //0.5,0.8,0.5
		_SpecularPower("Specular", Float) = 1

		_SmoothMotionFactor("Smooth wave motion", Float) = 105
		_WaveXFactor("Wave Control x axis", Float) = 1
		_WaveYFactor("Wave Control y axis", Float) = 1
	}
	SubShader {
		Tags {
			"Queue"="AlphaTest"
			"RenderType"="TransparentCutout"
		}
		Pass {
			Name "ForwardBase"
			Tags {
				"LightMode"="Always"
			}
			Cull Off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform float4 _TimeEditor;
			uniform sampler2D _Diffuse; uniform float4 _Diffuse_ST;
			
			uniform float _BulgeScale; 
			uniform float _BulgeShape;
			uniform float _BulgeScale_copy;
			float4 _WaveControl1;
			float4 _TimeControl1;
			float3 _OceanCenter;
			uniform fixed _Cutoff;
			float3 _InteractPos;
			float _FadeThreshold;
			float _StopMotionThreshold;
			
			float3 _ColorGlobal;
			float _SpecularPower;
			float _SmoothMotionFactor;
			float _WaveXFactor;
			float _WaveYFactor;
			
			float3 _InteractSpeed;
			
			struct VertexInput {
				float4 vertex : POSITION;
				float4 normal: NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
			};
			VertexOutput vert (VertexInput v) {
				VertexOutput o;
				o.uv0 = v.texcoord0;

				float bulgeCollision = lerp(v.normal.x, 0, (_Time.y - v.normal.y)/2);
				bulgeCollision = max(bulgeCollision, 0);
				float bulge = _BulgeScale + bulgeCollision; 
				
				float4 node_392 = _Time + _TimeEditor;
							
				float dist = distance(_OceanCenter, float3(_WaveControl1.x*mul(unity_ObjectToWorld, v.vertex).y,_WaveControl1.y*mul(unity_ObjectToWorld, v.vertex).x,_WaveControl1.z*mul(unity_ObjectToWorld, v.vertex).z) );
				float dist2 = distance(_OceanCenter, float3(mul(unity_ObjectToWorld, v.vertex).y,mul(unity_ObjectToWorld, v.vertex).x*0.10,0.1*mul(unity_ObjectToWorld, v.vertex).z) );

				float node_5027 = (_Time.y*_TimeControl1.x + _TimeEditor);//*sin(dist + 1.5*dist*pi);
				float node_133 = pow((abs((frac((o.uv0+node_5027*float2(0.2,0.1)).r)-0.5))*2.0),_BulgeShape);

				//INIFNIGRASS
				float4 modelY = float4(0.0,1.0,0.0,0.0);
				float4 ModelYWorld =mul(unity_ObjectToWorld,modelY);
				float scaleY = length(ModelYWorld);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);

				float3 SpeedFac = float3(0,0,0);  //  SpeedFac =  _InteractSpeed;  
				float distA =  distance(_InteractPos,posWorld)/ (_StopMotionThreshold*1);      
				if( distance(_InteractPos,posWorld) < _StopMotionThreshold*1){ 
					SpeedFac =  _InteractSpeed *_WaveControl1.w;

					if( o.uv0.y > 0.19){
						_WaveXFactor = _WaveXFactor - (1-distA)*(1-distA)*SpeedFac.z;
						_WaveYFactor = _WaveYFactor - (1-distA)*(1-distA)*SpeedFac.x;
					}
					if( o.uv0.y > 0.5){
						posWorld.y = posWorld.y - (1-distA)*3*(o.uv0.y-0.5)*sin(posWorld.z+_Time.y) ;//+bulge*0.5*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) ;
					}             
				}


				dist = 90* (cos(_BulgeShape+_Time.y/15))-_SmoothMotionFactor;
				///////////////////////// 
				if( o.uv0.y > 0.1){
					posWorld.x += bulge*1*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) + _WaveXFactor*((2+cos(posWorld.x/dist))*_OceanCenter.x/5) + _WaveYFactor*((3+sin(2*posWorld.z/dist))*_OceanCenter.z/5);
					posWorld.z += bulge*1*sin(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*cos(posWorld.z+_Time.y) + _WaveXFactor*((2+sin(posWorld.z/dist))*_OceanCenter.z/5) + _WaveYFactor*((3+cos(3*posWorld.x/dist))*_OceanCenter.x/6);
				}
				if( o.uv0.y > 0.2){         
					posWorld.x += bulge*2*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) + _WaveXFactor*((2+cos(posWorld.x/dist))*_OceanCenter.x/3) + _WaveYFactor*((3+sin(2*posWorld.z/dist))*_OceanCenter.z/3);
					posWorld.z += bulge*2*sin(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*cos(posWorld.z+_Time.y) + _WaveXFactor*((2+sin(posWorld.z/dist))*_OceanCenter.z/3) + _WaveYFactor*((3+cos(3*posWorld.x/dist))*_OceanCenter.x/3); 
				}
				if( o.uv0.y > 0.3){

					posWorld.x += bulge*3*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) + _WaveXFactor*((2+cos(posWorld.x/dist))*_OceanCenter.x/3) + _WaveYFactor*((3+sin(2*posWorld.z/dist))*_OceanCenter.z/4);
					posWorld.z += bulge*3*sin(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*cos(posWorld.z+_Time.y) + _WaveXFactor*((2+sin(posWorld.z/dist))*_OceanCenter.z/3) + _WaveYFactor*((3+cos(3*posWorld.x/dist))*_OceanCenter.x/3);
				}
				if( o.uv0.y > 0.4){

					posWorld.x += bulge*4*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) + _WaveXFactor*((2+cos(posWorld.x/dist))*_OceanCenter.x/2) + _WaveYFactor*((3+sin(2*posWorld.z/dist))*_OceanCenter.z/2);
					posWorld.z += bulge*4*sin(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*cos(posWorld.z+_Time.y) + _WaveXFactor*((2+sin(posWorld.z/dist))*_OceanCenter.z/2) + _WaveYFactor*((3+cos(3*posWorld.x/dist))*_OceanCenter.x/2); 
				}   
				if( o.uv0.y > 0.96){

					posWorld.x += bulge*5*cos(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*sin(posWorld.z+_Time.y) + _WaveXFactor*((2+cos(posWorld.x/dist))*_OceanCenter.x/0.9) + _WaveYFactor*((3+sin(2*posWorld.z/dist))*_OceanCenter.z/1);
					posWorld.z += bulge*5*sin(posWorld.x*_WaveControl1.x+_Time.y*_TimeControl1.x + posWorld.z*_WaveControl1.z)*0.1*cos(posWorld.z+_Time.y) + _WaveXFactor*((2+sin(posWorld.z/dist))*_OceanCenter.z/0.9) + _WaveYFactor*((3+cos(3*posWorld.x/dist))*_OceanCenter.x/1);
				} 
				//ADD GLOBAL ROTATION - WIND            
				v.vertex = mul(unity_WorldToObject, posWorld);              
																																																																				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			fixed4 frag(VertexOutput i) : COLOR {
				float4 diffuseColor = tex2D(_Diffuse,TRANSFORM_TEX(i.uv0, _Diffuse));
				clip(diffuseColor.a - _Cutoff);

				float3 finalColor = diffuseColor.rgb *_ColorGlobal;
							
				return fixed4(finalColor,1);
			}
			ENDCG
		}
	}
	FallBack "Transparent/Cutout/Diffuse"			
}
