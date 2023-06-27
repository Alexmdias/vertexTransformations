uniform vec3 remotePosition;

void main() {
	//Paint it red
	gl_FragColor = vec4(1,remotePosition*0.2); //je multiplie par 0.2 pour que le changement de couleur soit plus graduel
}