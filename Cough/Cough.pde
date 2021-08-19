import java.util.*;
Random randNo = new Random();  //Random number gen for random velocities and directions
float g=981; //Gravitational acceleration scaled to millimetre (mm/s^2)
float k=0.0181; //1.81E-5 Kg/m.s , viscosity of air at 15 deg C scaled to 0.0181 kg/mm.s  
float dt=0.01;  //Time step      
float t;  //time var
Droplet [] d;  //Droplet array
int maxDroplets=20000;  //Max array size for droplets
int droplets;  //Number of current droplets being drawn
int countFace,countBody;  //Number of drops that hit face
int hitRightMask,hitLeftMask,hitWallGround; //Number of drops that hit masks and ground/wall
PImage reset,mask,body,bodyFlip;  //Images for UI
boolean started;  //Whether simulation has started or not
boolean maskOn = false;  //mask is defaulted to off
slider s1;  //Slider to vary num droplets
button playBtn,stopBtn,maskBtn;  // Play button to start sim
mask maskLeft,maskRight;   //Mask on left person
float seperation=1;  //0.25=1m, 0.5=2m, 0.75=3m,1=4m separation
float move=4;  //meters of seperation
distButton oneMetre,twoMetre,threeMetre,fourMetre;  //buttons change seperation
float sliderPosition=200; //Initial slider pos and num of particles

/*-------------------------------------------------------------------------------------------*/

void setup(){
  fullScreen();
  textSize(20);
  d=null;
  d = new Droplet[maxDroplets];
  //Set up droplets
  for(int i=0; i<maxDroplets; i++){
     d[i]=new Droplet();
  }
  //Buttons and slider
  oneMetre = new distButton(width-400,120,50,"1");
  twoMetre = new distButton(width-300,120,50,"2");
  threeMetre = new distButton(width-200,120,50,"3");
  fourMetre = new distButton(width-100,120,50,"4");
  s1 = new slider(0,30, width, 20, 8);
  playBtn = new button(50,75,50,"play");
  stopBtn = new button(125,75,50,"stop");
  maskBtn = new button(200,75,50,"mask");
  //Masks
  maskRight = new mask(width-30,height/2-120,"right");
  maskLeft = new mask(40,height/2-120,"left");
  //Images for UI
  reset = loadImage("reset.png");
  mask=loadImage("mask.png");
  body = loadImage("body.png");
  bodyFlip = loadImage("bodyFlip.png");
  body.resize(120,700);
  bodyFlip.resize(120,700);
  //Set variables to initial values
  //Sets these each time reset is pressed
  started = false;
  countFace = 0;
  countBody=0;
  hitRightMask=0;
  hitLeftMask=0;
  hitWallGround =0;
  t=0;
}

/*-------------------------------------------------------------------------------------------*/

void draw(){
  background(255);
  //People
  stroke(0,0,100);
  image(body,(width-60)/2-(((width-60)/2)*seperation)-30,height/3);
  image(bodyFlip,(width-60)/2+(((width-60)/2)*seperation)-20,height/3);
  stroke(10);
  
  //Distance lines
  stroke(200);
  fill(10);
  line(10,0,10,height);
  text("0m",10,height-20);
  line(width/4,0,width/4,height);
  text("1m",width/4,height-20);
  line(width/2,0,width/2,height);
  text("2m",width/2,height-20);
  line(3*width/4,0,3*width/4,height);
  text("3m",3*width/4,height-20);
  line(width-30,0,width-30,height);
  text("4m",width-30,height-20);
  
  //Information
  fill(10); //If text is pure black droplets will collide with writing
  text("Num droplets: "+(int(sliderPosition)*5),width/2-120,70);
  text("Number that have hit face: "+countFace,width/2-150,100);
  text("Number that have hit wall/ground: "+hitWallGround,width/2-185,130);
  text("Number that have hit body: "+countBody,width/2-150,160);
  
  //Colour legend
  textSize(15);
  text("0-20.4 microns: ",30,140);
  fill(200,200,0);
  square(170,125,20);
  fill(10);
  text("20.4-40.8 microns: ",22,165);
  fill(0,200,200);
  square(170,150,20);
  fill(10);
  text("40.8-61.2 microns: ",22,190);
  fill(0,200,0);
  square(170,175,20);
  fill(10);
  text("61.2-81.6 microns: ",22,215);
  fill(200,0,200);
  square(170,200,20);
  fill(10);
  text("81.6-102 microns: ",22,240);
  fill(200,0,0);
  square(170,225,20);
  fill(10);
  textSize(20);
  
  //Reset button
  stopBtn.display();
  stopBtn.update();
  
  //Masks and mask number display
  //Only display when masks are on
  if(maskOn){
    fill(150);
    stroke(150);
    strokeWeight(3);
    maskLeft.display();
    maskLeft.update();
    maskRight.display();
    maskRight.update();
    fill(10);
    stroke(10);
    strokeWeight(2);
    text("Right mask blocked: "+hitRightMask+" droplets",4*width/6,300);
    text("Left mask blocked: "+hitLeftMask+" droplets",width/6,300);
  }
  
  //Keep slider postion the same after reset simulation
  sliderPosition=int(s1.getPos()); //-2 to correct for error in slider pos
  //Items to be displayed only before simulation starts
  if(!started){
    playBtn.display();
    playBtn.update();
    maskBtn.display();
    maskBtn.update();
    s1.update();
    s1.display();
    oneMetre.display();
    oneMetre.update();
    twoMetre.display();
    twoMetre.update();
    threeMetre.display();
    threeMetre.update();
    fourMetre.display();
    fourMetre.update();
    stroke(10);
    fill(10);
    text("Seperation = "+move+" m",width-350,70);
    line(width-430,85,width-70,85);
    line(width-430,85,width-430,105);
    line(width-70,85,width-70,105);
    line(width-250,85,width-250,75);
    loadPixels();
  }
  //Update droplets when simulation starts
  else{
    droplets = int(sliderPosition)*5;
    for(int i=0;i<droplets;i++){
      //Only update position if droplets have not collided with something
      if(d[i].stopped==false){  
        d[i].advance();
      }
      d[i].drawDrop();
    }
    t=t+dt; //<>//
  }
}

