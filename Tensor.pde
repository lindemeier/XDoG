


FImage computeStructureTensors(final FImage img)
{
  final int w = img.width;
  final int h = img.height;

  PImage mag = createImage(w, h, RGB);

  FImage tensors = new FImage(w, h); 
  for (int y = 0; y < h; y++) 
  {
    for (int x = 0; x < w; x++) 
    {
      final PVector uv = new PVector(x, y, 0.);      
      final PVector d = new PVector(1, 1, 0.);

      PVector dx = new PVector();
      PVector dy = new PVector();

      dx.x = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).x +
        -2.0 * img.get(uv.x - d.x, uv.y).x + 
        -1.0 * img.get(uv.x - d.x, uv.y + d.y).x +
        +1.0 * img.get(uv.x + d.x, uv.y - d.y).x +
        +2.0 * img.get(uv.x + d.x, uv.y).x + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).x
        ) / 4.0;
      dx.y = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).y +
        -2.0 * img.get(uv.x - d.x, uv.y).y + 
        -1.0 * img.get(uv.x - d.x, uv.y + d.y).y +
        +1.0 * img.get(uv.x + d.x, uv.y - d.y).y +
        +2.0 * img.get(uv.x + d.x, uv.y).y + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).y
        ) / 4.0;
      dx.z = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).z +
        -2.0 * img.get(uv.x - d.x, uv.y).z + 
        -1.0 * img.get(uv.x - d.x, uv.y + d.y).z +
        +1.0 * img.get(uv.x + d.x, uv.y - d.y).z +
        +2.0 * img.get(uv.x + d.x, uv.y).z + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).z
        ) / 4.0;


      dy.x = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).x +
        -2.0 * img.get(uv.x, uv.y - d.y).x + 
        -1.0 * img.get(uv.x + d.x, uv.y - d.y).x +
        +1.0 * img.get(uv.x - d.x, uv.y + d.y).x +
        +2.0 * img.get(uv.x, uv.y + d.y).x + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).x
        ) / 4.0;
      dy.y = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).y +
        -2.0 * img.get(uv.x, uv.y - d.y).y + 
        -1.0 * img.get(uv.x + d.x, uv.y - d.y).y +
        +1.0 * img.get(uv.x - d.x, uv.y + d.y).y +
        +2.0 * img.get(uv.x, uv.y + d.y).y + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).y
        ) / 4.0;
      dy.z = (
        -1.0 * img.get(uv.x - d.x, uv.y - d.y).z +
        -2.0 * img.get(uv.x, uv.y - d.y).z + 
        -1.0 * img.get(uv.x + d.x, uv.y - d.y).z +
        +1.0 * img.get(uv.x - d.x, uv.y + d.y).z +
        +2.0 * img.get(uv.x, uv.y + d.y).z + 
        +1.0 * img.get(uv.x + d.x, uv.y + d.y).z
        ) / 4.0;


      tensors.set(x, y, dx.dot(dx), dx.dot(dy), dy.dot(dy));

      float gm = 255.*sqrt(pow(dx.x+dx.y+dx.z, 2) + pow(dy.x+dy.y+dy.z, 2));
      mag.set(x, y, color(gm));
    }
  }
  //mag.save("data/gradient_magnitude.jpg");
  return tensors;
}

// major eigenvalue
float getLambda1(final FImage tensors, int x, int y)
{
  PVector g = tensors.get(x, y);
  final float E = g.x;
  final float F = g.y;
  final float G = g.z;

  final float det = sqrt(pow(E - G, 2.f) + 4.f * F*F);
  return (E + G + det) * 0.5f;
}

// minor eigenvalue
float getLambda2(final FImage tensors, int x, int y)
{
  PVector g = tensors.get(x, y);
  final float E = g.x;
  final float F = g.y;
  final float G = g.z;

  final float det = sqrt(pow(E - G, 2.f) + 4.f * F*F);
  return (E + G - det) * 0.5f;
}

// major eigenvector
PVector getV1(final FImage tensors, int x, int y)
{
  PVector g = tensors.get(x, y);
  final float E = g.x;
  final float F = g.y;
  final float G = g.z;

  final float det = sqrt(pow(E - G, 2.f) + 4.f * F*F);
  return new PVector(2.f*F, G - E + det, 0.f);
}

// minor eigenvector
PVector getV2(final FImage tensors, int x, int y)
{
  PVector g = tensors.get(x, y);
  final float E = g.x;
  final float F = g.y;
  final float G = g.z;

  final float det = sqrt(pow(E - G, 2.f) + 4.f * F*F);
  return new PVector(2.f*F, G - E - det, 0.f);
}


FImage computeTangentFlowMap(FImage tensors)
{
  final int w = tensors.width;
  final int h = tensors.height;

  FImage tfm = new FImage(w, h); 
  for (int y = 0; y < h; y++) 
  {
    for (int x = 0; x < w; x++) 
    {      
      final float lambda = getLambda2(tensors, x, y);
      PVector v = getV2(tensors, x, y);  

      float m = sqrt(v.x*v.x+v.y*v.y);
      if (m > 0.f)
      {
        v.x /= m;
        v.y /= m;
        tfm.set(x, y, v.x, v.y, sqrt(lambda));
      } else
      {
        tfm.set(x, y, 0, 1, 0);
      }
    }
  }
  return tfm;
}