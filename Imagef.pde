class Imagef
{
  public Colorf[][] pixels;
  public int width, height;
  public Imagef(int row, int col)
  {
    this.width = row;
    this.height = col;
    pixels = new Colorf[row][col];
  }
  
  public PImage ToPImage()
  {
    PImage pImage = createImage(this.width, this.height, RGB);
    
    for(int i=0; i<this.width; i++)
    {
      for(int j=0; j<this.height; j++)
      {
        pImage.pixels[j*this.width + i] = color(this.pixels[i][j].r,this.pixels[i][j].g, this.pixels[i][j].b);
      }
    }
    return pImage;
  }
  
}