/*-------------------------------------------------------------------------------------------*/

class Droplet{       
  float x,y;
  float vx,vy;
  color c; 
  float radius,m;
  boolean hitFace=false,hitBody=false,stopped=false;
  
  //General constructor
  Droplet(){
    //Small deviation in starting positions to represent mouth
    x=(width-60/2)-(((width-60))*seperation)+160;
    y=(float)randNo.nextGaussian()*0.001 + height+700;
    //Velocity distribution(VanSciver, Miller and Hertzberg, 2011). 
    vx=(float)randNo.nextGaussian()*67 + 100;
    //Small vertical spread in velocity slightly angled down as mouth is slightly angled
    vy=(float)randNo.nextGaussian()*10-10;
    
    //Sets random radius and then mass based off of radius
    //95% of droplets lie in 2micrometers - 100micrometers (Duguid, 1946) 
    //Calculated standard deviation from this.
    radius=(float)randNo.nextGaussian()*(2.45E-2/2) +(5.1E-2/2); //
    m = ((4/3)*PI*pow(radius,3));
    
    //Sets droplet colour to represent radius range
    if(radius < (10.2E-2/2) *1/5){c=color(200, 200, 0);}
    else if(radius < (10.2E-2/2) *2/5){c=color(0, 200, 200);}
    else if(radius < (10.2E-2/2) *3/5){c=color(0, 200, 0);}
    else if(radius < (10.2E-2/2) *4/5){c=color(200, 0, 200);}
    else{c=color(200, 0, 0);}
  }

  void advance(){
      //------------Differential Equations-------------//
      vx=vx-(6*PI*radius*k*vx)*dt;
      x=x+(vx*dt);
      
      vy=vy-(m*g)-(6*PI*radius*k*vy)*dt;
      y=y+(vy*dt);
      //Advance time
      //t += dt;
      //----------------------------------------------//
    
      //Sets boundaries droplets stick to at edges
      if (x<=0)  {vx=0; vy=0; stopped=true; hitWallGround++;}
      if (x>=3980){vy=0; vx=0; stopped=true; hitWallGround++;}
      if (y<=50){vy=0; vx=0; stopped=true; hitWallGround++;}
      if (y>=2980)  {vy=0; vx=0; stopped=true; hitWallGround++;}
      
      //Hit face and stops
      if(pixels[int(map(x,0,4000,0,width))+int(map(y,0,3000,height,0))*width]==color(0,0,0)){
        vx=0;
        vy=0;
        if(hitFace==false && x>=2000){
          countFace++;
          hitFace=true;
        }
        stopped = true;
      }
      
      //Hit body and stops
      if(pixels[int(map(x,0,4000,0,width))+int(map(y,0,3000,height,0))*width]==color(25,25,25)){
        vx=0;
        vy=0;
        if(hitBody==false && x>=2000){
          countBody++;
          hitBody=true;
        }
        stopped = true;
      }
      
      //Hit mask and stops with a certain probability
      if(pixels[int(map(x,0,4000,0,width))+int(map(y,0,3000,height,0))*width]==color(150)){
        if(random(1) <= 0.5){
          vx=0;
          vy=0;
          stopped = true;
          if(x>2000){
            hitRightMask++;
          }
          else{
            hitLeftMask++;
          }
          stopped=true;
        }
      }
  }

  void drawDrop(){
     float sx= map(x,0,4000,0,width); //maps x position to screen
     float sy= map(y,0,3000,height,0); //maps y position to screen
     fill(c);  //sets droplet to size range colour
     stroke(c);
     //Sets size of droplet based on discrete range of radius values
     if(radius < (10.2E-2/2) *1/5){circle(sx,sy,2);}
     else if(radius < (10.2E-2/2) *2/5){circle(sx,sy,4);}
     else if(radius < (10.2E-2/2) *3/5){circle(sx,sy,6);}
     else if(radius < (10.2E-2/2) *4/5){circle(sx,sy,8);}
     else{circle(sx,sy,10);}
  }
}

    
/*----------------------------------------------------------------------------*/

