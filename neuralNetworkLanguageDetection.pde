/*
Good options to change:
WINDOWS_SCALE_SIZE
MINIMUM_WORD_LENGTH
countedLanguages
*/
float WINDOW_SCALE_SIZE = 0.5;
int MINIMUM_WORD_LENGTH = 5;
float STARTING_AXON_VARIABILITY = 1.0;
int TRAINS_PER_FRAME = 20;
PFont font;
Brain brain;
int LANGUAGE_COUNT = 13;
int MIDDLE_LAYER_NEURON_COUNT = 19;
String[][] trainingData = new String[LANGUAGE_COUNT][];
int SAMPLE_LENGTH = 15;
int INPUTS_PER_CHAR = 27;
int INPUT_LAYER_HEIGHT = INPUTS_PER_CHAR*SAMPLE_LENGTH+1;
int OUTPUT_LAYER_HEIGHT = LANGUAGE_COUNT+1;
int lineAt = 0;
int iteration = 0;
int streak;
int longStreak;
int smooth = 0;
int guessWindow = 1000;
boolean[] recentGuesses = new boolean[guessWindow];
int recentRightCount = 0;
boolean training = false;
String word = "-";
int desiredOutput = 0;
int lastPressedKey = -1;
boolean typing = false;
int[] countedLanguages = {2,8};
boolean lastOneWasCorrect = false;
String[] languages = {"Random","Key Mash","English","Spanish","French","German","Japanese",
"Swahili","Mandarin","Esperanto","Dutch","Polish","Lojban"};
int[] langSizes = new int[LANGUAGE_COUNT];
void setup(){
  for(int i = 0; i < LANGUAGE_COUNT; i++){
    trainingData[i] = loadStrings("output"+i+".txt");
    String s = trainingData[i][trainingData[i].length-1];
    langSizes[i] = Integer.parseInt(s.substring(s.indexOf(",")+1,s.length()));
  }
  for(int i = 0; i < guessWindow; i++){
    recentGuesses[i] = false;
  }
  font = loadFont("Helvetica-Bold-96.vlw"); 
  int[] bls = {INPUT_LAYER_HEIGHT,MIDDLE_LAYER_NEURON_COUNT,OUTPUT_LAYER_HEIGHT};
  brain = new Brain(bls,INPUTS_PER_CHAR, languages);
  size((int)(1920*WINDOW_SCALE_SIZE),(int)(1080*WINDOW_SCALE_SIZE));
  frameRate(200);
}

