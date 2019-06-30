FImage GaussianBlur(final FImage f, float sigma)
{
  final int k_size = (int)(2.0f * floor( sqrt(-log(0.1f) * 2 * (sigma*sigma)) ) + 1.0f);
  final int r = (k_size - 1) / 2;
  final float sigmasquare = sigma * sigma;

  // compute gaussian kernel
  float[] kernel = new float[k_size];
  for (int i = -r; i <= r; ++i)
  {
    kernel[i+r] = exp(-i*i/(2*sigmasquare)) / (sqrt(sigmasquare*TWO_PI));
  }

  // normalize kernel
  float sum = 0;
  for (int j = 0; j < kernel.length; ++j)
  {
    sum += kernel[j];
  }

  for (int j = 0; j < kernel.length; ++j)
  {
    kernel[j] = (kernel[j] / sum);
  }

  return convolveVertical1D(convolveHorizontal1D(f, kernel), kernel);
}


FImage convolveVertical1D(final FImage f, float[] kernel) 
{
  final int k_len = kernel.length;
  final int r = (k_len - 1) / 2;
  final int w = f.width;
  final int h = f.height;

  FImage out = new FImage(w, h, f.channels); 
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {        
      PVector sum = new PVector(0.f, 0.f, 0.f);

      // center pixel
      PVector center = f.get(x, y);
      sum.x += kernel[r] * center.x;
      sum.y += kernel[r] * center.y;
      sum.z += kernel[r] * center.z;

      // neighbor pixels
      for (int i = 1; i <= r; ++i)    
      {
        PVector a = f.get(x, f.border(y-i, h));
        PVector b = f.get(x, f.border(y+i, h));

        sum.x += kernel[r+i] * b.x;  
        sum.y += kernel[r+i] * b.y;  
        sum.z += kernel[r+i] * b.z;  

        sum.x += kernel[r-i] * a.x;  
        sum.y += kernel[r-i] * a.y;  
        sum.z += kernel[r-i] * a.z;
      }
      out.set(x, y, sum);
    }
  }
  return out;
}

FImage convolveHorizontal1D(final FImage f, float[] kernel) 
{
  final int k_len = kernel.length;
  final int r = (k_len - 1) / 2;
  final int w = f.width;
  final int h = f.height;

  FImage out = new FImage(w, h, f.channels); 
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {        
      PVector sum = new PVector(0.f, 0.f, 0.f);

      // center pixel
      PVector center = f.get(x, y);
      sum.x += kernel[r] * center.x;
      sum.y += kernel[r] * center.y;
      sum.z += kernel[r] * center.z;

      // neighbor pixels
      for (int i = 1; i <= r; ++i)    
      {
        PVector a = f.get(f.border(x-i, w), y);
        PVector b = f.get(f.border(x+i, w), y);

        sum.x += kernel[r+i] * b.x;  
        sum.y += kernel[r+i] * b.y;  
        sum.z += kernel[r+i] * b.z;  

        sum.x += kernel[r-i] * a.x;  
        sum.y += kernel[r-i] * a.y;  
        sum.z += kernel[r-i] * a.z;
      }
      out.set(x, y, sum);
    }
  }
  return out;
}
