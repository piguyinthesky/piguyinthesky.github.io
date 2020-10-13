// generate the vertices of a N-dimensional cube and connect them
void generateVertices() {
  for (int c = 0; c < npoints(DIM); ++c) {
    for (int d = 0; d < DIM; ++d) {
      vertices[c][d] = (((c >> d) & 1)*2-1);
      connected[c][c ^ (1 << d)] = true;
    }
  }
}

// get number of points using the current dimension
int npoints(int dim) {
  return int(pow(2, dim));
}

// simply takes off the last dimension of a vector
float[] orthogonal(float[] vec) {
  if (vec.length <= 2) throw new Error("Can only project down to 2D!");
  float[] ans = new float[vec.length - 1];
  for (int i = 0; i < vec.length - 1; ++i)
    ans[i] = vec[i];
  return ans;
}

// generates a perspective projection of a vector
float[] perspec(float[] vec) {
  if (vec.length <= 2) throw new Error("Can only project down to 2D!");
  int newLen = vec.length - 1;
  float w = 1. / (DIST - vec[newLen]);
  float[] ans = new float[newLen];
  for (int i = 0; i < newLen; ++i)
    ans[i] = w * vec[i];
  return ans;
}

// multiply a matrix by a vector
float[] matrixByVector(float[][] proj, float[] vec) {
  // *technically* the number of columns in a matrix needs to equal the number of rows in a vector
  // in order for you to be able to multiply them
  // but here I was too lazy to check for lengths throughout so I just take the minimum of the two
  int newLen = min(proj[0].length, vec.length);
  float[] ans = new float[newLen];

  for (int row = 0; row < newLen; ++row)
    for (int col = 0; col < newLen; ++col) {
      float k = vec[col];
      float j = proj[row][col];
      ans[row] += j * k;
    }

  return ans;
}

/**
 * axis1 and axis2 define the plane we want to rotate around
 * I'm pretty sure rotating around a plane loses meaning in greater than 4 dimensions but whatever
 */
float[][] rotation(int axis1, int axis2, float theta) {
  float[][] ans = new float[DIM][DIM];

  if (axis1 == axis2) throw new Error("must provide two different axes");

  // we make sure axis1 is less than axis2
  if (axis1 > axis2) {
    int temp = axis1;
    axis1 = axis2;
    axis2 = temp;
  }

  // check for the indicated rows and columns and apply the rotation coordinates to them
  for (int r = 0; r < DIM; ++r) {
    if (r == axis1) {
      ans[r][r] = cos(theta);
      ans[r][axis2] = -sin(theta);
    } else if (r == axis2) {
      ans[r][axis1] = sin(theta);
      ans[r][r] = cos(theta);
    } else {
      ans[r][r] = 1;
    }
  }

  return ans;
}

// draw an information box in the top left
void drawInfoBox() {
  fill(255);
  rect(5, 5, 100, 10 + (DIM+1) * getTextHeight());
  fill(0);
  textAlign(LEFT, TOP);
  int i = 0;
  for (; i < DIM; ++i)
    text("DIM " + (i+1) + ": " + (pers[i] ? "PERSP" : "ORTHO"), 10, 10 + i * getTextHeight());
  rect(10, 10+i*getTextHeight(), getTextHeight(), getTextHeight());
  rect(100-getTextHeight(), 10+i*getTextHeight(), getTextHeight(), getTextHeight());

  fill(255);

  i += 2;
  text("FPS: " +int(frameRate), 10, 10 + (i++)*getTextHeight());
  text("Press h for help", 10, 10 + (i--)*getTextHeight());

  i -= 2;
  textAlign(CENTER, CENTER);
  text('-', 10+getTextHeight()/2., 10+(i+.5-.1)*getTextHeight());
  text('+', 100-getTextHeight()/2., 10+(i+.5-.1)*getTextHeight());
}

// draws a grid in the top right which the user can click on to rotate the cube
void drawRotateGrid() {
  float boxLeft = width-5-BOX_WIDTH*(DIM+1);
  rect(boxLeft, 5, BOX_WIDTH*(DIM+1), BOX_WIDTH*(DIM+1));
  fill(0);

  stroke(0);
  strokeWeight(1);
  textAlign(CENTER, CENTER);

  for (int i = 1; i <= DIM; ++i) {
    text(i, boxLeft + BOX_WIDTH*(i+0.5), 15); // header
    text(i, boxLeft+BOX_WIDTH/2., 5+BOX_WIDTH*(i+0.5)); // vertical header
    line(boxLeft + BOX_WIDTH*i, 5, boxLeft + BOX_WIDTH*i, 5+BOX_WIDTH*(DIM+1));
    line(boxLeft, 5+BOX_WIDTH*i, width - 5, 5+BOX_WIDTH*i);
    for (int j = 1; j <= DIM; ++j) {
      float t = 5+i*BOX_WIDTH;
      float l = boxLeft+j*BOX_WIDTH;
      if (i >= j) {
        line(l, t, l+BOX_WIDTH, t+BOX_WIDTH);
        line(l+BOX_WIDTH, t, l, t+BOX_WIDTH);
      } else if (auto[i-1][j-1] != 0) {
        char c = auto[i-1][j-1] > 0 ? '+' : '-';
        text(c, l+BOX_WIDTH/2., t+BOX_WIDTH/2.);
      }
    }
  }
}

String[] help = {
  "press h to hide/show this menu", 
  "click in the top-left menu to toggle projection methods", 
  "click in the top-right grid to rotate", 
  "use e/d to +/- rotate speed", 
  "use w/s to +/- dimensions", 
  "use r/f to zoom in/out"
};

void drawPauseScreen() {
  background(0);
  fill(255);
  resetMatrix();
  textAlign(CENTER, CENTER);

  text("HELP", width / 2., height / 4.);
  for (int i = 0; i < help.length; ++i) {
    text(help[i], width / 2., height * 3./8. + (i+1) * getTextHeight());
  }
}

float getTextHeight() {
  return (textAscent() + textDescent()) * 1.5;
}

void setDim(int dim) {
  DIM = dim;
  generateVertices();
}

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

  for (int i = 0; i < npoints(DIM); ++i) {
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

  for (int i = 0; i < npoints(DIM); ++i) {
    point(proj[i][0], proj[i][1]);
    for (int j = i; j < npoints(DIM); ++j)
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
