//
// mtdbt2f4d*
//
//  /\      /\      /\      
// /  \    /  \    /  \    
//     \  /    \  /    \  /  
//      \/      \/      \/       
//
// x = time, y = pressure
// wave = [-1 < y < 1]
// amplitude = abs(peak)
// level = root mean square
// pitch = f(wavelength)
//

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import themidibus.*; 

// objects

Minim minim;
AudioPlayer voice;
AudioInput linein; 	
AudioRecorder audioRecord;
FFT fftLog;
FFT fftLin;
MidiBus myBus;
VideoExport videoExport;

float Scaler = 20.0;    // for wave drawing [50]
float Weighter = 1.0;    // for wave drawing [50]

PFont font[];     // array of references to fonts
PFont display;    // for hollows display

// options 

boolean debug = false;

// settings

String fontDataFolder = "fonts/mtdbt2f4d-3"; // stub folder

// flags

boolean createMTDBT2F4Dbusy = true; // flag used when generating MTDBT2F4Ds
boolean displayHollows = false; // controlled by 'h'
boolean audioPlaying = false; // true when audio playing 
boolean useFFT = true; // true when FFT used
boolean showSpectrum = false; // assumes displayHollows
boolean fx = true; // scripted animation effects on/off *todo* try/catch reading
boolean german = false; // hack for adjusting sensitivity for german voice
boolean spanish = false; // hack for adjusting sensitivity for spanish voice
boolean music = false; // hack for adjusting sensitivity for music
boolean other = false; // hack for adjusting sensitivity for other
boolean inputImages = false; // use data/img folder to load sequences images
boolean cueAudio = true; // manually move voice forward using renderStep
boolean outputVideo; // [false] output video flag
boolean outputAudio; // [false] output audio flag
boolean useAudioLinein; // [false] live audio input flag
boolean useVideoExport = false; // use Video Export library realtime ffmpeg output
boolean supressAsterisk;
boolean fx_;	// currently in fx_*

// arrays

String fontnames[];  		// original source names
String fx_spin[];  		// fx
String fx_spin_reverse[];  	// fx
String fx_blur[];  		// fx
String fx_blur_fade[];  	// fx
String fx_north[];		// fx
String fx_south[];		// fx
String fx_east[];		// fx
String fx_west[];		// fx
String fx_scale_in[];  		// fx
String fx_scale_out[];  	// fx
String fx_black[];  		// fx
String fx_img[];  		// fx
String fx_order3d[];  		// fx
String fx_shapeshift[];  		// fx
String fx_cometogether[];  		// fx
String fx_parallel_1[];  		// fx
String fx_parallel_2[];  		// fx
String fx_parallel_3[];  		// fx
PImage[] img; 			// fx helper

// string

// String asterisk = "`"; // default
String asterisk = "*"; // default
String typed = "*"; // default starting string
String thisFileout = null; // used for outputting img sequence
String saveFilename = "out"; // prefix used for outputting img sequence
String tmpdir = "data/tmp";

// int

int counter = 0; // main counter -- increments in draw() loop when % delaySpeed == 0
// int fontSize = 40;  // [44][54][60][66][80][84][99] points
// int fontSize = 120;  // [44][54][60][66][80][84][99] points for 300p
// int fontSize = 140;  // [44][54][60][66][80][84][99] points for 350p
// int fontSize = 140*2;  // [44][54][60][66][80][84][99] points for 350p
// int fontSize = 160*2;  // [44][54][60][66][80][84][99] points for 400p
// int fontSize = 120*2;  // [44][54][60][66][80][84][99] points for 400p (@ 75%)
// int fontSize = 192;  // [44][54][60][66][80][84][99] points for 480p
// int fontSize = 192*2;  // [44][54][60][66][80][84][99] points for 480p
// int fontSize = 216;  // [44][54][60][66][80][84][99] points for 540p
// int fontSize = 240;  // [44][54][60][66][80][84][99] points for 600p
// int fontSize = 288*2;  // [44][54][60][66][80][84][99] points for 720p
int fontSize = 216*2;  // [44][54][60][66][80][84][99] points for 720p (@ 75%)
// int fontSize = 360;  // [44][54][60][66][80][84][99] points for 900p
int fontLength;  // length of font[] (computed when filled)
int thisFont; // pointer to font[] of currently selected
int fontLoadStart = 0; // first numbered font to try
int fontLoadEnd = 499; // last numbered font to try [499]
// int fontLoadEnd = 50; // last numbered font to try [499]
int fontRangeStart; // pointer to font[], range min
int fontRangeEnd; // pointer to font[], range max
int fontRangeDirection = 1; // only two values, 1 or -1
int thisMillis = 0;  // for draw() loop timing debug
int startMillis = 0;  // start audio time
int elapsedMillis = 0;  // total elapsed audio time
int currentElapsedMillis = 0;  // elapsed audio time 
int previousElapsedMillis = 0;  // paused audio time 
int thisBackground = 0;
// int thisBackground = 255;
int thisFill = 255;
// int thisFill = 0;
int thisOpacity = 255;
int cueStep = 1000;  // audio back, forward increment
int renderFrame = 0;  // current frame # rendering
int renderFPS = 30;  // rendering output FPS [30]
int bufferSize = 64; // [128] for mimim, when loading audio
int fxduration = 1675; // set per fx
int fft_logAverages_width_adjust = 4; // determines number of sample bands [4]
int fx_img_counter = 0; // increment for fast display img
int fx_img_count = 108; // number of images to load (+1)
int fx_img_delay = 400; // delay between sound and show image in frames
// int videoExport_delay = 2000; // delay for finishing ffmpeg process (ms)
int videoExport_delay = 0; // delay for finishing ffmpeg process (ms)

