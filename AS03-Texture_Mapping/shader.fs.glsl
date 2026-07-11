#version 330

in vec2 texCoord;
in vec3 vertex_color;
in vec3 vertex_normal;
in vec3 model_pos;
in vec3 light_pos;

out vec4 fragColor;

struct Material
{
    vec3 Ka;
    vec3 Kd;
    vec3 Ks;
};
struct Light
{
    int mode;
    vec3 pos[3];
    float cutoff;// dergee
    vec3 diffuse_intensity[3];
    float shininess;
};
uniform mat4 mvp;
uniform mat4 ModelView;
uniform mat4 Viewing;
uniform Material material;
uniform Light light;
uniform int isPerPixel;

const int Exponent = 50;
const vec3 Ambient_intensity = vec3(0.15,0.15,0.15);
const vec3 Specular_intensity = vec3(1,1,1);
const vec3 Directional_light_dir = vec3(0,0,0);
const vec3 Spot_light_dir = vec3(0,0,-1);
struct Attenuation
{
	float constant;
	float linear;
	float quadratic;
};
const Attenuation Point_light = Attenuation(0.01,0.8,0.1);
const Attenuation Spot_light = Attenuation(0.05,0.3,0.6);

// [TODO] passing texture from main.cpp
// Hint: sampler2D
uniform sampler2D tex;

void main() {

	// [TODO] sampleing from texture
	// Hint: texture
    vec3 Main_camera_pos = (Viewing * vec4(vec3(0.0, 0.0, 2.0),1.0)).xyz;// (0,0,0)
    vec3 I, IA, ID, IS;
    vec3 normalized_n, L, normalized_L, H, normalized_H;
    float d;

    normalized_n = normalize(vertex_normal);
    if(light.mode==0)
        L = light_pos - (Viewing * vec4(Directional_light_dir, 1.0)).xyz;
    else
        L = light_pos - model_pos;
    normalized_L = normalize(L);
    H = L + (Main_camera_pos-model_pos);
    normalized_H = normalize(H);
    d = length(light_pos-model_pos);

    IA = Ambient_intensity * material.Ka;
    ID = max(dot(normalized_L,normalized_n),0.0) * light.diffuse_intensity[light.mode] * material.Kd;
    IS = pow(max(dot(normalized_H,normalized_n),0.0),light.shininess) * Specular_intensity * material.Ks;

    if(light.mode==0){
        
    } else if(light.mode==1){
        float attenuation = ( 1 / (Point_light.constant + Point_light.linear * d + Point_light.quadratic * d * d) );
        ID *= attenuation;
        IS *= attenuation;
    } else if(light.mode==2){
        float attenuation = ( 1 / (Spot_light.constant + Spot_light.linear * d + Spot_light.quadratic * d * d) );
        float spotlight_effect;
        vec3 d = normalize((Viewing * vec4(Spot_light_dir,1.0)).xyz);
        
        if(dot(-1*normalized_L,d)>=cos(radians(light.cutoff))){
            spotlight_effect = pow(max(dot(-1*normalized_L,d),0.0),Exponent);
        }
        else{
            spotlight_effect = 0;
        }
        ID = attenuation * spotlight_effect * ID;
        IS = attenuation * spotlight_effect * IS;
    }

    I=IA+ID+IS;
    if(isPerPixel==1)
        fragColor = vec4(I, 1.0f);
    else
        fragColor = vec4(vertex_color, 1.0f);

    fragColor *= texture(tex, texCoord);
}
