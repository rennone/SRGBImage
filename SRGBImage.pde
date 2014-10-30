import java.nio.*;
import java.lang.StringBuffer;
import java.io.FileWriter;
import java.io.*;
import java.awt.datatransfer.DataFlavor;  
import java.awt.datatransfer.Transferable;  
import java.awt.datatransfer.UnsupportedFlavorException;  
import java.awt.dnd.DnDConstants;  
import java.awt.dnd.DropTarget;  
import java.awt.dnd.DropTargetDragEvent;  
import java.awt.dnd.DropTargetDropEvent;  
import java.awt.dnd.DropTargetEvent;  
import java.awt.dnd.DropTargetListener;  
import java.io.File;  
import java.io.IOException;  
import java.util.List;
import java.util.Arrays;

/*
void setup()
{
  byte b[] = loadBytes("te_0[deg]_380nm_700nm_b.dat");
  println(b.length);
  ByteBuffer buffer = ByteBuffer.wrap(b);
  double[] d = new double[b.length/8];
  
  
  for(int i=0; i<d.length; i++)
  {
    d[i] = buffer.order(ByteOrder.LITTLE_ENDIAN).getDouble();  
  }
  
  PrintWriter writer = createWriter("text.txt");
  
  int l = 500-380;
  for(int i=0; i<360; i++)
  {  
    writer.println(d[360*l + i]);
  }
  writer.close();
  println(d.length / 360);
}
*/

DropTarget dropTarget;
final String Indication = "Drop folder";
final String Condition  = "Now Calculating";

void draw_progress(int percent)
{
  background(0);
  text("Now Calculating", width/2, height/2);
  text(percent+"%", width*3/4, height*3/4);
}

// バイナリからノルム(2乗強度)データを読み込み
double[] GetNormDataDouble(String path)
{
  //バイナリ読み込み
  byte b[] = loadBytes(path);
  ByteBuffer buffer = ByteBuffer.wrap(b);
  
  double[] d = new double[b.length/8];
  for(int i=0; i<d.length; i++){
    d[i] = buffer.order(ByteOrder.LITTLE_ENDIAN).getDouble();  
  }
  return d;
}

// ディレクトリ中のバイナリファイル(.dat)ファイルを集める
HashMap<String, File> GetBinaryFiles(File f)
{
  HashMap<String, File> binaries = new HashMap<String, File>();
  
  if( !f.isDirectory() ) return binaries;  

  File[] fileArray = f.listFiles();
  for(int i=0; i<fileArray.length; i++)
  {
    if( match(fileArray[i].getName(), ".dat$") != null )
    {
      binaries.put(fileArray[i].getName(), fileArray[i]);
    }
  }
  return binaries;
}

//波長と反射率からRGB値を計算して返す
color CalcRGB(double reflec, double lambda)
{
 // throw new exception.
 println("Calc RGB Not Implemented");
 return color(0,0,0); 
}

// sRGB画像の生成
PImage MakeSRGBImage(File TMFolder, File TEFolder, String parentPath)
{
  //TM TEフォルダの中にあるバイナリデータを取得
  HashMap<String, File> tmBinaries = GetBinaryFiles(TMFolder);
  HashMap<String, File> teBinaries = GetBinaryFiles(TEFolder);
  
  //TM TEでバイナリファイルの数が違ったらエラー
  if( tmBinaries.size() != teBinaries.size() )
  {
   println(parentPath + " : TM binary file differ from TE in number");
   return null;
  }
  
  //入射角の大きさ
  int delta_theta = 5;
  //バイナリファイルの数が足りなくてもエラー
  if( tmBinaries.size() < (90 / delta_theta + 1) )
  {
    println(parentPath + " : has not enough binary files in number");
    return null;
  }
  
  //丁度90°分しか無いときは対象にする.
  boolean symmetry = tmBinaries.size() == (90 / delta_theta) + 1;
  
  Imagef srgbImage = new Imagef(181, 181); //181° * 181°の画像 (入射角は0 ~ 180まで なので)
  
  //短波長と長波長, en-st+1 の波長のデータが必要
  int st_lambda = 380, en_lambda = 700;
  //thetaは入射角度を表す.
  for(int theta=0; theta <=180; theta+=delta_theta)
  {
    String str = (theta-180) + "[deg]_" + st_lambda + "_" + en_lambda + "nm.dat";
    
    //必要なバイナリデータが見つからないとエラー
    if( !tmBinaries.containsKey(str) || !teBinaries.containsKey(str))
    {
      println(parentPath + " : can not find binary file " + str);
      return null;
    } 
    
    double[] sqrEth = GetNormDataDouble(tmBinaries.get(str).getAbsolutePath());
    double[] sqrEph = GetNormDataDouble(teBinaries.get(str).getAbsolutePath());
    
    //EthとEphを足し合わせる.
    for(int i=0; i<sqrEth.length; i++)
    {
      sqrEth[i] += sqrEph[i];
    }
    
    //各派長データを反射角度phiで正規化する.
    for(int l=0; l<=en_lambda - st_lambda; l++)
    {
      int index = l*360;
      double sum = 0;
      //全角度で正規化
      for(int phi=0; phi<360; phi++)
      {
        sum += sqrEth[index + phi]; 
      }
      
      //画像にするのは180°まで
      for(int phi=0; phi<=180; phi++)
      {
        // reflecが theta[deg], l+st_lambda [nm], phi[deg]の時の反射率を表す
        double reflec = sqrEth[index+phi] / sum;
        
        //reflecからRGB値を計算して足し合わせる.
        srgbImage.pixels[theta][phi].Add( tr.CalcRGB(reflec, l+st_lambda) );
      }
    }
  }
  
  //線形補完
  for(int theta = 0; theta < 180; theta+=delta_theta) {
    for(int phi = 0; phi < 180; phi++){
      for(int i=1; i<delta_theta; i++){
        float p = 1.0*i/delta_theta;
        srgbImage.pixels[theta+i][phi] = Add( Mul(1.0-p, srgbImage.pixels[theta][phi]            ), 
                                              Mul(    p, srgbImage.pixels[theta+delta_theta][phi]) );
      }
    }
  }
  srgbImage.ToPImage().save(parentPath + "/color.bmp");
  return srgbImage.ToPImage();
}