// float

float amplitude; // used for scaling, mapped from amplitudeRaw
float amplitudeRaw; // raw level from src either linein or in.aiff
float levelAdjust = .75;  // used to adjust amplitudeRaw [1.0]
float rotation = 0;  // in radians, 0-TWO_PI
float scaled = 1;  // .25-4 for scaling
float renderPosition = 0.0; // current position
float renderStep = 1.0 / renderFPS * 1000; // [33.33] 1/30 spf * 1000 ms
float fx_spin_adjust = 0.0; // increment rotate
float fx_spin_reverse_adjust = 0.0; // increment rotate
float fx_blur_adjust = 0.0; // increment thisOpacity
float fx_blur_fade_adjust = 0.0; // increment thisOpacity
float fx_north_adjust = 0.0; // increment rotate
float fx_south_adjust = 0.0; // increment rotate
float fx_east_adjust = 0.0; // increment rotate
float fx_west_adjust = 0.0; // increment rotate
float fx_scale_in_adjust = 1.0; // increment scale 
float fx_scale_out_adjust = 1.0; // increment scale 
float fx_black_adjust = 1.0; // increment scale 
float fx_img_adjust = 1.0; // increment scale 
float fx_order3d_adjust = 0.0; // increment rotation around Y
float fx_shapeshift_adjust = 0.0; // change rotation of lines
float fx_cometogether_adjust = 0.0; // change rotation of the parallel lines
float fx_parallel_1_adjust = 0.0; // change rotation of the parallel lines
float fx_parallel_2_adjust = 0.0; // change rotation of the parallel lines
float fx_parallel_3_adjust = 0.0; // change rotation of the parallel lines

float rot = 0.0;

