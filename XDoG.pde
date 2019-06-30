// input image location
final String imageFile = "data/portrait.jpg";

// input images in RGB and CIE Lab color space
PImage originalRgb;
FImage originalLab;

String displayedText = "input image";
PImage displayedImage;

/////////////////////////////////////////
/////////////  Params ///////////////////
/////////////////////////////////////////

final float tensorOuterSigma = 3.f;

// standard deviation of the Gaussian blur
final float xdogParamSigma = 2.0f;
// Differences of Gaussians factor
final float xdogParamKappa = 1.6f;
// shifts the detection threshold, thereby controlling sensitivity (albeit on
// an inverted scale: Smaller values make the edge detection more
// sensitive, while large values decrease detection sensitivity).
final float xdogParamEps = -15.0f;
// changes the relative weighting between the larger and
// smaller Gaussians, thereby affecting the tone-mapping response of
// the operator.
final float xdogParamTau = 0.998f;
//creates an adjustable
//soft ramp between the edge and non-edge values, with parameter φ
//controlling the steepness of this transition
final float xdogParamPhi = 1.0f;

// orientation aligned bilateral filter
final float oabfSigma_d = 3.f;
final float oabfSigma_r = 4.25f;
final int oabfIterations = 5;

/////////////////////////////////////////
//////////  cached results //////////////
/////////////////////////////////////////

// edge tangent flow field
FImage edgeTangentFlow;

// DoG response
FImage dogResponse;

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

  // 
  dogResponse = new FImage(originalLab.width, originalLab.height, 1); 
  fdogAlongGradient(
    originalLab, dogResponse, edgeTangentFlow, xdogParamSigma, xdogParamKappa * xdogParamSigma, xdogParamTau);

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
  } else if (key == '3')
  {
    displayedText = "DoG Response";   
    displayedImage = dogResponse.toPImage();
  } else if (key == '4')
  {
    displayedText = "Flow based DoG along gradient";   
    FImage dst = new FImage(originalLab.width, originalLab.height, 1); 
    fdogAlongGradient(
      originalLab, dst, edgeTangentFlow, xdogParamSigma, xdogParamKappa * xdogParamSigma, xdogParamTau);
    displayedImage = dst.toPImage();
  } else if (key == '5')
  {
    displayedText = "Flow based DoG along flow";   
    FImage dst = new FImage(originalLab.width, originalLab.height, 1); 
    fdogAlongFlow(
      originalLab, dst, edgeTangentFlow, xdogParamSigma);
    displayedImage = dst.toPImage();
  } else if (key == '6')
  {
    displayedText = "DoG simple thresholding   ";   
    displayedImage = xdogSimpleThresholding(dogResponse).toPImage();
  } else if (key == '7')
  {
    displayedText = "XDoG";   
    displayedImage = 
      xdogThresholding(dogResponse).toPImage();
  } else if (key == '8')
  {
    displayedText = "Orientation aligned bilateral filter";   
    displayedImage = convert_Lab2srgb(
      filterOrientationAlignedBilateral(
      originalLab, edgeTangentFlow, oabfSigma_d, oabfSigma_r, oabfIterations)).toPImage();
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

FImage computeDoGIsotropic(final FImage input, final float sigma, final float kappa, final float tau)
{  
  FImage G0 = GaussianBlur(input, sigma);
  FImage G1 = GaussianBlur(input, kappa * sigma);

  for (int i = 0; i < G0.data.length; i++)
  {
    G0.data[i] -= tau * G1.data[i];
  }

  return G0;
}

FImage xdogSimpleThresholding(FImage response)
{  
  FImage out = new FImage(response. width, response.height, 1);
  for (int i = 0; i < response.data.length; i++)
  {
    out.data[i] = (response.data[i] > 0.0) ? 1.0 : 0.0;
  }

  return out;
}

FImage xdogThresholding(final FImage response)
{  
  FImage out = new FImage(response. width, response.height, 1);
  for (int i = 0; i < response.data.length; i++)
  {
    float e = response.data[i];
    out.data[i] = (e < xdogParamEps) ? 1.0 : (1.0f + (float)java.lang.Math.tanh(xdogParamPhi * e));
  }

  return out;
}
