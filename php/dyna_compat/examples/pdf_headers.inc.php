<?php
if (headers_sent()) die('');
header('MIME-Version: 1.0');
header('Expires: Mon, 31 Dec 2012 08:00:00 GMT');
header('Last-Modified: '.gmdate('D, d M Y H:i:s').' GMT');
header('Content-Description: File Transfer');
if ($attach)
	header('Content-Disposition: attachment; filename='.$fileName);
else
	header('Content-Disposition: inline; filename='.$fileName);
if (!isset($mime))
	header('Content-Type: application/pdf');
else
	header('Content-Type: '.$mime);
header('Content-Transfer-Encoding: binary');
header('Content-Length: '.$fileSize);
if ($_SERVER['HTTPS'] != 'on' && !$HTTP_SERVER_VARS['HTTP_X_FORWARDED_HOST'])
{
	if (strpos($_SERVER['HTTP_USER_AGENT'],'MSIE') !== false)
		header('Cache-Control: public');
	else
	{
		header('Cache-Control: no-cache, must-revalidate');
		header('Cache-Control: post-check=0, pre-check=0');
		header('Pragma: no-cache');
	}
}else
{
	header ('Cache-Control: must-revalidate, post-check=0,pre-check=0');
	header ('Pragma: public');
}
?>