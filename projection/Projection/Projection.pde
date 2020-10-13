/**
 * draws a 2D projection of higher-dimensional cubes.
 * by Alexander Cai
 */

final float DIST = 2.;
final float BOX_WIDTH = 22;

int MAXDIM = 9;
int DIM = 3; // the number of dimensions

// whether or not each dimension is being projected using perspective or orthogonal
boolean pers[] = new boolean[MAXDIM];

float[][] vertices = new float[npoints(MAXDIM)][MAXDIM]; // the original vertices of the cube
float[][] proj = new float[npoints(MAXDIM)][2]; // the projected vertices in 2D

// track a few keys
boolean rPressed = false, fPressed = false;

// angles in different directions
// I'm pretty sure this is what makes rotation wonky but let's leave it
float[][] theta = new float[MAXDIM][MAXDIM];
int[][] auto = new int[MAXDIM][MAXDIM];

// pairs of connections
boolean connected[][] = new boolean[npoints(MAXDIM)][npoints(MAXDIM)];

float rotSpeed = 0.001; // rotation speed
float len = 200; // zoom level

boolean paused = false;

void setup() {
  size(640, 640);
  generateVertices();
}

void draw() {
  background(0);
  drawInfoBox();
  drawRotateGrid();

  translate(width/2, height/2); // (0, 0) becomes the center of the screen
  stroke(255);
  strokeWeight(5);

  for (int i = 0; i < npoints(); ++i) {
    // Java actually doesn't bother with the length when assigning arrays like this,
    // so this makes proj[i] have a length of 4 instead of 2. Dumb Java.
    proj[i] = vertices[i];

    // handle rotation across several planes
    for (int r = 0; r < DIM; ++r) {
      for (int c = r+1; c < DIM; ++c) {
        proj[i] = matrixByVector(rotation(r, c, theta[r][c]), proj[i]);
        if (auto[r][c] != 0) {
          theta[r][c] += auto[r][c] * rotSpeed;
        }
      }
    }

    for (int j = DIM; j > 2; --j) {
      if (pers[j-1])
        proj[i] = perspec(proj[i]);
      else
        proj[i] = orthogonal(proj[i]);
    }

    for (int j = 0; j < proj[i].length; ++j)
      proj[i][j] *= len;
  }

  for (int i = 0; i < npoints(); ++i) {
    point(proj[i][0], proj[i][1]);
    for (int j = i; j < npoints(); ++j)
      if (connected[i][j])
        line(proj[i][0], proj[i][1], proj[j][0], proj[j][1]);
  }

  // zoom in/out
  if (rPressed)
    len *= 1.02;
  if (fPressed)
    len /= 1.02;
}

void mousePressed() {
  if (mouseX > 10 && mouseX < 110 && mouseY > 10 && mouseY < 10 + DIM * getTextHeight())
    for (int i = 0; i < DIM; ++i)
      if (mouseY > 10 + i * getTextHeight() && mouseY < 10 + (i+1) * getTextHeight())
        pers[i] = !pers[i];

  if (mouseX > 10 && mouseX < 10 + getTextHeight()
    && mouseY > 10+DIM*getTextHeight() && mouseY < 10+(DIM+1)*getTextHeight())
    setDim(DIM-1);

  if (mouseX > 100-getTextHeight() && mouseX < 100
    && mouseY > 10+DIM*getTextHeight() && mouseY < 10+(DIM+1)*getTextHeight())
    setDim(DIM+1);

  // if click on rotation box
  float boxLeft = width-5-BOX_WIDTH*DIM;
  if (
    mouseX > boxLeft
    && mouseX < width-5
    && mouseY > 5+BOX_WIDTH
    && mouseY < 5+BOX_WIDTH*(DIM+1)) {
    int xc = int((mouseX - boxLeft) / BOX_WIDTH);
    int yc = int((mouseY - (5+BOX_WIDTH)) / BOX_WIDTH);
    if (xc > yc) {
      switch(auto[yc][xc]) {
      case 0:
        auto[yc][xc] = 1;
        break;
      case 1:
        auto[yc][xc] = -1;
        break;
      default:
        auto[yc][xc] = 0;
        break;
      }
    }
  }
}

// a few menu options
void keyPressed() {
  if (key == ' ')
    for (int r = 0; r < DIM; ++r)
      for (int c = 0; c < DIM; ++c)
        theta[r][c] = auto[r][c] = 0;
  if (key == 'w' && DIM < MAXDIM)
    setDim(DIM+1);
  if (key == 's' && DIM > 3)
    setDim(DIM-1);
  if (key == 'e') rotSpeed *= 1.5;
  if (key == 'd') rotSpeed /= 1.5;
  if (key == 'r') rPressed = true;
  if (key == 'f') fPressed = true;

  // toggle pause screen
  if (key == 'h') {
    if (!paused) {
      paused = true;
      textSize(20);
      drawPauseScreen();
      noLoop();
    } else {
      paused = false;
      textSize(12);
      loop();
    }
  }
}

void keyReleased() {
  if (key == 'r') rPressed = false;
  if (key == 'f') fPressed = false;
}