void setup() {

  createMTDBT2F4D();

  // ffmpeg insists on multiples of 16 for h,w

  int thisW = 720;  // global height [300] [350] [480] [720]
  int thisH = 720;  // global width [300] [350] [480] [720]
  size(720, 720);

  frameRate(30); // this seems to matter

  background(thisBackground);
  fill(thisFill, thisOpacity);
  textSize(fontSize);
  textAlign(CENTER);

  // minim

  minim = new Minim(this);
  voice = minim.loadFile("data/audio/in.wav", bufferSize);

  // midiBus 

  if (debug) { 
    MidiBus.list();
  }
  myBus = new MidiBus(this, 0, 0); 

  // videoExport

  // videoExport = new VideoExport(this, "out/out.mp4", "data/audio/in.wav");
  // videoExport.setFrameRate(30.0);

  // fft

  // Fast Fourier Transform with logarathmic averages
  // this splits the frequency spectrum by bands based on octaves
  // which are non-linear and correspond more closely to our hearing

  // logAverages require octave width (hz), bands/octave
  // adjusting this produces additional frequency bands
  // which could be used to draw extra *

  // * todo * add adjustable coarseness to these averages (knob?)

  fftLog = new FFT(voice.bufferSize(), voice.sampleRate());
  // fftLog.logAverages(1024 * 4, 1);
  fftLog.logAverages(1024 * fft_logAverages_width_adjust, 1);
  fftLin = new FFT(voice.bufferSize(), voice.sampleRate());
  fftLin.linAverages(1);
  // fftLin is a linear Fast Fourier Transform
  // and it is used to draw the spectrum when called
  // fft signal window to control outliers in fft bands
  fftLog.window( FFT.HAMMING );  // FFT.NONE, FFT.HAMMING, FFT.TRIANGULAR, [FFT.LANCZOS]

  // init fx
  // convert into int arrays?
  // only do this if not using existing audio file

  if (fx) {
    fx_spin = loadStrings(tmpdir + "/_fx_spin");
    fx_spin_reverse = loadStrings(tmpdir + "/_fx_spin_reverse");
    fx_blur = loadStrings(tmpdir + "/_fx_blur");
    fx_blur_fade = loadStrings(tmpdir + "/_fx_blur_fade");
    fx_north = loadStrings(tmpdir + "/_fx_north");
    fx_south = loadStrings(tmpdir + "/_fx_south");
    fx_east = loadStrings(tmpdir + "/_fx_east");
    fx_west = loadStrings(tmpdir + "/_fx_west");
    fx_scale_in = loadStrings(tmpdir + "/_fx_scale_in");
    fx_scale_out = loadStrings(tmpdir + "/_fx_scale_out");
    fx_black = loadStrings(tmpdir + "/_fx_black");
    fx_img = loadStrings(tmpdir + "/_fx_img");
    fx_order3d = loadStrings(tmpdir + "/_fx_order3d");
    fx_shapeshift = loadStrings(tmpdir + "/_fx_shapeshift");
    fx_cometogether = loadStrings(tmpdir + "/_fx_cometogether");
    fx_parallel_1 = loadStrings(tmpdir + "/_fx_parallel_1");
    fx_parallel_2 = loadStrings(tmpdir + "/_fx_parallel_2");
    fx_parallel_3 = loadStrings(tmpdir + "/_fx_parallel_3");
  }

  // display font

  String fontStub = "fonts/Monaco.ttf"; // from sketch /data
  display = createFont(fontStub, 10, false);
  // textMode(SHAPE);

  // load img[]

  if (inputImages) {
    img = new PImage[fx_img_count];	// new array object

    for (int i = 0; i < img.length; i++) {
      String imgStub = "data/img/" + nf(i+1, 4) + ".jpg";
      img[i] = loadImage(imgStub);
      println("loadImage : " + imgStub);
    }
  }
}

void draw() { 

    // adjust mtdbt2f4d

    if ( ( thisFont + fontRangeDirection >= fontRangeStart ) && ( thisFont + fontRangeDirection <= fontRangeEnd ) ) {
      thisFont += fontRangeDirection;
    } else {
      fontRangeDirection *= -1;
      thisFont += fontRangeDirection;
    }

	// set transform matrix

    pushMatrix();
    translate(width/2, height/2);
    rotate(rotation);
    noStroke();

	// clear screen

    fill(thisBackground, thisOpacity);
    rect(-width/2, -height/2, width, height);
    textFont(font[thisFont]);
    fill(thisFill, thisOpacity);

    // fx

	fx_=false;

    if (fx) {
      checkFx();
    }

    // get amplitude

    if (useAudioLinein) {
      amplitudeRaw = abs(linein.left.level()) * levelAdjust;
    } else {
      amplitudeRaw = abs(voice.left.level()) * levelAdjust;
    }
    amplitude = map(amplitudeRaw, 0, 1, 1, 5);

    // get fft log avg
    // now, set for 1 band only
    // but can loop, see Spectrum.pde

    fftLog.forward(voice.mix);

    float fftLogScale = 0.0;

    for (int i = 0; i < fftLog.avgSize (); i++) {

      if (german) {
        fftLogScale = map(fftLog.getAvg(i), 0.0, 3.0, 1.0, 1.75);
      } else if (spanish) {
        fftLogScale = map(fftLog.getAvg(i), 0.0, 3.0, 1.0, 2.5);
      } else if (music) {
        fftLogScale = map(fftLog.getAvg(i), 0.0, 3.0, 1.0, 2.75);
      } else if (other) {
        fftLogScale = map(fftLog.getAvg(i), 0.0, 3.0, 1.0, 11.5);
      } else {
        fftLogScale = map(fftLog.getAvg(i), 0.0, 3.0, 1.0, 5.0);
      }
		if (debug) {
      		println(fftLog.avgSize());
      		println(fftLog.getAvg(i));
      		println(fftLogScale);
		}
    }

    scale(scaled); // adjust scale from midi controller

    if (useFFT) {
      scale(fftLogScale);
    } else {
      scale(amplitude);
    }

	if (!supressAsterisk)
    	text(asterisk, 0, textAscent()*.67);      
    counter++;
    popMatrix();

    // render

    if (outputVideo) {
      if (!useVideoExport) {
        thisFileout = saveFilename + "-" + nf(renderFrame, 4) + ".tga"; // needs to be padded
        saveFrame("out/tga/" + thisFileout);
      } else {
        videoExport.saveFrame();
      }
      renderPosition = renderFrame * renderStep; 
      if (round(renderPosition) < voice.length() + videoExport_delay) {
        if (cueAudio) {          		
          voice.cue(round(renderPosition));
        }
      } else {
        startstopRender();
      }	
      if (debug) {
        println("--");
        println("renderFrame : " + renderFrame);
        println("amplitude : " + amplitude);
      }
      renderFrame++;
    }

    if (debug) {
		println("-------");
		println("amplitudeRaw = " + amplitudeRaw);	
		println("amplitude = " + amplitude);
	}
	
  	// hollows 
  	if (displayHollows) {
    	drawdisplayHollows();
    	drawGrid();
  	}
}


