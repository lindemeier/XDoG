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

final float tensor_sigma = 3.f;

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

  edgeTangentFlow = computeEdgeTangentFlow(sourceRGB, tensor_sigma); 

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
    displayedImage = originalRgb;
  } else if (key == '2')
  {
    displayedText = "edge tangent flow";   
    displayedImage = computeLineIntegralConvolution(edgeTangentFlow, 15.f).toPImage();
  } 

  redraw();
}

/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////

FImage computeEdgeTangentFlow(final FImage input, final float tensor_sigma)
{
  // compute structure tensors from rgb image
  FImage tensors = computeStructureTensors(input);

  // smooth tensors with Gaussian blur
  if (tensor_sigma > 0.5f)
  {
    tensors = GaussianBlur(tensors, tensor_sigma);
  }

  FImage tfm = computeTangentFlowMap(tensors);

  return tfm;
}
