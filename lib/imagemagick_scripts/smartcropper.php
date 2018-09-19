<?php
	try{
		parse_str(implode('&', array_slice($argv, 1)), $_GET);

		$size = explode('x', $_GET['size']);
		$h = intval($size[1]);
		$w = intval($size[0]);
		$image = $_GET['input_image'];
		// Hack for php 5.3. Replace with pathinfo($image)['extension']; when issue with php upgrading to 5.5 is solved
		$image_ext = substr($image, strrpos($image, '.') + 1);
		$out = $_GET['output_image'];
		define('GAMMA', 0.2);

		$ext = pathinfo($image, PATHINFO_EXTENSION);
		$tmp_image = '/tmp/smart-cropper-' . uniqid() . '.' . $ext;
		copy($image, $tmp_image);

		/*
	 * edge-maximizing crop
	 * determines center-of-edginess, then tries different-sized crops around it.
	 * picks the crop with the highest normalized edginess.
	 * see documentation on how to tune the algorithm
	 *
	 * $w, $h - target dimensions of thumbnail
	 * $image - system path to source image
	 * $out - path/name of output image
	 */

	  // source dimensions
	  $imginfo = getimagesize($tmp_image);
	  $w0 = $imginfo[0];
	  $h0 = $imginfo[1];

		// smart scaling in case if crop size is larger than actual image size
		if($h > $h0 || $w > $w0){
			$img_width = $w0;
			$img_height = $h0;
			$img_ar = floatval($img_width)/floatval($img_height);

			if($img_height < $h){
				$img_height = $h;
				$img_width = floatval($img_height)*$img_ar;
			}

			if($img_width < $w){
				$img_width = $w;
				$img_height = floatval($img_width)/$img_ar;
			}

			shell_exec("convert $tmp_image -resize " . intval($img_width) . '!x' . intval($img_height) . "! -gravity center $tmp_image");
		}

	  // parameters for the edge-maximizing crop algorithm
	  $r = 1;         // radius of edge filter
	  $nk = 9;        // scale count: number of crop sizes to try
	  $gamma = GAMMA;   // edge normalization parameter -- see documentation
	  $ar = $w/$h;    // target aspect ratio (AR)
	  $ar0 = $w0/$h0;    // target aspect ratio (AR)
	  print(basename($tmp_image).": $w0 x $h0 => $w x $h");
	  $img = new Imagick($tmp_image);
	  $imgcp = clone $img;
	  // compute center of edginess
	  $img->edgeImage($r);
	  $img->modulateImage(100,0,100); // grayscale
	  $img->blackThresholdImage("#0f0f0f");
	  $img->writeImage($out);

		// use gd for random pixel access
	  $im = null;
		if($image_ext == 'jpg' || $image_ext == 'jpeg'){
			$im = ImageCreateFromJpeg($out);
		}elseif($image_ext == 'png'){
			$im = ImageCreateFromPng($out);
		}elseif($image_ext == 'gif'){
			$im = ImageCreateFromGif($out);
		}
	  $xcenter = 0;
	  $ycenter = 0;
	  $sum = 0;
	  $n = 100000;
	  for ($k=0; $k<$n; $k++) {
	      $i = mt_rand(0,$w0-1);
	      $j = mt_rand(0,$h0-1);
				$rgb = @imagecolorat($im, $i, $j);
	      $val = $rgb & 0xFF;
	      $sum += $val;
	      $xcenter += ($i+1)*$val;
	      $ycenter += ($j+1)*$val;
	  }
	  $xcenter /= $sum;
	  $ycenter /= $sum;
	  // crop source img to target AR
	  if ($w0/$h0 > $ar) {
	      // source AR wider than target
	      // crop width to target AR
	      $wcrop0 = round($ar*$h0);
	      $hcrop0 = $h0;
	  }
	  else {
	      // crop height to target AR
	      $wcrop0 = $w0;
	      $hcrop0 = round($w0/$ar);
	  }
	  // crop parameters for all scales and translations
	  $params = array();
	  // crop at different scales
	  $hgap = $hcrop0 - $h;
	  $hinc = ($nk == 1) ? 0 : $hgap / ($nk - 1);
	  $wgap = $wcrop0 - $w;
	  $winc = ($nk == 1) ? 0 : $wgap / ($nk - 1);
	  // find window with highest normalized edginess
	  $n = 10000;
	  $maxbetanorm = 0;
	  $maxparam = array('w'=>0, 'h'=>0, 'x'=>0, 'y'=>0);
	  for ($k = 0; $k < $nk; $k++) {
	      $hcrop = round($hcrop0 - $k*$hinc);
	      $wcrop = round($wcrop0 - $k*$winc);
	      $xcrop = $xcenter - $wcrop / 2;
	      $ycrop = $ycenter - $hcrop / 2;
	      if ($xcrop < 0) $xcrop = 0;
	      if ($xcrop+$wcrop > $w0) $xcrop = $w0-$wcrop;
	      if ($ycrop < 0) $ycrop = 0;
	      if ($ycrop+$hcrop > $h0) $ycrop = $h0-$hcrop;

	      $beta = 0;
	      for ($c=0; $c<$n; $c++) {
	          $i = mt_rand(0,$wcrop-1);
	          $j = mt_rand(0,$hcrop-1);
	          $beta += @imagecolorat($im, $xcrop+$i, $ycrop+$j) & 0xFF;
	      }
	      $area = $wcrop * $hcrop;
	      $betanorm = $beta / ($n*pow($area, $gamma-1));

	      // best image found, save it
	      if ($betanorm > $maxbetanorm) {
	          $maxbetanorm = $betanorm;
	          $maxparam['w'] = $wcrop;
	          $maxparam['h'] = $hcrop;
	          $maxparam['x'] = $xcrop;
	          $maxparam['y'] = $ycrop;
	      }
	  }

	  // return image
	  $imgcp->cropImage($maxparam['w'],$maxparam['h'],
	      $maxparam['x'],$maxparam['y']);
	  $imgcp->scaleImage($w,$h);
	  $imgcp->writeImage($out);

	  chmod($out, 0777);
	  $img->destroy();
	  $imgcp->destroy();
	}catch(Exception $e){unlink($tmp_image);}
  return 0;
?>
