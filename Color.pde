float f(float t)
{
  return (t > pow(6.f/29.f, 3.f)) ? pow(t, 1.f/3.f) : (1.f/3.f) * pow(29.f/6.f, 2.f) * t + (4.f/29.f);
}

float fi(float t)
{
  return (t > 6.f/29.f) ? pow(t, 3.f) : 3.f * pow(6.f/29.f, 2.f) * (t - (4.f/29.f));
}

final float[]  illuminant = new float[]{0.95047f, 1.00000f, 1.08883f}; // D65

FImage convert_srgb2Lab(final FImage input)
{
  final int w = input.width;
  final int h = input.height;

  FImage out = new FImage(w, h);

  float X, Y, Z;

  for (int y = 0; y < h; y++) 
  {
    for (int x = 0; x < w; x++) 
    {
      PVector rgb = input.get(x, y);

      float r = rgb.x;
      float g = rgb.y;
      float b = rgb.z;

      // RGB to XYZ
      // assuming sRGB (D65)
      if (r <= 0.04045f)
        r = r/12.92f;
      else
        r =  pow(((r + 0.055f) / 1.055f), 2.4f);

      if (g <= 0.04045f)
        g = g/12.92f;
      else
        g =  pow(((g + 0.055f) / 1.055f), 2.4f);

      if (b <= 0.04045f)
        b = b/12.92f;
      else
        b =  pow(((b + 0.055f) / 1.055f), 2.4f);

      //sRGB D65, http://brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
      final float[][] RGB2XYZ_MATRIX =
        {
        { 0.4124564f, 0.3575761f, 0.1804375f }, 
        { 0.2126729f, 0.7151522f, 0.0721750f }, 
        { 0.0193339f, 0.1191920f, 0.9503041f }
      };

      X = RGB2XYZ_MATRIX[0][0] * r + RGB2XYZ_MATRIX[0][1] * g + RGB2XYZ_MATRIX[0][2] * b;
      Y = RGB2XYZ_MATRIX[1][0] * r + RGB2XYZ_MATRIX[1][1] * g + RGB2XYZ_MATRIX[1][2] * b;
      Z = RGB2XYZ_MATRIX[2][0] * r + RGB2XYZ_MATRIX[2][1] * g + RGB2XYZ_MATRIX[2][2] * b;

      // XYZ to Lab      
      out.set(x, y, 
        116.f * f(Y / illuminant[1]) - 16.f, 
        500.f * (f(X/ illuminant[0]) - f(Y/ illuminant[1])), 
        200.f * (f(Y/ illuminant[1]) - f(Z/ illuminant[2])));
    }
  }
  return out;
}

FImage convert_Lab2srgb(final FImage input)
{
  final int w = input.width;
  final int h = input.height;

  FImage out = new FImage(w, h);

  float X, Y, Z, r, g, b;

  for (int y = 0; y < h; y++) 
  {
    for (int x = 0; x < w; x++) 
    {
      PVector Lab = input.get(x, y);

      // chromatic adaption, reference white
      Y = illuminant[1] * fi((1.f/116.f) * (Lab.x + 16.f)); // Y
      X = illuminant[0] * fi((1.f/116.f) * (Lab.x + 16.f) + (1.f/500.f) * Lab.y); // X
      Z = illuminant[2] * fi((1.f/116.f) * (Lab.x + 16.f) - (1.f/200.f) * Lab.z); // Z

      //sRGB D65, http://brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
      final float XYZ2RGB_MATRIX[][] =
        {
        { 3.2404542f, -1.5371385f, -0.4985314f }, 
        { -0.9692660f, 1.8760108f, 0.0415560f }, 
        { 0.0556434f, -0.2040259f, 1.0572252f }
      };

      r = XYZ2RGB_MATRIX[0][0] * X + XYZ2RGB_MATRIX[0][1] * Y + XYZ2RGB_MATRIX[0][2] * Z;
      g = XYZ2RGB_MATRIX[1][0] * X + XYZ2RGB_MATRIX[1][1] * Y + XYZ2RGB_MATRIX[1][2] * Z;
      b = XYZ2RGB_MATRIX[2][0] * X + XYZ2RGB_MATRIX[2][1] * Y + XYZ2RGB_MATRIX[2][2] * Z;

      if (r <= 0.0031308f)
        r = r * 12.92f;
      else
        r = 1.055f * pow(r, 1.0f / 2.4f) - 0.055f;
      if (g <= 0.0031308f)
        g = g * 12.92f;
      else
        g = 1.055f * pow(g, 1.0f / 2.4f) - 0.055f;
      if (b <= 0.0031308f)
        b = b * 12.92f;
      else
        b = 1.055f * pow(b, 1.0f / 2.4f) - 0.055f;
        
      out.set(x, y, r, g, b);
    }
  }
  return out;
}