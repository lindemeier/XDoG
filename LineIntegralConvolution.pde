
FImage computeLineIntegralConvolution(final FImage tfm, final float sigma)
{
  final int w = tfm.width;
  final int h = tfm.height;
  FImage out = new FImage(w, h, 3); 

  final float step = 1.;

  final int l = (int)(2.0f * floor( sqrt(-log(0.1f) * 2 * (sigma*sigma)) ) + 1.0f);

  PImage noise = createImage(w, h, RGB);
  for (int i = 0; i < noise.pixels.length; i++) 
  {
    noise.pixels[i] = color(random(0, 255));
  }
  noise.filter(THRESHOLD, 0.5);

  for (int y = 0; y < h; y++) 
  {    
    for (int x = 0; x < w; x++) 
    {        
      float c = 0;

      PVector v0 = tfm.get(x, y);

      float x_ = x;
      float y_ = y;

      float g = 0;

      // forward 
      for (int i = 0; i < l/2; i++)
      {       
        PVector v1 = new PVector(tfm.getSingleInterpolated(x_, y_, 0), 
          tfm.getSingleInterpolated(x_, y_, 1), 
          tfm.getSingleInterpolated(x_, y_, 2));

        if (v1.dot(v0) < 0.f) v1.mult(-1);

        x_ += v1.x*step;
        y_ += v1.y*step; 

        if (x_ < 0.f || x_ >= w || y_ < 0.f || y_ >= h) break;        

        v0 = v1;

        float gw = exp(-(i*i) / (2.f*sigma*sigma));
        c += gw * red(noise.get((int)x_, (int)y_));
        g+=gw;
      }
      v0 = tfm.get(x, y).mult(-1);
      x_ = x;
      y_ = y;
      // backward 
      for (int i = 0; i < l/2; i++)
      {       
        PVector v1 = new PVector(tfm.getSingleInterpolated(x_, y_, 0), 
          tfm.getSingleInterpolated(x_, y_, 1), 
          tfm.getSingleInterpolated(x_, y_, 2)).mult(-1);

        if (v1.dot(v0) < 0.f) v1.mult(-1);

        x_ += v1.x*step;
        y_ += v1.y*step;

        if (x_ < 0.f || x_ >= w || y_ < 0.f || y_ >= h) break;

        v0 = v1;

        float gw = exp(-(i*i) / (2.f*sigma*sigma));
        c += gw * red(noise.get((int)x_, (int)y_));
        g+=gw;
      }
      //final float lambda = tfm.get(x, y).z;
      //color blend = lerpColor(color(c / g), color(255, 0, 0), lambda);
      //out.set(x, y, red(blend) / 255.f, green(blend) / 255.f, blue(blend) / 255.f);
      out.set(x, y, (c / g) / 255.f, (c / g) / 255.f, (c / g) / 255.f);
    }
  }

  return out;
}

void drawArrows(final FImage tfm)
{
  final int w = tfm.width;
  final int h = tfm.height;

  final int cs = 15;
  final int o = 5;
  
  pushStyle();

  stroke(0, 255, 0);
  for (int y = 0; y < h; y+=cs) 
  {    
    for (int x = 0; x < w; x+=cs) 
    {        
      PVector v = tfm.get(x, y);
      final int r = (cs-1)/2;
      final int cx = x + r;
      final int cy = y + r;

      line(cx - o*v.x, cy - o*v.y, cx + o*v.x, cy + o*v.y);
    }
  }
  
  popStyle();
}