class slider {
  int swidth, sheight;    // width and height of slider
  float xpos, ypos;       // x and y position of slider
  float spos, newspos;    // x position of toggle
  float sposMin, sposMax; // max and min values of slider
  int loose;              // Stiffness of movement
  boolean over;           // checks if mouse is above slider
  boolean locked;         // checks if mouse is clicked and locks to it
  float ratio;            //ratio of full slider width to width-height
  //General constructor
  slider (float x, float y, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = x;
    ypos = y-sheight/2;
    spos = sliderPosition;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }
  //Update slider position
  void update() {
    if (overbar()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }
  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }
  //Check if mouse is over
  boolean overbar() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }
  //Display slider
  void display() {
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(10, 10, 10);
    } else {
      fill(100, 100, 100);
    }
    rect(spos, ypos, sheight, sheight);
  }
  //returns slider position
  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}

/*----------------------------------------------------------------------------*/

class button {
  int radius;
  int xpos,ypos;
  String type;  //Start/Stop/Mask button
  //General constructor
  button(int x, int y, int r, String btnType){
    radius=r;
    xpos=x;
    ypos=y;
    type=btnType;
  }
  //Display the button on screen
  void display(){
    if(type=="play"){
      stroke(50);
      strokeWeight(3);
      fill(0,255,0);
      circle(xpos,ypos,radius);
      fill(50);
      triangle(xpos-radius/4,ypos-radius/4,xpos-radius/4,ypos+radius/4,xpos+radius/3,ypos);
    }
    else if (type=="stop"){
        stroke(0);
        strokeWeight(3);
        fill(255,0,0);
        circle(xpos,ypos,radius);
        fill(255);
        image(reset,xpos-30,ypos-30);
        reset.resize(60,60);
    }
    else if(type=="mask"){
      stroke(50);
      strokeWeight(3);
      fill(200,255,50);
      circle(xpos,ypos,radius);
      fill(50);
      textSize(15);
      text("Mask",xpos-15,ypos+40);
      textSize(20);
      mask.resize(60,60);
      image(mask,xpos-30,ypos-30);
    }
  }
  //Check if button is pressed and carry out assigned function
  void update(){
    if(type=="play"){
      if(mousePressed){
        if(mouseX>xpos-radius/2 && mouseX<xpos+radius/2 
          && mouseY>ypos-radius/2 && mouseY<ypos+radius/2){
            //Starts simulation
            if(started==true){started=false;}
            else{started=true;}
            delay(200);
        }
      }
    }
    else if(type=="stop"){
      if(mousePressed){
        if(mouseX>xpos-radius/2 && mouseX<xpos+radius/2 
          && mouseY>ypos-radius/2 && mouseY<ypos+radius/2){
            //Resets simulation
            setup();
            delay(200);
        }
      }  
    }
    else if(type=="mask"){
      if(mousePressed){
        if(mouseX>xpos-radius/2 && mouseX<xpos+radius/2 
          && mouseY>ypos-radius/2 && mouseY<ypos+radius/2){
            //Puts mask on/off
            if(maskOn==true){maskOn=false;}
            else{maskOn=true;}
            delay(200);
        }
      }  
    }
  }
}

class mask{
  float x,y;
  String side;
  //General constructor
  mask(float xpos,float ypos,String side){
   x=xpos;
   y=ypos;
   this.side = side;
  }
  //Display masks
  void display(){
    strokeWeight(2);
    if (side=="right"){
      line(x,y,x-4,y+10);
      line(x-4,y+10,x+8,y+43);
      line(x+8,y+43,x+27,y+57);
    }
    else if(side=="left"){
      line(x,y,x+5,y+11);
      line(x+5,y+11,x-5,y+41);
      line(x-5,y+41,x-28,y+54);
    }
  }
  //update position according to people separation
  void update(){
    if(side=="right"){
      x = (width-60)/2+(((width-60)/2)*seperation);
    }
    else{
      x = (width)/2-(((width-60)/2)*seperation)+60;
    }
  }
}

class distButton{
  float x,y;
  int r;
  String dist;
  //General constructor
  distButton(float x, float y, int r, String dist){
    this.x=x;
    this.y=y;
    this.r=r;
    this.dist=dist;
  }
  //Display distance buttons
  void display(){
    stroke(0);
    strokeWeight(3);
    fill(0,0,100);
    circle(x,y,r);
    fill(255);
    stroke(0);
    text(dist+"m",x-15,y+5);
  }
  //Check if pressed and changes separation
  void update(){
    if(mousePressed){
        if(mouseX>x-r/2 && mouseX<x+r/2 
          && mouseY>y-r/2 && mouseY<y+r/2){
            //move is the distance in meters
            move = int(dist);
            //separation is set to a fraction of the max separation
            seperation = move/4;
            setup();
        }
      }
  }
}
