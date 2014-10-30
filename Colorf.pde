class Colorf
{
  public float r,g,b;
  public Colorf()
  {
    r = g = b = 0;
  }
  
  public Colorf(float r, float g, float b)
  {
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  public Colorf(Colorf c)
  {
    this.r = c.r;
    this.g = c.g;
    this.b = c.b;
  }
  
  public Colorf Add(Colorf c)
  {
    this.r += c.r;
    this.g += c.g;
    this.b += c.b;
    
    return this;
  }
  
  public Colorf Mul(float k)
  {
    this.r *= k;
    this.g *= k;
    this.b *= k;
    
    return this;
  }
  
  public Colorf Cpy()
  {
    return new Colorf(this);
  }
}
  public Colorf Add(Colorf a, Colorf b)
  {
    return new Colorf(a.r + b.r, a.g + b.g, a.b + b.b);
  }
  
  public Colorf Mul(Colorf a, float k)
  {
    return new Colorf(a.r*k, a.g*k, a.b*k);
  }
  
  public Colorf Mul(float k, Colorf a)
  {
    return Mul(a, k);
  }