// TM, TEフォルダのあるディレクトリまでネストしていく
void SearchBinary(String folderPath)
{  
  String TM_FOLDER = "TM_UPML";
  String TE_FOLDER = "TE_UPML"; 
  File dir = new File(folderPath);
  File[] fileArray = dir.listFiles();
  
  File tmFolder = null, teFolder = null;
  if (fileArray != null) 
  {
    for(int i = 0; i < fileArray.length; i++) 
    {
      File f = fileArray[i];
      if( !f.isDirectory() )    continue;
      
      //TMフォルダを見つけた
      if( f.getName().equals(TM_FOLDER) )
      {
        tmFolder = f;
        continue;
      }
      //TEフォルダを見つけた
      else if(f.getName().equals(TE_FOLDER) )
      {
        teFolder = f;
        continue;
      }
     //一つネストして探す 
      else {
        SearchBinary(f.getAbsolutePath());
      }
    }
  } 
  else{
    System.out.println(dir.toString() + " not found" );
    exit();    
  }
  
  //どっちも見つかれば, 画像を作る
  if( tmFolder != null && teFolder != null)
  {
    MakeSRGBImage(tmFolder, teFolder, folderPath);
  }  
}

ColorTransform tr;
Imagef testImg;
PImage img;
void setup()
{
  tr = new ColorTransform();
  dropTarget = new DropTarget(this, new DropTargetListener() 
  {
    public void dragEnter(DropTargetDragEvent e){}
    public void dragOver(DropTargetDragEvent e){}
    public void dropActionChanged(DropTargetDragEvent e) {}
    public void dragExit(DropTargetEvent e) {}  
    public void drop(DropTargetDropEvent e) {
      e.acceptDrop(DnDConstants.ACTION_COPY_OR_MOVE);
      Transferable trans = e.getTransferable();
      List<File> fileNameList = null;
      if(trans.isDataFlavorSupported(DataFlavor.javaFileListFlavor)){
        try{
          fileNameList = (List<File>)trans.getTransferData(DataFlavor.javaFileListFlavor);
        }catch(UnsupportedFlavorException ex){
          //
        } catch(IOException ex){
          //
        }
      }
      if(fileNameList == null)     return;
      
      background(0);
      text("Now Calculating", width/2, height/2);
      for(File f : fileNameList)
      {
        println(f.getName());
        if( f.isDirectory() )
        {
          SearchBinary(f.getAbsolutePath());
        }
      }
      
      //background(0);
      //text("drop folder", width/2, height/2);
    }  
  });
  
  size(400, 400);
  textAlign(CENTER);
  textSize(32);
  testImg = new Imagef(width, height);
  for(int i=0; i<testImg.width; i++)
  {
    for(int j=0; j<testImg.height; j++)
    {
      testImg.pixels[i][j] = tr.CalcRGB(150.0, i+380);//.Mul(255) ;
      
    }
  };
  img = testImg.ToPImage();
}

void draw()
{
  background(0);
  image(img, 0,0);
}

