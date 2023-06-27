// Create shared variable for the vertex and fragment shaders
out vec3 interpolatedNormal;
uniform int time;
uniform sampler2D fft;
uniform vec3 controller; // les trois controlleurs : controller.x, controller.y et controller.z

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
	vec3 a = floor(p);
	vec3 d = p - a;
	d = d * d * (3.0 - 2.0 * d);

	vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
	vec4 k1 = perm(b.xyxy);
	vec4 k2 = perm(k1.xyxy + b.zzww);

	vec4 c = k2 + a.zzzz;
	vec4 k3 = perm(c);
	vec4 k4 = perm(c + 1.0);

	vec4 o1 = fract(k3 * (1.0 / 41.0));
	vec4 o2 = fract(k4 * (1.0 / 41.0));

	vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
	vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

	return o4.y * d.y + o4.x * (1.0 - d.y);
}

// rotation autour de l'axe Y
mat3 rotationY(float theta) {
	return mat3(
	vec3(cos(theta), 0, sin(theta)),
	vec3(0, 1, 0),
	vec3(-sin(theta), 0, cos(theta))
	);
}

void main() {

	// Get components of sounds from the FFT texture
	float fft_bass = texture(fft, vec2(0.1, 0.0)).x;
	float fft_middle = texture(fft, vec2(0.25, 0.0)).x;
	float fft_treble = texture(fft, vec2(0.3, 0.0)).x;

	//fait spin l'armadillo sur lui même en fonction du temps
	mat3 spinY = rotationY(min(float(time)*controller.y*4.0,float(time)*0.4));
	//je le fait tourner puis je le translate sur x, en résultat ca le fait tourner autour d'un pivot grand selon l'intentité du controlleur
	vec3 pivot = position * spinY + vec3(controller.y, 0, 0) * spinY ;//rotation, translation, rotation!
	//nouvelle position quand l'armadillo tourne autour du pivot
	vec4 new_position = vec4(pivot,1.0);
	//je twist l'ardmadillo selon un certain angle qui est déterminer par fft_bass, et par le controlleur. Il ressemble a une tornade quand il se fait twist
	float angle = fft_bass *controller.y*10.0* new_position.y;
	//formule pour twist un objet : x'= x*cos(angle)-z*sin(angle)	y'=y	z'=x*sin(angle)+z*cos(angle)
	vec4 twist = vec4(cos(angle) * new_position.x - sin(angle) * new_position.z, new_position.y, sin(angle) * new_position.x + cos(angle) * new_position.z, 1.0);

	//je le fait sauter sur y, en fonction du temps et de fft_middle
	vec4 jumpY = vec4(1.0,(cos(float(time))+1.0)*10.0*fft_middle* controller.x,1.0,1.0);

	gl_Position = projectionMatrix * modelViewMatrix * twist + jumpY;

	//glitch prend la position x des vertices et le met dans une fonction sin avec le temps, mutliplier par fft_middle de la musique. Puis, je l'ajoute à la position x des vertices
	//ca fait en sorte que l'armadillo se multiplie sur l'axe des x quand un fft_middle est présent dans la musique
	//ça fait un effet glitch plutot cool, comme si l'armadillo recevait les ondes de la musique à travers son corp :p
	float glitch = sin(gl_Position.x * float(time))*controller.z * fft_middle;
	gl_Position.x += glitch;

	//selon le noise et le temps, rend l'armadillo "invisible". la transformation fait des spot vide créer par la fonction sinusoidale du noise et du temps manipuler par le controlleur
	//la fonction noise prend la normal de l'armadillo avec le temps en input.
	float invisible = sin(noise(normal) * float(time))*controller.z*0.5; //on peut le voir à travers le sol!
	gl_Position.z += invisible;


	//fait dancer l'armadillo. En gros il suit une onde sinusoidale, dépendamment de sa position sur le temps multiplier par sin(gl_position.z),
	//avec un facteur noise sur la position et le temps pour randomizer un peu la dance. Seulement la position y des vertices est modifier pour onduler.
	float danceY = (sin(gl_Position.z)*sin(float(time))*noise(vec3(new_position.x,new_position.y,new_position.z)*sin(float(time))))*controller.x*0.4;
	gl_Position.y += danceY;

	//change les couleurs de l'armadillo selon le temps
	vec3 rainbow = normal - normal * vec3(sin(float(time)),sin(float(time))-cos(float(time)),cos(float(time)))*controller.x;
	//change la couleur des vertices selon leurs positions. Je rajoute du bruit en fonction du temps pour donner un effet de grain à la couleur selon l'intensité du controlleur
	vec3 position_color = vec3(new_position.x,1.0+cos(new_position.y*float(time)*noise(normal)),new_position.z)*controller.y; //noise+temps change la couleur en y
	//quand on rend l'armadillo invisible en changant le 3ieme controller, selon le bruit et le temps il augmente sa quantité de bleu.
	//la fonction est étrange par exprès pour rester dans le thème du glitch étrange pour le 3ieme controlleur!
	vec3 glitch_color = normal + vec3(0.5,0.5,max(cos(noise(float(time)*position)),0.5)) *controller.z;

	interpolatedNormal = rainbow  + position_color + glitch_color;
}