void checkFx() {

  // read timelines, apply fx 

    // fx_spin

  fxduration = 1675;		// based on .aif length (ms)  

  // fx_spin

  for (String val : fx_spin) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      float now = float(val) + float(fxduration) - float(voice.position());
      fx_spin_adjust = map(now, fxduration, 0, 0.0, -4*TWO_PI);
      rotate(fx_spin_adjust);
    }
  }

  // fx_spin_reverse

  fxduration = 1675;

  for (String val : fx_spin_reverse) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      float now = float(val) + float(fxduration) - float(voice.position());
      fx_spin_reverse_adjust = map(now, fxduration, 0, 0.0, 4*TWO_PI);
      rotate(fx_spin_reverse_adjust);
    }
  }

  // (init blur)

  boolean blurring=false;

  // fx_blur (would be good not to use global, but for now ok)

  fxduration = 15830;

  for (String val : fx_blur) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      thisOpacity=0;
      blurring=true;
    }
  }

  // fx_blur_fade 

    fxduration = 800;

  for (String val : fx_blur_fade) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      thisOpacity=0;
      blurring=true;
    }
  }

  // (stop blur)

  if (!blurring) {
    thisOpacity=255;
  }

  // fx_north

  fxduration = 200;

  for (String val : fx_north) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      rotate(TWO_PI);
    }
  }

  // fx_south

  fxduration = 200;

  for (String val : fx_south) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      rotate(PI);
    }
  }

  // fx_east

  fxduration = 200;

  for (String val : fx_east) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      rotate(PI/2.0);
    }
  }

  // fx_west

  fxduration = 200;

  for (String val : fx_west) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      rotate(PI*3/2);
    }
  }

  // fx_scale_in

  fxduration = 700;	// [500] for anEra [1520] for README

  for (String val : fx_scale_in) {
    if ( (voice.position() >= int(val)) && (voice.position() <= int(val)+fxduration) ) {	
      float now = float(val) + float(fxduration) - float(voice.position());
      fx_scale_in_adjust = map(now, fxduration, 0, 0.0001, 1.0);  // would be nice to do logarithmically
      scale(fx_scale_in_adjust);
    }
  }

  // fx_scale_out

 	fxduration = 1050;	// [500] for anEra [1050] for README

  for (String val : fx_scale_out) {
    if ( (voice.position() >= int(val)) && (voice.position() <= int(val)+fxduration) ) {	
      float now = float(val) + float(fxduration) - float(voice.position());
      fx_scale_out_adjust = map(now, fxduration, 0, 1.0, 0.0001);  // would be nice to do logarithmically       
      scale(fx_scale_out_adjust);
    }
  }

  // fx_black

  // fxduration = 25000;
  fxduration = 4000;		// 4 seconds, must be same as length of black.aif

  for (String val : fx_black) {
    if ( (voice.position() >= int(val)) && (voice.position() <= int(val)+fxduration) ) {	
      	/* debug
		// still something funny in relation between effect length and voice position and counter
		println("BLACK");
      	println("counter = " + counter);
      	println("voice.position = " + voice.position());
      	println("int(val) = " + int(val));
		*/
      thisFill = 0;
	  fill(thisFill);
      // thisFill = 255;
    } else { 
      thisFill = 255;
      // thisFill = 0;
      // fill(24,48,41);
    }
  }


  // fx_img

  fxduration = 100000;	
  int i = 0;

  if (inputImages) {
    for (String val : fx_img) {
      if ( (voice.position() >= int(val)+fx_img_delay) && (voice.position() <= int(val)+fxduration+fx_img_delay) ) {	
        if (img[i] == null) {
          println("** img[] not available **");
        } else {
          // image(img[i], -width/2, -height/2);
          image(img[i], -img[i].width/2, -img[i].height/2);
        } 
        /*
				// img speedup ** fix **
         				if (fx_img_counter < i+50) {
         					image(img[fx_img_counter % fx_img_count], -width/2, -height/2);
         					fx_img_counter++;	// dont actually need this, rm from globals
         				} else {	
         				image(img[i], -width/2, -height/2);
         				}
         				*/
      }
      i++;
    }
  }

  // fx_order3d

  // fxduration = 1833;	// 1 minute, 50 seconds (length of order3d.aif)
  fxduration = 3833;	// 3 minutes, 50 seconds

  for (String val : fx_order3d) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	
      float now = float(val) + float(fxduration) - float(voice.position());
      // fx_order3d_adjust = map(now, fxduration, 0, 0.0, 1.0);
      fx_order3d_adjust = map(now, 0, fxduration, 1.0, 0.0);
		
		// multiple * cube
		
	    text(asterisk,textAscent()*.4*fx_order3d_adjust,textAscent()*.67*.43*fx_order3d_adjust);
	    text(asterisk,-textAscent()*.4*fx_order3d_adjust,textAscent()*.67*.43*fx_order3d_adjust);
	    text(asterisk,textAscent()*.4*fx_order3d_adjust,textAscent()*.91*fx_order3d_adjust);
	    text(asterisk,-textAscent()*.4*fx_order3d_adjust,textAscent()*.91*fx_order3d_adjust);
	    text(asterisk,0*fx_order3d_adjust,textAscent()*.18*fx_order3d_adjust);
	    text(asterisk,0*fx_order3d_adjust,textAscent()*1.15*fx_order3d_adjust);
    }
  }

  // fx_shapeshift

  fxduration = 27000; //  x" @ 30 fps

  for (String val : fx_shapeshift) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	

		// ** fix ** would be better to have this map over time 
      	float now = float(val) + float(fxduration) - float(voice.position());
      	fx_shapeshift_adjust = map(now, 0, fxduration, 0.0, TWO_PI*12);
      	// fx_shapeshift_adjust += TWO_PI / 100; 	// speedup hardcoded

		// currently position is hardcoded
		// should understand how push / pop works
		// and use println to debug current tranformation matrix

		int yoffset = int(textAscent()*.33);

		if (asterisk == "*") asterisk = "–"; 
		supressAsterisk = true;
		thisOpacity = 200;
		fill(thisFill, thisOpacity);

      	// not using FFT for now ** fix **
		// b/c of variable scope
		// either way seems best no scaling
		scale(amplitude*.85);

		pushMatrix();
		rotate(fx_shapeshift_adjust);
	    text(asterisk,0,yoffset);
		popMatrix();	

		pushMatrix();
		rotate(-fx_shapeshift_adjust);
	    text(asterisk,0,yoffset);
		popMatrix();	

		pushMatrix();
		rotate(fx_shapeshift_adjust*.5);
	    text(asterisk,0,yoffset);
		popMatrix();	

		pushMatrix();
		rotate(-fx_shapeshift_adjust*.25);
	    text(asterisk,0,yoffset);
		popMatrix();			

		fx_ = true;
    } 
  }

  // fx_parallel_1

  fxduration = 5000; //  x" @ 30 fps

  for (String val : fx_parallel_1) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	

		// draw one parallel line from one starting line, then pause

      	float now = float(val) + float(fxduration) - float(voice.position());
      	fx_parallel_1_adjust = map(now, 0, fxduration, 1000, 0.0); // 1000 works as speed
		fx_parallel_1_adjust = constrain(fx_parallel_1_adjust, 0, width/6);

		// println(millis());
		// println("voice.position() = " + voice.position());
		// println("now = " + voice.position());
		// println("fx_parallel_1_adjust = " + fx_parallel_1_adjust);

		int yoffset = int(textAscent()*.33);

		if (asterisk == "*") asterisk = "–"; 
		supressAsterisk = true;
		// thisOpacity = 200;
		fill(thisFill, thisOpacity);

        // not using FFT for now ** fix **
        // b/c of variable scope
        scale(amplitude*.85);
        rotate(TWO_PI/4);

        pushMatrix();
        text(asterisk,0,yoffset);
        popMatrix();

		fx_=true;
    } 
  }

  // fx_parallel_2

  fxduration = 5000; //  x" @ 30 fps

  for (String val : fx_parallel_2) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	

		// draw one parallel line from one starting line, then pause

      	float now = float(val) + float(fxduration) - float(voice.position());
      	fx_parallel_2_adjust = map(now, 0, fxduration, 1000, 0.0); // 1000 works as speed
		fx_parallel_2_adjust = constrain(fx_parallel_2_adjust, 0, width/12);

		// println(millis());
		// println("voice.position() = " + voice.position());
		// println("now = " + voice.position());
		// println("fx_parallel_2_adjust = " + fx_parallel_2_adjust);

		int yoffset = int(textAscent()*.33);

		if (asterisk == "*") asterisk = "–"; 
		supressAsterisk = true;
		// thisOpacity = 200;
		fill(thisFill, thisOpacity);

        // not using FFT for now ** fix **
        // b/c of variable scope
        scale(amplitude*.85);
        rotate(TWO_PI/4);

        pushMatrix();
	    text(asterisk,0,yoffset+fx_parallel_2_adjust);
	    text(asterisk,0,yoffset-fx_parallel_2_adjust);
        popMatrix();

		fx_=true;
    } 
  }

  // fx_parallel_3

  fxduration = 5000; //  x" @ 30 fps

  for (String val : fx_parallel_3) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	

		// draw one parallel line from one starting line, then pause

      	float now = float(val) + float(fxduration) - float(voice.position());
      	fx_parallel_3_adjust = map(now, 0, fxduration, 1000, 0.0); // 1000 works as speed
		fx_parallel_3_adjust = constrain(fx_parallel_3_adjust, 0, width/6);

		// println(millis());
		// println("voice.position() = " + voice.position());
		// println("now = " + voice.position());
		// println("fx_parallel_3_adjust = " + fx_parallel_3_adjust);

		int yoffset = int(textAscent()*.33);

		if (asterisk == "*") asterisk = "–"; 
		supressAsterisk = true;
		// thisOpacity = 200;
		fill(thisFill, thisOpacity);

        // not using FFT for now ** fix **
        // b/c of variable scope
        scale(amplitude*.85);
        rotate(TWO_PI/4);

        pushMatrix();
        text(asterisk,0,yoffset);
	    text(asterisk,0,yoffset+fx_parallel_3_adjust);
	    text(asterisk,0,yoffset-fx_parallel_3_adjust);
        popMatrix();

		fx_=true;
    } 
  }

  // fx_cometogether

  fxduration = 5000; //  x" @ 30 fps
  // fxduration = 1000; //  x" @ 30 fps

  for (String val : fx_cometogether) {
    if ( (voice.position() > int(val)) && (voice.position() < int(val)+fxduration) ) {	

		// rotate around the center point until reach vertical

      	float now = float(val) + float(fxduration) - float(voice.position());
      	// fx_cometogether_adjust = map(now, 0, fxduration, 0.0, 4*TWO_PI/4);
      	fx_cometogether_adjust = map(0, now, fxduration, 0.0, TWO_PI/3);

		// println(millis());
		// println(voice.position());
		// println("fx_cometogether_adjust = " + fx_cometogether_adjust);

		int yoffset = int(textAscent()*.33);

		if (asterisk == "*") asterisk = "–"; 
		supressAsterisk = true;
		// thisOpacity = 200;
		fill(thisFill, thisOpacity);

      	// not using FFT for now ** fix **
		// b/c of variable scope
		// either way seems best no scaling
		scale(amplitude*.85);
		rotate(TWO_PI/4);

		pushMatrix();
		rotate(fx_cometogether_adjust);
	    text(asterisk,0,yoffset);
		popMatrix();	

		pushMatrix();
		rotate(-fx_cometogether_adjust);
	    text(asterisk,0,yoffset);
		popMatrix();	

		pushMatrix();
		rotate(fx_cometogether_adjust*.3333);
	    text(asterisk,0,yoffset);
		popMatrix();	

		fx_=true;
    } 
  }

	// if not in the middle of any fx_ then reset to *
	// ** fix ** add this to the other fx_

	if (!fx_) {
		asterisk = "*";
		supressAsterisk = false;
	}
}


