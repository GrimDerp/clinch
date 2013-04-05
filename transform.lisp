;;;; transform.lisp
;;;; Please see the licence.txt for the CLinch 

(in-package #:clinch)

(defconstant +pi+ (coerce pi 'single-float))

(defmacro ensure-float (x)
  `(coerce ,x 'single-float))


(defmacro degrees->radians (degrees)
  (coerce (* 2 pi (/ degrees 360)) 'single-float))

(defun radians->degrees (radians)
  (coerce (* 180 (/ radians pi)) 'single-float))

(defun make-matrix (m11 m12 m13 m14 
		    m21 m22 m23 m24
		    m31 m32 m33 m34
		    m41 m42 m43 m44)
  (sb-cga:matrix (ENSURE-FLOAT M11) (ENSURE-FLOAT M12) (ENSURE-FLOAT M13) (ENSURE-FLOAT M14) 
		 (ENSURE-FLOAT M21) (ENSURE-FLOAT M22) (ENSURE-FLOAT M23) (ENSURE-FLOAT M24) 
		 (ENSURE-FLOAT M31) (ENSURE-FLOAT M32) (ENSURE-FLOAT M33) (ENSURE-FLOAT M34)
		 (ENSURE-FLOAT M41) (ENSURE-FLOAT M42) (ENSURE-FLOAT M43) (ENSURE-FLOAT M44)))


(defun make-orthogonal-transform (width height near far)
  "Create a raw CFFI orthogonal matrix."
  (make-matrix (/ 2 width) 0.0 0.0 0.0
	       0.0 (/ 2 height) 0.0 0.0
	       0.0 0.0 (/ (- far near)) (/ (- near) (- far near)) 
	       0.0 0.0 0.0 1.0))

(defun make-frustum-transform (left right bottom top near far)
  "Create a raw CFFI frustum matrix."  
  (let ((a (/ (+ right left) (- right left)))
	(b (/ (+ top bottom) (- top bottom)))
	(c (- (/ (+ far near) (- far near))))
	(d (- (/ (* 2 far near) (- far near)))))
    
    (make-matrix (/ (* 2 near) (- right left)) 0 A 0
		 0 (/ (* 2 near) (- top bottom)) B 0
		 0 0 C D
		 0 0 -1 0)))

;; (defun make-frustum-transform (left right bottom top near far)
;;   "Create a raw CFFI frustum matrix."  
;;   (let ((a (- (/ (+ right left) (- right left))))
;; 	(b (- (/ (+ top bottom) (- top bottom))))
;; 	(c (/ -2 (- far near)))
;; 	(d (- (/ (+ far near) (- far near)))))
    
;;     (sb-cga:transpose-matrix
;;      (make-matrix (/ 2 (- right left)) 0 0 A
;; 		  0 (/ 2 (- top bottom)) 0 B
;; 		  0 0 C D
;; 		  0 0 0 1))))


(defun make-perspective-transform  (fovy aspect znear zfar)
  "Create a raw CFFI perspective matrix."
  (let* ((ymax (* znear (tan fovy)))
	 (xmax (* ymax aspect)))
    (make-frustum-transform (- xmax) xmax (- ymax) ymax znear zfar)))


(defun transform-point (p m)
  (let ((w (/
	    (+ (* (elt m 3) (elt p 0))
	       (* (elt m 7) (elt p 1))
	       (* (elt m 11) (elt p 2))
	       (elt m 15)))))
    (make-vector (* w (+ (* (elt m 0) (elt p 0))
			 (* (elt m 4) (elt p 1))
			 (* (elt m 8) (elt p 2))
			 (elt m 12)))
		 (* w (+ (* (elt m 1) (elt p 0))
			 (* (elt m 5) (elt p 1))
			 (* (elt m 9) (elt p 2))
			 (elt m 13)))
		 (* w (+ (* (elt m 2) (elt p 0))
			 (* (elt m 6) (elt p 1))
			 (* (elt m 10) (elt p 2))
			 (elt m 14))))))

						     

  ;; int glhUnProjectf(float winx, float winy, float winz, float *modelview, float *projection, int *viewport, float *objectCoordinate)
  ;; {
  ;;     //Transformation matrices
  ;;     float m[16], A[16];
  ;;     float in[4], out[4];
  ;;     //Calculation for inverting a matrix, compute projection x modelview
  ;;     //and store in A[16]

(defun unproject (x y width height transform)
  (let* ((new-x (1- (/ (* 2 x) width)))
	 (new-y (1- (/ (* 2 y) height)))
	 (inv (sb-cga:inverse-matrix transform))
	 (start (clinch:transform-point (clinch:make-vector new-x new-y 0) inv))
	 (end   (clinch:transform-point (clinch:make-vector new-x new-y 1) inv)))
    (values start
	    (sb-cga:normalize (sb-cga:vec- end start)))))
  
;; (defun unproject (x y z
;; 		  modelview-matrix projection-matrix
;; 		  viewport-x viewport-y viewport-width viewport-height)

;;   )
		  
  ;;     MultiplyMatrices4by4OpenGL_FLOAT(A, projection, modelview);
  ;;     //Now compute the inverse of matrix A
  ;;     if(glhInvertMatrixf2(A, m)==0)
  ;;        return 0;
  ;;     //Transformation of normalized coordinates between -1 and 1
  ;;     in[0]=(winx-(float)viewport[0])/(float)viewport[2]*2.0-1.0;
  ;;     in[1]=(winy-(float)viewport[1])/(float)viewport[3]*2.0-1.0;
  ;;     in[2]=2.0*winz-1.0;
  ;;     in[3]=1.0;
  ;;     //Objects coordinates
  ;;     MultiplyMatrixByVector4by4OpenGL_FLOAT(out, m, in);
  ;;     if(out[3]==0.0)
  ;;        return 0;
  ;;     out[3]=1.0/out[3];
  ;;     objectCoordinate[0]=out[0]*out[3];
  ;;     objectCoordinate[1]=out[1]*out[3];
  ;;     objectCoordinate[2]=out[2]*out[3];
  ;;     return 1;
  ;; }
 
;; Use this!!!!
;; unProject(float winx, float winy, float winz,
;;                           float[] modelMatrix, int moffset,
;;                           float[] projMatrix, int poffset,
;;                           int[] viewport, int voffset,
;;                           float[] obj, int ooffset) {
;;   float[] finalMatrix = new float[16];
;;   float[] in = new float[4];
;;   float[] out = new float[4];

;;   Matrix.multiplyMM(finalMatrix, 0, projMatrix, poffset,
;;     modelMatrix, moffset);
;;   if (!Matrix.invertM(finalMatrix, 0, finalMatrix, 0))
;;     return false;

;;   in[0] = winx;
;;   in[1] = winy;
;;   in[2] = winz;
;;   in[3] = 1.0f;

;;   // Map x and y from window coordinates
;;   in[0] = (in[0] - viewport[voffset]) / viewport[voffset + 2];
;;   in[1] = (in[1] - viewport[voffset + 1]) / viewport[voffset + 3];

;;   // Map to range -1 to 1
;;   in[0] = in[0] * 2 - 1;
;;   in[1] = in[1] * 2 - 1;
;;   in[2] = in[2] * 2 - 1;

;;   Matrix.multiplyMV(out, 0, finalMatrix, 0, in, 0);
;;   if (out[3] == 0.0f)
;;     return false;

;;   out[0] /= out[3];
;;   out[1] /= out[3];
;;   out[2] /= out[3];
;;   obj[ooffset] = out[0];
;;   obj[ooffset + 1] = out[1];
;;   obj[ooffset + 2] = out[2];

;;   return true;
;; }