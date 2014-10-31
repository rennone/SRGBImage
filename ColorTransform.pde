import java.io.*;
import java.util.List;
import java.util.Arrays;
import java.nio.*;
import java.lang.StringBuffer;
import java.io.FileWriter;
class ColorTransform
{  
  HashMap<Integer, Float> X, Y, Z, S;
  float K;
  int minLambda, maxLambda;
  
  public Colorf CIE_ToRGB(float x, float y, float z)
  {
    float r =  2.3655*x - 0.8971*y - 0.4683*z;
    float g = -0.5151*x + 1.4264*y + 0.0887*z;
    float b =  0.0052*x - 0.0144*y + 1.0089*z;
   return new Colorf(r,g,b); 
  }
  
  public Colorf D65_ToRGB(float x, float y, float z)
  {
    float r =  3.2410*x - 1.5374*y - 0.4986*z;
    float g = -0.9692*x + 1.8760*y + 0.0416*z;
    float b =  0.0556*z - 0.2040*y + 1.5070*z;
    return new Colorf(r,g,b);
  }
  
  public Colorf CalcRGB(double reflec, Integer lambda)
  {
    if( !S.containsKey(lambda) ) return new Colorf();
    
    float s = (float)S.get(lambda);
    float x = (float)(K * reflec * X.get(lambda) * s);
    float y = (float)(K * reflec * Y.get(lambda) * s);
    float z = (float)(K * reflec * Z.get(lambda) * s);
    return D65_ToRGB(x,y,z); 
  }
  
  float minX = 1000, maxX = 0, minY = 1000, maxY = 0;
  
  public ColorTransform()
  {
    X = new HashMap<Integer, Float>();
    Y = new HashMap<Integer, Float>();
    Z = new HashMap<Integer, Float>();
    S = new HashMap<Integer, Float>();
    K = 0.0;
    String lines[] = loadStrings("XYZS.csv");
    for(int i=0; i<lines.length; i++)
    {
      String[] params = split(lines[i], ",");
      int l = parseInt(params[0]);
      float x = parseFloat(params[1]);
      float y = parseFloat(params[2]);
      float z = parseFloat(params[3]);
      float s = parseFloat(params[4]);
      X.put(l, x);
      Y.put(l, y);
      Z.put(l, z);
      S.put(l, s);
      K += y*s;
      minX = min(minX, l);
      maxX = max(maxX, l);
      minY = min( minY, min(x, min(y, z)));
      maxY = max( maxY, max(x, max(y, z)));  
    }  
    minLambda = (int)minX;
    maxLambda = (int)maxX;
    K = 200 / K;
    println(K);
  }
  
  private ColorTransform(ColorTransform c){}
  
  void drawGraph()
  {
    float dx = width / (maxX - minX);
    float dy = height /(maxY - minY);
    for( Integer k : X.keySet() )
    {
      float l = (k-minX)*dx; 
      float x = (X.get(k)-minY)*dy;
      float y = (Y.get(k)-minY)*dy;
      float z = (Z.get(k)-minY)*dy;
      float s = (S.get(k)-minY)*dy;
      
      point(l, height - x);
      point(l, height - y);
      point(l, height - z);
      point(l, height - s);
    }
  }
}
