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
  for (int c = 0; c < f.channels; c++) 
  {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {  
        // center pixel
        float sum = kernel[r] * f.getSingle(x, y, c);      

        // neighbor pixels
        for (int i = 1; i <= r; ++i)    
        {
          float a = f.getSingle(x, f.border(y-i, h), c);
          float b = f.getSingle(x, f.border(y+i, h), c);

          sum += kernel[r+i] * b; 
          sum += kernel[r-i] * a;
        }
        out.setSingle(x, y, c, sum);
      }
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
  for (int c = 0; c < f.channels; c++) 
  {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {   

        // center pixel
        float sum = kernel[r] * f.getSingle(x, y, c);

        // neighbor pixels
        for (int i = 1; i <= r; ++i)    
        {
          float a = f.getSingle(f.border(x-i, w), y, c);
          float b = f.getSingle(f.border(x+i, w), y, c);

          sum += kernel[r+i] * b;  

          sum += kernel[r-i] * a;  
        }
        out.setSingle(x, y, c, sum);
      }
    }
  }
  return out;
}
