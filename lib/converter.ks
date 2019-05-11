@LazyGlobal off.


global function lngObtToBody {
	parameter p_body.
	parameter p_lng.
	
	return mod(p_lng - p_body:rotationAngle + 540, 360) - 180.
}