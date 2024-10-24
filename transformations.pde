/*
 @author: Massiles GHERNAOUT (github.com/MassiGy)
 
 Motivation & Goal:
 =================
 
 The idea behind this little sketch is to understand how we can go from modal/world space to view space.
 Put differently, how to go from 3D to 2D.
 
 With this sketch, I took a simple 3D model that is a cube ( without the edges ) and the cartesian axes.
 I apply transformations on their coordinates ( Vectors ) using matrices ( 3x3 matrices to respect the homogeneous
 coordinates system ). Then I apply a perspective matrix on them that does nothing to our coordinates ( idMatrix ).
 
 After that, we project from the 3D world space to the 2D view space using our projection matrix which is an orthogonal
 projection matrix. This works just fine since our animation is at the center of the view space and no distance or z depth
 accountability is needed for the end result overall fidelity.
 
 Of course all of this is home made and we do not use a 3D renderer. Here we use the java 2D renderer, thus we do everything
 on the CPU. For more mainstream applications using a 3D renderer is better for this since it uses the GPU through shaders.
 
 Here we stick to the basics for the depth of knowledge gain, thus we use P2D and not P3D.( see the size routine )
 
 */




float edgeLen = 100;
PVector[] points = {
  new PVector(0.5, 0.5, -0.5),
  new PVector(0.5, -0.5, -0.5),
  new PVector(-0.5, 0.5, -0.5),
  new PVector(-0.5, -0.5, -0.5),

  new PVector(0.5, 0.5, 0.5),
  new PVector(0.5, -0.5, 0.5),
  new PVector(-0.5, 0.5, 0.5),
  new PVector(-0.5, -0.5, 0.5),
};

float infinity = 150;
float epsilon = 0.0001;
PVector worldOrig = new PVector(0, 0, epsilon);  // make sure that z is not equal to 0 for the normalization

PVector[] axes = {
  new PVector(infinity, 0, 0),
  new PVector(0, infinity, 0),
  new PVector(0, 0, infinity),
};


boolean useMouseForRotations = false;
float theta = 0.0;

float[][] idMatrix = {
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 1},
};

float[][] perspectiveMatrix = idMatrix; // No perspective ( z depth and fov not taken into account )


float[][] projectionMatrix = {
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 0}, // orthogonal projection ( x->x, y->y, z->void )
};

float[][] toCenterTransltationMatrix;


float[][] transp_rotateX;
float[][] transp_rotateY;
// float[][] transp_rotateZ; // No Z transforms since we use an orthogonal projection

void setup() {
  size(400, 400, P2D);


  /* Initialization of our world space */

  toCenterTransltationMatrix = new float[][]{
    {1, 0, width/2},
    {0, 1, height/2},
    {0, 0, 1}
  };

  println("origin is @", worldOrig);

  // @note: we could of just added a translate2D vector (w/2, h/2, 0)
  // this will allow us to be more performant and remove the epsilon costraint.
  // I just want to do it all with matricies.
  worldOrig = TMat3xVect3D(
    transposeMat3(normalizeTranslation3DMatrixByZ(toCenterTransltationMatrix, worldOrig)),
    worldOrig
    );

  for (int i = 0; i < points.length; i++) {
    points[i] = points[i].mult(edgeLen);
  }
}

