void run_fdog_0(final FImage img, FImage dst, FImage tfm, 
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
      final PVector ht = img.get(uv.x, uv.y);
      PVector sum = new PVector(ht.x, ht.x, 0.f);
      PVector norm = new PVector(1.0, 1.0, 0.f);

      float halfWidth = 2.0 * sigma_r / sqrt(n.x*n.x+n.y*n.y);
      for (int d = 1; d <= halfWidth; d++) 
      {
        // kernel for both gaussians
        float[] kernel = new float[]{exp( -d * d / twoSigmaESquared), 
          exp( -d * d / twoSigmaRSquared)};
        norm.x += 2.0 * kernel[0];
        norm.y += 2.0 * kernel[1];

        PVector L0 =  img.get(uv.x - d*n.x, uv.y - d*n.y);
        PVector L1 =  img.get(uv.x + d*n.x, uv.y + d*n.y);  
        L0.y = L0.x;
        L1.y = L1.x;

        sum.x += kernel[0] * ( L0.x + L1.x);
        sum.y += kernel[1] * ( L0.y + L1.y);
      }
      sum.x /= norm.x;
      sum.y /= norm.y;

      // DoG operation
      float diff = (sum.x - tau * sum.y);
      dst.set(x, y, diff, diff, diff);
    }
  }
}

void run_fdog_1(final FImage img, FImage dst, FImage tfm, 
  final float sigma_m, final float phi)
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
      float H = img.get(x, y).x;

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
        H += k * img.get(a.p.x, a.p.y).x;
        wg += k;
      }
      while (b.w < halfWidth) 
      {
        step(tfm, b);
        float k = b.dw * exp(-b.w * b.w / twoSigmaMSquared); // TODO check b.dw
        H += k * img.get(b.p.x, b.p.y).x;
        wg += k;
      }
      H /= wg;

      float edge = ( H > 0.0 )? 1.0 : 2.0 * smoothstep(-2.0, 2.0, phi * H );
      dst.set(x, y, edge, edge, edge);
    }
  }
}

float sign(float x)
{
  return (x <= 0.f) ? -1.f : 1.f;
}

void step(final FImage tfm, lic_t s) 
{
  PVector t = tfm.get(s.p.x, s.p.y);
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

float smoothstep(final float edge0, final float edge1, final float x)
{
  float t = constrain((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

class lic_t 
{ 
  PVector p = new PVector(); 
  PVector t = new PVector();
  float w;
  float dw;
};
