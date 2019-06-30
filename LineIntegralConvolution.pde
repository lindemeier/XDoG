
FImage computeLineIntegralConvolution(final FImage tfm, final float sigma)
{
  final int w = tfm.width;
  final int h = tfm.height;
  FImage out = new FImage(w, h, 1); 

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
        PVector v1 = tfm.get(x_, y_);

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
        PVector v1 = tfm.get(x_, y_).mult(-1);

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
      out.setSingle(x, y, 0, (c / g) / 255.f);
    }
  }

  return out;
}
