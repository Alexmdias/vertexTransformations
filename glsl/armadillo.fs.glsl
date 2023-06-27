// Create shared variable. The value is given as the interpolation between normals computed in the vertex shader
in vec3 interpolatedNormal;
uniform int time;
uniform sampler2D fft;
uniform vec3 controller; // les trois controlleurs : controller.x, controller.y et controller.z


void main() {

  // Set final rendered color according to the surface normal
  gl_FragColor = vec4(normalize(interpolatedNormal), 1.0) ;
  //gl_FragColor = vec3(1.0,remotePosition);
}
