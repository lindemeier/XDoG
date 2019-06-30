FImage quantize(final FImage img, final int nbins, final float phi_q)
{
  final int w = img.width;
  final int h = img.height;
  FImage out = new FImage(w, h, 3); 
  for (int y = 0; y < h; y++) 
  {    
    for (int x = 0; x < w; x++) 
    {
      PVector c = img.get(x, y);

      float qn = floor(c.x * (float)nbins + 0.5) / (float)nbins;
      float qs = smoothstep(-2.0, 2.0, phi_q * (c.x - qn) * 100.0) - 0.5;
      float qc = qn + qs / (float)nbins;
      out.set(x, y, qc, c.y, c.z);
    }
  }
  return out;
}

float smoothstep(final float edge0, final float edge1, final float x)
{
  float t = constrain((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}