void keyPressed() {

  switch(key) {
  case ' ':  // play/pause voice
    if (audioPlaying == true) {
      previousElapsedMillis = elapsedMillis;
      voice.pause();
    } else {
      startMillis=millis();
      voice.play();
    }
    audioPlaying = !audioPlaying;
    break;
  case TAB:  // rewind
    voice.rewind();
    previousElapsedMillis=0;
    currentElapsedMillis=0;
    elapsedMillis=0;
    startMillis=millis();
    voice.play();
    audioPlaying = true;
    break;
  case ',':  // cue reverse
    voice.cue(voice.position()-cueStep);
    break;
  case '.':  // cue forward
    voice.cue(voice.position()+cueStep);
    break;
  case '<':  // cue reverse 5x
    voice.cue(voice.position()-(cueStep*5));
    break;
  case '>':  // cue forward 5x
    voice.cue(voice.position()+(cueStep*5));
    break;
  case 'd':  // displayHollows
    displayHollows = !displayHollows;
    break;
  case 's':  // showSpectrum
    if (displayHollows) {
      showSpectrum = !showSpectrum;
    }
    break;
  case 'f':  // useFFT
    useFFT = !useFFT;
    println("useFFT=" + useFFT);
    break;
  case 'b':  // blur + (knobstub)
    if (thisOpacity > 10) {    
      thisOpacity -= 10;
    }
    break;
  case 'B':  // blur - (knobstub)
    if (thisOpacity < 245) {    
      thisOpacity += 10;
    }
    break;
  case 'r':  // render
    startstopRender();
    break;
  case 'a':  // audioRecord
    if ( audioRecord != null ) {
      audioRecord.endRecord();
      audioRecord.save();
      audioRecord = null;
      linein = null;
      voice = null;
      voice = minim.loadFile("data/audio/in.wav", bufferSize);
      println("** stop audioRecord **");
      useAudioLinein = false;
    } else {
      linein = minim.getLineIn(Minim.MONO, bufferSize);
      // audioRecord = minim.createRecorder(linein, "data/audio/in.wav");
      audioRecord = minim.createRecorder(linein, "/Users/reinfurt/pipe.wav");
      audioRecord.beginRecord(); 
      println("** start audioRecord **");
      useAudioLinein = true;
    }
    break;
  case 'm':  // monitor linein
    if ( linein == null ) {
      linein = minim.getLineIn(Minim.MONO, bufferSize);
    }
    if ( linein.isMonitoring() ) {
      linein.disableMonitoring();
    } else {
      linein.enableMonitoring();
    }
    break;
  case 'k':  // adjust logAvg freg width
    fft_logAverages_width_adjust--;
    fftLog.logAverages(1024 * fft_logAverages_width_adjust, 1);
    println(fft_logAverages_width_adjust);
    break;
  case 'l':  // adjust logAvg freg width
    fft_logAverages_width_adjust++;
    fftLog.logAverages(1024 * fft_logAverages_width_adjust, 1);
    println(fft_logAverages_width_adjust);
    break;
  default:
    asterisk = str(key);
    break;
  }
  if (debug) {
    println("--");
    println("Key:"+key);
    println("outputVideo:"+outputVideo);
  }
}


