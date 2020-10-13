// generate the vertices of a N-dimensional cube and connect them
void generateVertices() {
  for (int c = 0; c < npoints(); ++c) {
    for (int d = 0; d < DIM; ++d) {
      vertices[c][d] = (((c >> d) & 1)*2-1);
      connected[c][c ^ (1 << d)] = true;
    }
  }
}

// get number of points using the current dimension
int npoints() {
  return npoints(DIM);
}

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
