// input image location
final String imageFile = "data/portrait.jpg";

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
final float xdogParamRho = 0.998f;
//creates an adjustable
//soft ramp between the edge and non-edge values, with parameter φ
//controlling the steepness of this transition
final float xdogParamPhi = 1.0f;

// orientation aligned bilateral filter
final float oabfSigma_d = 3.f;
final float oabfSigma_r = 4.25f;
final int oabfIterations = 5;

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
    displayedImage = originalRgb;
  } else if (key == '2')
  {
    displayedText = "edge tangent flow";   
    displayedImage = computeLineIntegralConvolution(edgeTangentFlow, 15.f).toPImage();
  } else if (key == '3')
  {
    displayedText = "DoG isotropic simple threshold   ";   
    displayedImage = xdogSimpleThresholding(originalLab, 0).toPImage();
  } else if (key == '4')
  {
    displayedText = "DoG isotropic thresholding   ";   
    displayedImage = xdogThresholding(originalLab, 0).toPImage();
  } else if (key == '5')
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

FImage computeDoGIsotropic(final FImage input, final float sigma, final float kappa, final float rho)
{  
  FImage G0 = GaussianBlur(input, sigma);
  FImage G1 = GaussianBlur(input, kappa * sigma);

  for (int i = 0; i < G0.data.length; i++)
  {
    G0.data[i] -= rho * G1.data[i];
  }

  return G0;
}

FImage xdogSimpleThresholding(FImage input, int channel)
{
  FImage G0 = GaussianBlur(input, xdogParamSigma);
  FImage G1 = GaussianBlur(input, xdogParamKappa * xdogParamSigma);

  for (int i = 0; i < G0.data.length; i++)
  {
    G0.data[i] -= G1.data[i];
  }
  G0 = G0.extractChannel(channel);
  for (int i = 0; i < G0.data.length; i++)
  {
    G0.data[i] = (G0.data[i] > 0.0) ? 1.0 : 0.0;
  }

  return G0;
}

FImage xdogThresholding(final FImage input, final int channel)
{
  FImage D = computeDoGIsotropic(input, xdogParamSigma, xdogParamKappa, xdogParamRho).extractChannel(channel);
  for (int i = 0; i < D.data.length; i++)
  {
    float e = D.data[i];
    D.data[i] = (e < xdogParamEps) ? 1.0 : (1.0f + (float)java.lang.Math.tanh(xdogParamPhi * e));
  }

  return D;
}
