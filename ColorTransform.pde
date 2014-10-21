import java.io.*;
import java.util.List;
import java.util.Arrays;
import java.nio.*;
import java.lang.StringBuffer;
import java.io.FileWriter;
class ColorTransform
{  
  HashMap<Integer, Float> R, G, B, S;
  float K;
  
  public color CalcRGB(double reflec, Integer lambda)
  {
    float s = (float)S.get(lambda);
    float r = (float)(K * reflec * R.get(lambda) * s);
    float g = (float)(K * reflec * G.get(lambda) * s);
    float b = (float)(K * reflec * B.get(lambda) * s);
    return color(r,g,b); 
  }
  
  public void AddRGB(double reflec, Integer lambda, Float r, Float g, Float b)
  {
    float s = (float)S.get(lambda);
    r += K * reflec * R.get(lambda) * s;
    g += K * reflec * G.get(lambda) * s;
    b += K * reflec * B.get(lambda) * s;
  }
  
  public void AddRGB(double reflec, Integer lambda, Colorf c)
  {
    float s = (float)S.get(lambda);
    c.r += K * reflec * R.get(lambda) * s;
    c.g += K * reflec * G.get(lambda) * s;
    c.b += K * reflec * B.get(lambda) * s;
  }
  
  float minX = 1000, maxX = 0, minY = 1000, maxY = 0;
  
  public ColorTransform()
  {
    R = new HashMap<Integer, Float>();
    G = new HashMap<Integer, Float>();
    B = new HashMap<Integer, Float>();
    S = new HashMap<Integer, Float>();
    K = 0.0;
    String lines[] = loadStrings("XYZS.csv");
    for(int i=0; i<lines.length; i++)
    {
      String[] params = split(lines[i], ",");
      int l = parseInt(params[0]);
      float r = parseFloat(params[1]);
      float g = parseFloat(params[2]);
      float b = parseFloat(params[3]);
      float s = parseFloat(params[4]);
      R.put(l, r);
      G.put(l, g);
      B.put(l, b);
      S.put(l, s);
      K += g*s;
      minX = min(minX, l);
      maxX = max(maxX, l);
      minY = min( minY, min(r, min(g, b)));
      maxY = max( maxY, max(r, max(g, b)));  
    }  
    
    K = 200 / K;
  }
  
  private ColorTransform(ColorTransform c){}
  
  void drawGraph()
  {
    float dx = width / (maxX - minX);
    float dy = height /(maxY - minY);
    for( Integer x : R.keySet() )
    {
      float l = (x-minX)*dx; 
      float r = (R.get(x)-minY)*dy;
      float g = (G.get(x)-minY)*dy;
      float b = (B.get(x)-minY)*dy;
      float s = (S.get(x)-minY)*dy;
      
      point(l, height - r);
      point(l, height - g);
      point(l, height - b);
      point(l, height - s);
    }
  }  
}