void createMTDBT2F4D()
{

  // createFont() works either from data folder or from installed fonts
  // renders with installed fonts if in regular JAVA2D mode
  // the fonts installed in sketch data folder make it possible to export standalone app
  // but the performance seems to suffer a little. also requires appending extension .ttf
  // biggest issue is that redundantly named fonts create referencing problems


  int fontLoadLimit = fontLoadEnd - fontLoadStart;
  font = new PFont[fontLoadLimit];
  fontnames = new String[fontLoadLimit];
  fontLength = 0; // reset

  for ( int i = 0; i < fontLoadLimit; i++ ) {  
    String fontStub = fontDataFolder + "/mtdbt2f4d-" + i + ".ttf"; // from sketch /data

    if ( createFont(fontStub, fontSize, true) != null ) {
      font[fontLength] = createFont(fontStub, fontSize, true);
      fontnames[fontLength] = "mtdbt2f4d-" + i;
      if (debug) {
        println("/mtdbt2f4d-" + i + ".ttf" + " ** OK **");
      }
      fontLength++;
    }
  }

  // set fontRange (random)
  /*
  fontRangeStart = int(map(random(1),0.0,1.0,0,fontLength));
   fontRangeEnd = int(map(random(1),0.0,1.0,fontRangeStart,fontLength-1));
   */

  fontRangeStart = 0;
  fontRangeEnd = fontLength-1;
  thisFont = fontRangeStart;

  if (debug) {
    println("###################################");
    println("fontRangeStart = " + fontRangeStart);
    println("fontRangeEnd = " + fontRangeEnd);
    println("fontLoadLimit = " + fontLoadLimit);
    println("fontLength = " + fontLength);
    println("font.length = " + font.length);
    println("###################################");
    println("** init complete -- " + fontLength + " / " + font.length + " **");
  }

  createMTDBT2F4Dbusy = false;
}


