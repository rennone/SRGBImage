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
import java.util.Stack;
import java.util.Queue;
import java.util.ArrayDeque;
class ImageData
{
  public PImage image;
  public String path;
}


DropTarget dropTarget;
final String Indication = "Drop folder";
final String Condition  = "Now Calculating";
ColorTransform tr;
PImage img;
boolean checked = false;
ArrayList<ImageData> images = new ArrayList<ImageData>();
//ArrayList<ImageData> savedImages = new ArrayList<ImageData>();

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


// sRGB画像の生成
ImageData MakeSRGBImage(File TMFolder, File TEFolder, String parentPath)
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
  boolean symmetry = (tmBinaries.size() == ((90 / delta_theta) + 1));
  
  println("start transforming " + parentPath);
  Imagef srgbImage = new Imagef(181, 181); //181° * 181°の画像 (入射角は0 ~ 180まで なので)
  
  //短波長と長波長, en-st+1 の波長のデータが必要
  int st_lambda = 380, en_lambda = 700;
  
  int en_theta = symmetry ? 90 : 180;
  //thetaは入射角度を表す.
  for(int theta=0; theta <=en_theta; theta+=delta_theta)
  {
    String str = (theta-180) + "[deg]_" + st_lambda + "nm_" + en_lambda + "nm_b.dat";
    
    //必要なバイナリデータが見つからないとエラー
    if( !tmBinaries.containsKey(str) || !teBinaries.containsKey(str))
    {
      println(parentPath + " : can not find binary file " + str);
      return null;
    } 
    
    double[] sqrEth = GetNormDataDouble(tmBinaries.get(str).getAbsolutePath());
    double[] sqrEph = GetNormDataDouble(teBinaries.get(str).getAbsolutePath());

    //EthとEphを足し合わせる.
    for(int i=0; i<sqrEth.length; i++){
      sqrEth[i] += sqrEph[i];
    }
    //各派長データを反射角度phiで正規化する.
    for(int l=0; l<=en_lambda - st_lambda; l++){
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
        //reflecからXYZ値を計算して足し合わせる.
        srgbImage.pixels[theta][phi].Add( tr.CalcXYZ(reflec, l+st_lambda) );
      }
    }
    //RGB変換
    for(int phi=0; phi<=180; phi++){
      srgbImage.pixels[theta][phi] = tr.D65_ToRGB(srgbImage.pixels[theta][phi].r, 
      srgbImage.pixels[theta][phi].g,
      srgbImage.pixels[theta][phi].b);
    }
  }

  //線形補完
  for(int theta = 0; theta < 180; theta+=delta_theta) {
    for(int phi = 0; phi <= 180; phi++){
      for(int i=1; i<delta_theta; i++){
        float p = 1.0*i/delta_theta;
        srgbImage.pixels[theta+i][phi] = Add( Mul(1.0-p, srgbImage.pixels[theta][phi]            ), 
                                              Mul(    p, srgbImage.pixels[theta+delta_theta][phi]) );
      }
    }
  }
  
  if(symmetry)
  {    
    for(int theta = 0; theta < 90; theta++){
      for(int phi = 0; phi <= 180; phi++){
        srgbImage.pixels[180-theta][180-phi] = srgbImage.pixels[theta][phi];
      }
    }
  }
  //println("saving");
  //srgbImage.ToPImage().save(parentPath + "/color.bmp");
  //println("finish");
  ImageData data = new ImageData();
  data.image = srgbImage.ToPImage();
  data.path  = parentPath;
  data.image.save(data.path + "/original_color.bmp");
  return data;
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
    ImageData img = MakeSRGBImage(tmFolder, teFolder, folderPath);

    if(img !=null){
      synchronized(images){
        images.add(img);
      }      
    }
  }
}

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
      if(fileNameList == null)     
      return;

      for(File f : fileNameList){
        if( f.isDirectory() )
        {
          SearchBinary(f.getAbsolutePath());
        }
      }
      
      checked = true;
    }
  });
  
  strokeWeight(1);
  stroke(255);
  size(200, 200);
  textAlign(CENTER);
  textSize(32);
  
  secondFrame = new PFrame(this);
  secondFrame.size(400,400);
    
  secondFrame.textAlign(LEFT);
  secondFrame.textSize(12);
}

ImageData image = null;
int scale = 2;
PFrame secondFrame;
int drawingNo = 0;
void draw()
{
  background(0);
  
  if(!checked)
  {
    text(images.size() + " images", width/2, height/2);
    drawSecond();
    return;
  } 
  
  //現在の画像を保存する.  
  if(image != null)
  {
    PImage img = image.image;
    this.image(img, 0,0, width, height);
    save(image.path + "/color.bmp");
    drawFrame(img.width*scale, img.height*scale, false);
    save(image.path + "/frame_color.bmp");
  }
  
  //あれば次の画像をとってきてサイズを変える.
  synchronized (images)
  {    
    image = drawingNo < images.size() ? images.get(drawingNo) : null;
    drawingNo++;
  }
  
  if( image != null)
  {
    ResizeWindow(scale*image.image.width, scale*image.image.height);
  } else
  {
    checked = false;
  }
  
  drawSecond();
}

int lastViewNo = -1, viewNo = 0;
void drawSecond()
{
  if(images.size()==0){
    return;
  }

  ImageData data = images.get(viewNo);  
  PImage img = data.image;
  
  int desired_w = max( 2*scale*img.width, data.path.length()*7);
  int desired_h = scale*img.height + 30;
  if(desired_w != secondFrame.width || desired_h != secondFrame.height)
  {    
    secondFrame.frame.setSize(desired_w + secondFrame.frame.getInsets().left + secondFrame.frame.getInsets().right,
    desired_h + secondFrame.frame.getInsets().top + secondFrame.frame.getInsets().bottom);
    secondFrame.resize(desired_w,desired_h);
    return;
  }
 
 if( lastViewNo != viewNo)
{ 
  secondFrame.background(0);
  secondFrame.image(img, 0, 0, scale*img.width, scale*img.height);
  drawFrame(scale*img.width, scale*img.height, true);
  //secondFrame.text(data.path,0,scale*img.height + 15);
  secondFrame.text(images.size() + "Images", scale*img.width, secondFrame.height/2);
  secondFrame.redraw();
  lastViewNo = viewNo;
}
}

void ResizeWindow(int w, int h)
{
  frame.setSize(w + frame.getInsets().left + frame.getInsets().right,
    h + frame.getInsets().top + frame.getInsets().bottom);
    resize(w,h);
}

//画面を縦横4分割するように線を引く
void drawFrame(int w, int h, boolean sndFrame)
{
  int q_w = w/4;
  int q_h = h/4;
  for(int i=1; i<4; i++){
    if(sndFrame){
      secondFrame.line(q_w*i, 0, q_w*i, h);
      secondFrame.line(0, q_h*i, w, q_h*i);
    }
    else{     
      line(q_w*i, 0, q_w*i, h);
      line(0, q_h*i, w, q_h*i);
    }
  }
}

void keyPressed()
{
  
  if( images.size() == 0)
  return;
  
  if( key == CODED )
  {
    if(keyCode == RIGHT)
    {
      viewNo = (viewNo+1) % images.size();
      println("right");
    }
    
    if(keyCode == LEFT)
    {
      viewNo = (viewNo + images.size() - 1) % images.size();
    }
  }
}