void draw() {
  background(255); // reset the screen



  /* Rehydrate our transformation matricies */


  if (!useMouseForRotations) {
    // either transform using an variadic angle (theta)
    transp_rotateX = transposeMat3(calcRotateXmat(theta));
    transp_rotateY = transposeMat3(calcRotateYmat(theta));

    // once transforms matricies are computed, incr theta for next frame
    theta += 0.02;
  } else {
    // or tranfrom using the mouse movements
    transp_rotateX = transposeMat3(calcRotateXmat(calcAngleFromMouseY()));
    transp_rotateY = transposeMat3(calcRotateYmat(calcAngleFromMouseX()));
  }



  //Cube Verticies Transformations
  for (PVector p : points) {

    /* Transformations on our points ( world space - 3D )*/
    PVector transformedP = TMat3xVect3D(transp_rotateX, p);
    transformedP = TMat3xVect3D(transp_rotateY, transformedP);
    PVector translatedP = transformedP.add(worldOrig);


    /* Perspective projection of our points (world space -> view space ) */
    PVector inPerspectiveP = TMat3xVect3D(transposeMat3(perspectiveMatrix), translatedP);
    PVector projectedP = TMat3xVect3D(transposeMat3(projectionMatrix), inPerspectiveP);

    /* Rendering our points ( view space - 2D ) */
    stroke(0);
    strokeWeight(16); // make the points a bit bold
    point(projectedP.x, projectedP.y);
  }

  //Axes End Verticies Transfromations
  for (PVector a : axes ) {

    /* Transformations on our axies ( world space - 3D )*/
    PVector transformedA = TMat3xVect3D(transp_rotateX, a);
    transformedA = TMat3xVect3D(transp_rotateY, transformedA);
    PVector translatedA = transformedA.add(worldOrig);


    /* Perspective projection of our axies ( wold space -> view space ) */
    PVector inPerspectiveA = TMat3xVect3D(transposeMat3(perspectiveMatrix), translatedA);
    PVector projectedA = TMat3xVect3D(transposeMat3(projectionMatrix), inPerspectiveA);

    /* Rendering our axies ( view space - 2D )*/
    stroke(0);
    strokeWeight(3); // make the axis line a bit bold


    if (a.x != 0)
      stroke(255, 0, 0);  // x axis
    else if (a.y != 0)
      stroke(0, 255, 0);  // y axis
    else if (a.z != 0)
      stroke(0, 0, 255);  // z axis
    line(worldOrig.x, worldOrig.y, projectedA.x, projectedA.y);
  }

  /* Record animation */
  // saveFrame("frames/transformations_demo_####.tif");
}


float[][] transposeMat3(float[][] mat) {
  float[][] tmat = new float[3][3];
  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      tmat[i][j] = mat[j][i];

  return tmat;
}

PVector TMat3xVect3D(float[][] transposedMat, PVector vect) {
  PVector res;
  // Mat3 * Vect3 = col1(Mat3) * Vect3.x + col2(Mat3) * Vect3.y + col3(Mat3) * Vect3.z
  // colN(Mat3) = rowN(TMat3)
  res = (new PVector(transposedMat[0][0], transposedMat[0][1], transposedMat[0][2])).mult(vect.x);
  res = res.add((new PVector(transposedMat[1][0], transposedMat[1][1], transposedMat[1][2])).mult(vect.y));
  res = res.add((new PVector(transposedMat[2][0], transposedMat[2][1], transposedMat[2][2])).mult(vect.z));

  return res;
}

float[][] calcRotateXmat(float angle) {
  float[][] rotateXmat = {
    {1, 0, 0},
    {0, cos(angle), -sin(angle)},
    {0, sin(angle), cos(angle)}
  };
  return rotateXmat;
}

float[][] calcRotateYmat(float angle) {
  float[][] rotateYmat = {
    {cos(angle), 0, sin(angle) },
    {0, 1, 0},
    {-sin(angle), 0, cos(angle)}
  };
  return rotateYmat;
}

// float[][] calcRotateZmat(float angle) {}  // No Z transforms since we use an orthogonal projection


float[][] normalizeTranslation3DMatrixByZ(float[][] in, PVector v) {
  float[][] out = new float[3][3];

  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      out[i][j] = in[i][j];


  // @note: maybe raise an exception ?
  if (v.z == 0.0)
    return null;

  out[0][2] /= v.z;
  out[1][2] /= v.z;

  return out;
}

float calcAngleFromMouseY() {
  float speed = 0.02;
  float a = ((mouseY * speed) % TWO_PI) * (-1); // inversely to the y axis

  return a;
}
float calcAngleFromMouseX() {
  float speed = 0.02;
  float a = (mouseX * speed) % TWO_PI;

  return a;
}

void mousePressed() {
  toggleMouseControl();
}

void toggleMouseControl() {
  useMouseForRotations = !useMouseForRotations;
}