void updateRangeMTDBT2F4D(int fontRangeStartNew, int fontRangeEndNew)
{

  int fontRangeStartPrevious = fontRangeStart;
  int fontRangeEndPrevious = fontRangeEnd;

  fontRangeStart = fontRangeStartNew;  
  fontRangeEnd = fontRangeEndNew;

  // in range?
  // ** this needs to be fixed **

  if ( ( fontRangeStart < 0 ) || ( fontRangeStart > fontLength - 1 ) ) {
    fontRangeStart = 0;
  } 
  if ( ( fontRangeEnd < 0 ) || ( fontRangeEnd > fontLength - 1 ) ) {
    fontRangeEnd = fontLength - 1;
  }

  // "bump" thisFont into new range

  if ( ( fontRangeStart != fontRangeStartPrevious ) || (  fontRangeEnd != fontRangeEndPrevious )  ) {
    thisFont = fontRangeStart;
  }
}


void controllerChange(int channel, int number, int value) {

  switch(number) {
  case 1:
    thisOpacity = int(map(value, 0, 127, 255, 0));
    break;
  case 3:
    float thisLevelAdjust = map(value, 0, 127, 0.25, 4);	
    levelAdjust = thisLevelAdjust;
    break;
  case 4:
    float gain = map(value, 0, 127, -48, 6);	// -48, +6 = full audible range
    voice.setGain(gain);
    break;
  case 5:
    fontRangeStart = value;
    updateRangeMTDBT2F4D(fontRangeStart, fontRangeEnd);
    break;
  case 6:
    fontRangeEnd = value+500;
    updateRangeMTDBT2F4D(fontRangeStart, fontRangeEnd);
    break;
  case 7:
    rotation = map(value, 0, 127, 0, TWO_PI);
    break;
  case 8:
    scaled = map(value, 0, 127, .25, 4);
    break;
  default:
    break;
  }

  if (debug) {
    println();
    println("Controller Change:");
    println("--------");
    println("Channel:"+channel);
    println("Number:"+number);
    println("Value:"+value);
    println("thisOpacity:"+thisOpacity);
    println("getGain : " + voice.getGain());
    println("levelAdjust : " + levelAdjust);
  }
}


