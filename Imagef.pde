//左下が原点の画像
class Imagef
{
  public Colorf[][] pixels;
  public int width, height;
  public Imagef(int row, int col)
  {
    this.width = row;
    this.height = col;
    pixels = new Colorf[row][col];
    for(int i=0; i<row; i++){
      for(int j=0; j<col; j++){
        pixels[i][j] = new Colorf();
      }
    }
    println("Imagef Constructor");
  }
  
  public PImage ToPImage()
  {
    PImage pImage = createImage(this.width, this.height, RGB);
    
    for(int i=0; i<this.width; i++)
    {
      for(int j=0; j<this.height; j++)
      {
        //PImageは左上が原点なので, jを反転させる
        pImage.pixels[(this.height-1-j)*this.width + i] = color(
        (int)(255*this.pixels[i][j].r),
        (int)(255*this.pixels[i][j].g), 
        (int)(255*this.pixels[i][j].b));
      }
    }
    return pImage;
  }
  
}
