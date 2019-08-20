@LazyGlobal off.

global function lngObtToBody {
	parameter p_body.
	parameter p_lng.
	
	return mod(p_lng - p_body:rotationAngle + 540, 360) - 180.
}

global function lngBodyToObt {
	parameter p_body.
	parameter p_lng.
	
	return mod(p_lng + 360 + p_body:rotationAngle, 360).
}