void drawdisplayHollows() 
{       
  thisMillis = millis() - thisMillis;  // milliseconds since this was last called
  String fps = str(1000 / thisMillis);
  String thisDisplay = fps + " fps";
  thisMillis = millis();
  if (audioPlaying == true) {
    currentElapsedMillis = (millis() - startMillis);
    elapsedMillis = previousElapsedMillis + currentElapsedMillis;
  }
  thisDisplay += " > " + thisFont + ".ttf";
  thisDisplay += " / " + elapsedMillis + " / " + voice.position() + " ms";
  stroke(255, 0, 0);  
  strokeWeight(1);

  if (!outputVideo) {
    if (showSpectrum) {

      // spectrum

        fftLin.forward(voice.mix);
      float spectrumDisplayWidth = map(fftLin.specSize(), 0, 64, 0, width);
      float spectrumDisplayIncrement = width / fftLin.specSize();
      for (int i = 0; i < spectrumDisplayWidth; i+=spectrumDisplayIncrement) {
        line(i, height/10, i, height/10 - fftLin.getBand(i)*10);
      }
    } else {

      // waveform

      float Scaler = 100.0;

      for (int i = 0; i < voice.bufferSize () - 1; i++) {
        float x1 = map(i, 0, voice.bufferSize(), 0, width);
        float x2 = map(i+1, 0, voice.bufferSize(), 0, height);
        line(x1, voice.mix.get(i)*Scaler+height/9, x2, voice.mix.get(i+1)*Scaler+height/9);
      }
    }
  } else {

    // render progress

    float x = map(voice.position(), 0, voice.length(), 0, width);
    line(0, height/9, x, height/9);
    thisDisplay += "\n\n" + voice.bufferSize() + " @ " + renderFPS + " fps / ";
    thisDisplay += renderFrame + " : " + int(voice.length()/renderStep + 1);
  }

  noStroke();
  textFont(display);
  textAlign(LEFT);
  text(thisDisplay, 10, 20);
  textAlign(CENTER);
}


void drawGrid() 
{       
  	pushMatrix();
  	translate(width/2, height/2);
  	stroke(0, 255, 255);
  	line(-width/2, 0, width/2, 0); 
  	line(0, -width/2, 0, width/2);

	textFont(display);
	textAlign(LEFT);
	for (int y=0; y<height; y+=height/10) {
  		line(-width/100, -y, width/100, -y);
  		line(-width/100, y, width/100, y);
		text(y, width/50, -y);
		text(y, width/50, y);
	}
	for (int x=0; x<width; x+=width/10) {
  		line(-x, -height/100, -x, height/100);
  		line(x, -height/100, x, height/100);
		text(x, -x, -height/50);
		text(x, x, -height/50);
	}
 	stroke(0);
	textAlign(CENTER);
  	popMatrix();
}


void startstopRender() 
{
  outputVideo = !outputVideo;
  outputAudio = !outputAudio;
  audioPlaying = !audioPlaying;
  displayHollows = true;
  voice.rewind();
  if (outputVideo) {
    voice.play();
  } else {
    voice.pause();
    stop();
  }
  renderPosition = 0.0;
  renderFrame = 0;
}


void stop() {
  minim.stop();
  super.stop();
  exit();
}