void draw(){
  scale(WINDOW_SCALE_SIZE);
  smooth(smooth);
  if(keyPressed){
    int c = (int)(key);
    if(c == 49 && lastPressedKey != 49){
      training = !training;
      typing = false;
    }else if(c == 50 && lastPressedKey != 50){
      training = false;
      typing = false;
      train();
    }else if(c == 52 && lastPressedKey != 52){
      brain.alpha *= 2;
    }else if(c == 51 && lastPressedKey != 51){
      brain.alpha *= 0.5;
    }else if(c >= 97 && c <= 122 && !(lastPressedKey >= 97 && lastPressedKey <= 122)){
      training = false;
      if(!typing){
        word = "";
      }
      typing = true;
      word = (word+(char)(c)).toUpperCase();
      getBrainErrorFromLine(word,0,false);
    }else if(c == 8 && lastPressedKey != 8){
      training = false;
      if(typing && word.length() >= 1){
        word = word.substring(0,word.length()-1);
      }
      typing = true;
      getBrainErrorFromLine(word,0,false);
    }else if(c == 53 && lastPressedKey != 53){
      smooth++;
      if(smooth == 2){
        smooth = 0;
      }
    }
    lastPressedKey = c;
  }else{
    lastPressedKey = -1;
  }
  if(training){
    for(int i = 0; i < TRAINS_PER_FRAME; i++){
      train();
    }
  }
  background(255);
  fill(0);
  textFont(font,48);
  textAlign(LEFT);
  text("Cary's Neural Net!",20,50);
  text("Iteration #"+iteration,20,150);
  text("Input word:",20,250);
  fill(0,0,255);
  text(word.toUpperCase(),20,300);
  fill(0);
  text("Expected output:",20,350);
  text("Current streak: "+streak,20,900);
  text("Longest streak: "+longStreak,20,950);
  String o = languages[desiredOutput];
  if(typing){
    o = "???";
  }
  fill(0,0,255);
  text(o,20,400);
  fill(0);
  text("Step size:",20,500);
  text(nf((float)(brain.alpha),0,4),20,550);
  
  text("Min Word Len: "+MINIMUM_WORD_LENGTH,20,650);
  text("Possible Languages:",20,700);
  for(int i = 0; i < countedLanguages.length; i++){
    text(languages[countedLanguages[i]],20,750+i*50);
  }
   
  int ex = 1330;
  text("Actual prediction:",ex,50);
  String s = "";
  if(typing){
    s = "HOW'D I DO?";
    fill(160,120,0);
  }else{
    if(lastOneWasCorrect){
      s = "RIGHT";
      fill(0,140,0);
      if(training == true){
        streak++;
      }
      
    }else{
      s = "WRONG";
      fill(255,0,0);
      streak = 0;
    }
     if(streak > longStreak){
        longStreak = streak;
      }
      
  }
  text(languages[brain.topOutput]+" ("+s+")",ex,100);
  fill(0);
  
  text("Confidence: "+percentify(brain.confidence),ex,150);
  
  text("% of last "+guessWindow+" correct:",ex,250);
  text(percentify(((float)recentRightCount)/min(iteration,guessWindow)),ex,300);
  
  text("1 to toggle training.",ex,400);
  text("2 to do one training.",ex,450);
  text("3 to decrease step size.",ex,500);
  text("4 to increase step size.",ex,550);
  text("5 to toggle smoothing.",ex,600);
  if(smooth == 1){
    text("Smoothing is on.",ex,1000);
  }
  translate(550,40);
  brain.drawBrain(55);
  lineAt++;
}
void train(){
  int lang = countedLanguages[(int)(random(0,countedLanguages.length))];//(int)(random(0,LANGUAGE_COUNT));
  word = "";
  while(word.length() < MINIMUM_WORD_LENGTH){
    int wordIndex = (int)(random(0,langSizes[lang]));
    lineAt = binarySearch(lang, wordIndex);
    String[] parts = trainingData[lang][lineAt].split(",");
    word = parts[0];
  }
  desiredOutput = lang;//Integer.parseInt(parts[1]);
  double error = getBrainErrorFromLine(word,desiredOutput,true);
  if(brain.topOutput == desiredOutput){
    if(!recentGuesses[iteration%guessWindow]){
      recentRightCount++;
    }
    recentGuesses[iteration%guessWindow] = true;
    lastOneWasCorrect = true;
  }else{
    if(recentGuesses[iteration%guessWindow]){
      recentRightCount--;
    }
    recentGuesses[iteration%guessWindow] = false;
    lastOneWasCorrect = false;
  }

}
int binarySearch(int lang, int n){
  return binarySearch(lang,n,0,trainingData[lang].length-1);
}
int binarySearch(int lang, int n, int beg, int end){
  if(beg > end){
    return beg;
  }
  int mid = (beg+end)/2;
  
  String s = trainingData[lang][mid];
  int diff = n-Integer.parseInt(s.substring(s.lastIndexOf(",")+1,s.length()));
  if(diff == 0){
    return mid+1;
  }else if(diff > 0){
    return binarySearch(lang,n,mid+1,end);
  }else if(diff < 0){
    return binarySearch(lang,n,beg,mid-1);
  }
  return -1;
}
String percentify(double d){
  return nf((float)(d*100),0,2)+"%";
}
double getBrainErrorFromLine(String word, int desiredOutput, boolean train){
  double inputs[] = new double[INPUT_LAYER_HEIGHT];
  for(int i = 0; i < INPUT_LAYER_HEIGHT; i++){
    inputs[i] = 0;
  }
  for(int i = 0; i < SAMPLE_LENGTH; i++){
    int c = 0;
    if(i < word.length()){
      c = (int)word.toUpperCase().charAt(i)-64;
    }
    c = max(0,c);
    inputs[i*INPUTS_PER_CHAR+c] = 1;
  }
  double desiredOutputs[] = new double[OUTPUT_LAYER_HEIGHT];
  for(int i = 0; i < OUTPUT_LAYER_HEIGHT; i++){
    desiredOutputs[i] = 0;
  }
  desiredOutputs[desiredOutput] = 1;
  if(train){
    iteration++;
  }
  return brain.useBrainGetError(inputs, desiredOutputs,train);
}
