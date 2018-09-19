<?php
	require_once('SlyCropEntropy.php');

	parse_str(implode('&', array_slice($argv, 1)), $_GET);

	$input_image =$_GET['input_image'];
	$size = explode('x', $_GET['size']);
	$output_image = $_GET['output_image'];

	$entropy = new SlyCropEntropy($input_image);
	$croppedImage = $entropy->resizeAndCrop($size[0], $size[1]);
	$croppedImage->writeimage($output_image);
?>
