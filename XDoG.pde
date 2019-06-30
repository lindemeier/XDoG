// input image location
final String imageFile = "data/Butterfly.jpg";

// input images in RGB and CIE Lab color space
PImage originalRgb;
FImage originalLab;

// edge tangent flow field
FImage edgeTangentFlow;

String displayedText = "input image";
PImage displayedImage;

/////////////////////////////////////////
/////////////  Params ///////////////////
/////////////////////////////////////////

final float tensorOuterSigma = 3.f;

// standard deviation of the Gaussian blur
final float xdogParamSigma = 3.0f;
// Differences of Gaussians factor
final float xdogParamKappa = 3.0f;

/////////////////////////////////////////
/////////////   Init  ///////////////////
/////////////////////////////////////////

void settings()
{
  originalRgb =  loadImage(imageFile);
  displayedImage = originalRgb;

  size(originalRgb.width, originalRgb.height);
}

void setup()
{
  FImage sourceRGB = new FImage(originalRgb);

  originalLab = convert_srgb2Lab(sourceRGB);

  edgeTangentFlow = computeEdgeTangentFlow(sourceRGB, tensorOuterSigma); 

  noLoop();
}

/////////////////////////////////////////
///// processing loop functions /////////
/////////////////////////////////////////

void draw()
{  
  image(displayedImage, 0, 0, width, height);

  fill(255, 200);
  rect(10, 10, 10+textWidth(displayedText)+6, 10+textAscent()+2);
  fill(0, 200);
  text(displayedText, 10+4, 10+textAscent()+4);
}

void keyPressed()
{
  if (key == '1')
  {
    displayedText = "input            "; 
    //displayedImage = originalRgb;
    displayedImage = GaussianBlur(new FImage(originalRgb), 15.0).toPImage();
  } else if (key == '2')
  {
    displayedText = "edge tangent flow";   
    displayedImage = computeLineIntegralConvolution(edgeTangentFlow, 15.f).toPImage();
  } 

  redraw();
}

/////////////////////////////////////////
////////////// functions ////////////////
/////////////////////////////////////////

// Compute a flow field of an image
FImage computeEdgeTangentFlow(final FImage input, final float tensorOuterSigma)
{
  // compute structure tensors from rgb image
  FImage tensors = computeStructureTensors(input);

  // smooth tensors with Gaussian blur
  if (tensorOuterSigma > 0.5f)
  {
    tensors = GaussianBlur(tensors, tensorOuterSigma);
  }

  FImage tfm = computeTangentFlowMap(tensors);

  return tfm;
}

FImage computeDoG(final FImage input, final float sigma, final float kappa)
{
  
  return new FImage(input.width, input.height, 1);
}
