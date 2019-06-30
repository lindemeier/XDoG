FImage computefDoG(final FImage img, FImage tfm, 
  final float sigma_e, final float sigma_r, final float tau, final float sigmaSmoothing)
{
  FImage out = new FImage(img. width, img.height, 1);

  // compute DoG
  fdogAlongGradient(img, out, tfm, sigma_e, sigma_r, tau);
  // smooth along etf
  FImage outSmooth = new FImage(img. width, img.height, 1);
  smoothAlongFlow(out, outSmooth, tfm, sigmaSmoothing);

  return out;
}

void fdogAlongGradient(final FImage img, FImage dst, FImage tfm, 
  final float sigma_e, final float sigma_r, final float tau)
{
  final float twoSigmaESquared = 2.0 * sigma_e * sigma_e;
  final float twoSigmaRSquared = 2.0 * sigma_r * sigma_r;

  final int w = img.width;
  final int h = img.height;

  for (int y = 0; y < h; y++) 
  {    
    for (int x = 0; x < w; x++) 
    {
      final PVector uv = new PVector(x, y, 0.f);
      final PVector t = tfm.get(constrain((int)round(uv.x), 0, w-1), constrain((int)round(uv.y), 0, h-1)); // nearest neighbor
      PVector n = new PVector(t.y, -t.x, 0.); // along gradient not tangent
      if (abs(n.x) >= abs(n.y))
      {
        n.y = n.y / n.x;
        n.x = 1.f;     
        n.z = 0.;
      } else
      {
        n.x = n.x / n.y;
        n.y = 1.f;
        n.z = 0;
      }    
      final float ht = img.getSingleInterpolated(uv.x, uv.y, 0);

      float sumG0 = ht;
      float sumG1 = ht;
      float normG0 = 1.0;
      float normG1 = 1.0;

      float halfWidth = 2.0 * sigma_r / sqrt(n.x*n.x+n.y*n.y);
      for (int d = 1; d <= halfWidth; d++) 
      {
        // kernel for both gaussians
        float[] kernel = new float[]{exp( -d * d / twoSigmaESquared), 
          exp( -d * d / twoSigmaRSquared)};
        normG0 += 2.0 * kernel[0];
        normG1 += 2.0 * kernel[1];

        float backwardsValue =  img.getSingleInterpolated(uv.x - d*n.x, uv.y - d*n.y, 0);
        float forwardsValue =  img.getSingleInterpolated(uv.x + d*n.x, uv.y + d*n.y, 0);  

        // only Luminance used
        float accumValues = backwardsValue + forwardsValue;

        sumG0 += kernel[0] * accumValues;
        sumG1 += kernel[1] * accumValues;
      }
      sumG0 /= normG0;
      sumG1 /= normG1;

      // DoG operation
      dst.setSingle(x, y, 0, (sumG0 - tau * sumG1));
    }
  }
}

void smoothAlongFlow(final FImage img, FImage dst, FImage tfm, 
  final float sigma_m)
{
  final float twoSigmaMSquared = 2.0 * sigma_m * sigma_m;
  final float halfWidth = 2.0 * sigma_m;
  final int w = img.width;
  final int h = img.height;

  for (int y = 0; y < h; y++) 
  {    
    for (int x = 0; x < w; x++) 
    {
      final PVector uv = new PVector(x, y, 0.f);
      float wg = 1.0;
      float H = img.getSingle(x, y, 0);

      lic_t a = new lic_t(), b = new lic_t();
      a.p.x = b.p.x = uv.x;
      a.p.y = b.p.y = uv.y;
      a.t = tfm.get(x, y);
      b.t = tfm.get(x, y);
      b.t.mult(-1);
      a.w = b.w = 0.0;

      while (a.w < halfWidth) 
      {
        step(tfm, a);
        float k = a.dw * exp(-a.w * a.w / twoSigmaMSquared); // TODO check a.dw
        H += k * img.getSingleInterpolated(a.p.x, a.p.y, 0);
        wg += k;
      }
      while (b.w < halfWidth) 
      {
        step(tfm, b);
        float k = b.dw * exp(-b.w * b.w / twoSigmaMSquared); // TODO check b.dw
        H += k * img.getSingleInterpolated(b.p.x, b.p.y, 0);
        wg += k;
      }
      H /= wg;

      dst.setSingle(x, y, 0, H);
    }
  }
}

float sign(float x)
{
  return (x <= 0.f) ? -1.f : 1.f;
}

void step(final FImage tfm, lic_t s) 
{
  PVector t = new PVector(tfm.getSingleInterpolated(s.p.x, s.p.y, 0), 
    tfm.getSingleInterpolated(s.p.x, s.p.y, 1), 
    tfm.getSingleInterpolated(s.p.x, s.p.y, 2));
  if (t.dot(s.t) < 0.0) t.mult(-1);
  s.t.x = t.x;
  s.t.y = t.y;

  s.dw = (abs(t.x) >= abs(t.y))? 
    abs(((s.p.x - floor(s.p.x)) - 0.5 - sign(t.x)) / t.x) : 
    abs(((s.p.y - floor(s.p.y)) - 0.5 - sign(t.y)) / t.y);

  s.p.x += t.x * s.dw;
  s.p.y += t.y * s.dw;
  s.w += s.dw;
}

class lic_t 
{ 
  PVector p = new PVector(); 
  PVector t = new PVector();
  float w;
  float dw;
};
