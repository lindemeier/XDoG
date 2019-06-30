// floating point rgb
class FImage
{
  private float[] data = null;

  int width, height;

  FImage(PImage source)
  {
    setPImage(source);
  }

  FImage(FImage other)
  {
    this.width = other.width;
    this.height = other.height;
    if (data == null || data.length != other.data.length)
    {
      data = new float[other.data.length];
    }
    for (int i = 0; i < other.data.length; i++)
    {      
      data[i] = other.data[i];
    }
  }

  FImage(int w, int h)
  {
    this.width = w;
    this.height = h;
    data = new float[w*h*3];
  }

  void setPImage(final PImage source)
  {
    this.width = source.width;
    this.height = source.height;
    if (data == null || data.length != source.pixels.length*3)
    {
      data = new float[source.pixels.length*3];
    }
    for (int i = 0; i < source.pixels.length; i++)
    {
      color c = source.pixels[i];

      int index = i*3;
      data[index] = red(c) / 255.f;
      data[index+1] = green(c) / 255.f;
      data[index+2] = blue(c) / 255.f;
    }
  }

  PImage toPImage()
  {
    PImage image = createImage(this.width, this.height, RGB);
    for (int i = 0; i < image.pixels.length; i++)
    {
      int index = i*3;
      image.pixels[i] = color(data[index]*255.f, data[index+1]*255.f, data[index+2]*255.f);
    }
    return image;
  }

  private void setSingle(int x, int y, int c, float v)
  {
    data[3*(y*this.width+x)+c] = v;
  }

  private float getSingle(int x, int y, int c)
  {
    return data[3*(y*this.width+x)+c];
  }

  PVector get(int x, int y)
  {
    return new PVector(getSingle(x, y, 0), getSingle(x, y, 1), getSingle(x, y, 2));
  }

  // bilinear interpolation
  PVector get(float xp, float yp)
  {
    final int x = floor(xp);
    final int y = floor(yp);

    final int x0 = border(x, this.width);
    final int x1 = border(x+1, this.width);
    final int y0 = border(y, this.height);
    final int y1 = border(y+1, this.height);

    final float a = xp - (float)(x);
    final float c = yp - (float)(y);

    PVector r = new PVector();
    r.x = (getSingle(x0, y0, 0) * (1.f - a) + getSingle(x1, y0, 0) * a) * (1.f - c)
      + (getSingle(x0, y1, 0) * (1.f - a) + getSingle(x1, y1, 0) * a) * c;
    r.y = (getSingle(x0, y0, 1) * (1.f - a) + getSingle(x1, y0, 1) * a) * (1.f - c)
      + (getSingle(x0, y1, 1) * (1.f - a) + getSingle(x1, y1, 1) * a) * c;
    r.z = (getSingle(x0, y0, 2) * (1.f - a) + getSingle(x1, y0, 2) * a) * (1.f - c)
      + (getSingle(x0, y1, 2) * (1.f - a) + getSingle(x1, y1, 2) * a) * c;
    return r;
  }

  void set(int x, int y, float r, float g, float b)
  {
    setSingle(x, y, 0, r);
    setSingle(x, y, 1, g);
    setSingle(x, y, 2, b);
  }

  void set(int x, int y, PVector v)
  {
    setSingle(x, y, 0, v.x);
    setSingle(x, y, 1, v.y);
    setSingle(x, y, 2, v.z);
  }

  private int border(int pos, int axisLength)
  {
    // pos lies in image
    if (pos < axisLength && pos >= 0) return pos;

    if (axisLength == 1) return 0;

    do
    {
      if (pos < 0)
      {
        pos = -pos - 1;
      } else
      {
        pos = axisLength - 1 - (pos  - axisLength);
      }
    }  
    while ( abs(pos) >= abs(axisLength) );

    return pos;
  }
}