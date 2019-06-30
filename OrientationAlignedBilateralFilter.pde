FImage filterOrientationAlignedBilateral(final FImage sourceLab, final FImage tfm, final float sigma_d, final float sigma_r, int n)
{
  final int w = sourceLab.width;
  final int h = sourceLab.height;

  FImage t0 = new FImage(w, h, 3);  
  FImage t1 = new FImage(sourceLab);  

  for (int i = 0; i < n; i++)
  {
    run_oabf(0, t1, t0, tfm, sigma_d, sigma_r);
    run_oabf(1, t0, t1, tfm, sigma_d, sigma_r);
  }  

  return t1;
}

void run_oabf(int pass, final FImage sourceLab, FImage target, final FImage tfm, final float sigma_d, final float sigma_r)
{
  final int w = sourceLab.width;
  final int h = sourceLab.height;

  for (int y = 0; y < h; y++) 
  {
    for (int x = 0; x < w; x++) 
    {        
      final PVector uv = new PVector(x, y, 0.f);
      final PVector tangent = new PVector(tfm.getSingleInterpolated(uv.x, uv.y, 0), 
        tfm.getSingleInterpolated(uv.x, uv.y, 1), 
        tfm.getSingleInterpolated(uv.x, uv.y, 2));
      PVector t = (pass == 0) ? new PVector(tangent.y, -tangent.x, 0.f) : tangent;    

      if (abs(t.x) >= abs(t.y))
      {
        t.y = t.y / t.x;
        t.x = 1.f;     
        t.z = 0.;
      } else
      {
        t.x = t.x / t.y;
        t.y = 1.f;
        t.z = 0;
      }      

      final PVector center = new PVector(sourceLab.getSingleInterpolated(uv.x, uv.y, 0), 
        sourceLab.getSingleInterpolated(uv.x, uv.y, 1), 
        sourceLab.getSingleInterpolated(uv.x, uv.y, 2));
      PVector sum = new PVector();
      sum.x = center.x;
      sum.y = center.y;
      sum.z = center.z;

      float norm = 1;
      float halfWidth = (2.0 * sigma_d) / sqrt(t.x*t.x+t.y*t.y);

      //println("t: " + t + "  h: " + halfWidth);

      for (int d = 1; d <= halfWidth; d++) 
      {
        final float uxn = uv.x + d * t.x;
        final float uyn = uv.y + d * t.y;
        final float uxp = uv.x - d * t.x;
        final float uyp = uv.y - d * t.y;

        PVector c0 = new PVector(sourceLab.getSingleInterpolated(uxn, uyn, 0), 
          sourceLab.getSingleInterpolated(uxn, uyn, 1), 
          sourceLab.getSingleInterpolated(uxn, uyn, 2));
        PVector c1 = new PVector(sourceLab.getSingleInterpolated(uxp, uyp, 0), 
          sourceLab.getSingleInterpolated(uxp, uyp, 1), 
          sourceLab.getSingleInterpolated(uxp, uyp, 2));

        float e0 = sqrt(pow(c0.x-center.x, 2.f) + pow(c0.y-center.y, 2.f) + pow(c0.z-center.z, 2.f));
        float e1 = sqrt(pow(c1.x-center.x, 2.f) + pow(c1.y-center.y, 2.f) + pow(c1.z-center.z, 2.f));

        float kerneld = exp(-(d*d) / (2.f*sigma_d*sigma_d));
        float kernele0 = exp(-(e0*e0) / (2.f*sigma_r*sigma_r));
        float kernele1 = exp(-(e1*e1) / (2.f*sigma_r*sigma_r));      

        norm += kerneld * kernele0;
        norm += kerneld * kernele1;

        sum.x += kerneld * kernele0 * c0.x;
        sum.y += kerneld * kernele0 * c0.y;
        sum.z += kerneld * kernele0 * c0.z;

        sum.x += kerneld * kernele1 * c1.x;
        sum.y += kerneld * kernele1 * c1.y;
        sum.z += kerneld * kernele1 * c1.z;
      }
      sum.x /= norm;
      sum.y /= norm;
      sum.z /= norm;
      target.set(x, y, sum);
    }
  }
}
