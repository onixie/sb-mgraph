;;;; sb-mgraph.lisp

(in-package #:sb-mgraph)

;;; "sb-mgraph" goes here. Hacks and glory await!
(defclass mem ()
  ())
(defgeneric readonly-space-boundary (mem))
(defgeneric readonly-space-size (mem))
(defgeneric static-space-boundary (mem))
(defgeneric static-space-size (mem))
(defgeneric dynamic-space-boundary (mem))
(defgeneric dynamic-space-free (mem))
(defgeneric dynamic-space-allocated-boundary (mem))
(defgeneric dynamic-space-allocated-size (mem))
(defgeneric dynamic-space-size (mem))
(defgeneric threads-boundaries (mem))
(defgeneric threads-sizes (mem))

(defclass lisp-mem (mem)
  ())

(defmethod readonly-space-boundary ((mem lisp-mem))
  (list sb-vm::read-only-space-start sb-vm::read-only-space-end))
(defmethod readonly-space-size ((mem lisp-mem))
  (- sb-vm::read-only-space-end sb-vm::read-only-space-start))

(defmethod static-space-boundary ((mem lisp-mem))
  (list sb-vm::static-space-start sb-vm::static-space-end))
(defmethod static-space-size ((mem lisp-mem))
  (- sb-vm::static-space-end sb-vm::static-space-start))

(defmethod dynamic-space-boundary ((mem lisp-mem))
  (list sb-vm::dynamic-space-start sb-vm::dynamic-space-end))
(defmethod dynamic-space-size ((mem lisp-mem))
  (- sb-vm::dynamic-space-end sb-vm::dynamic-space-start))

(defmethod dynamic-space-allocated-boundary ((mem lisp-mem))
  (list sb-vm::dynamic-space-start (sb-sys::sap-int (sb-c::dynamic-space-free-pointer))))
(defmethod dynamic-space-allocated-size ((mem lisp-mem))
  (- (sb-sys::sap-int (sb-c::dynamic-space-free-pointer)) sb-vm::dynamic-space-start))

(defmethod threads-boundaries ((mem lisp-mem))
  nil)

(define-presentation-method present (lisp-mem (type lisp-mem) stream (view textual-view) &key)
  (format stream "Readonly:(~{0x~x~^,~})~&" (readonly-space-boundary lisp-mem))
  (format stream "Static:(~{0x~x~^,~})~&" (static-space-boundary lisp-mem))
  (format stream "Dynamic:(~{0x~x~^,~})~&" (dynamic-space-boundary lisp-mem))
  (format stream "Dynamic(allocated):(~{0x~x~^,~})~&" (dynamic-space-allocated-boundary lisp-mem)))

(define-presentation-method present (lisp-mem (type lisp-mem) stream (view gadget-view) &key)
  (let*	((width 600)
	 (height 30)
	 (r-scale 20)
	 (s-scale 20)
	 (d-scale 1)
	 (r-size (readonly-space-size lisp-mem))
	 (s-size (static-space-size lisp-mem))
	 (d-size (dynamic-space-size lisp-mem))
	 (da-size (dynamic-space-allocated-size lisp-mem))
	 (total-size (+ d-size r-size s-size))

	 (rs-size (1- (/ (* r-scale width r-size) total-size)))
	 (ss-size (1- (/ (* s-scale width s-size) total-size)))
	 (ds-size (1- (/ (* d-scale width d-size) total-size)))
	 (das-size (1- (/ (* d-scale width da-size) total-size)))
	 (ts-size (+ rs-size ss-size ds-size)))
    (with-room-for-graphics (stream)
      (draw-rectangle* stream 0 0 ts-size height :filled nil)
      (with-translation (stream 0 0)
	(draw-rectangle* stream 1 0 rs-size (1- height) :ink +blue+)
	(with-translation (stream rs-size 0)
	  (draw-rectangle* stream 1 0 ss-size (1- height) :ink +green+)
	  (with-translation (stream ss-size 0)
	    (draw-rectangle* stream 1 0 ds-size (1- height) :ink +pink+)
	    (draw-rectangle* stream 1 0 das-size (1- height) :ink +red+)))))))

(define-application-frame ct ()
  ((timer-on :accessor timer-on :initarg :timer)
   (sampling :accessor sampling :initarg :sampling-rate))
  (:panes
   (graph :application
	  :width 800 :height :compute
	  :scroll-bars nil
	  :display-function 'graph-display
	  :display-time nil
	  :default-view +gadget-view+)
   (refresh :push-button
	    :label "Refresh"
	    :activate-callback #'(lambda (gadget)
				   (declare (ignorable gadget))
				   (let* ((frame *application-frame*)
					  (graph (find-pane-named frame 'graph))
					  (refresh (find-pane-named frame 'refresh)))
				     (cond ((null (timer-on frame))
					    (setf (gadget-label refresh) "Stop")
					    (setf (timer-on frame)
						  (sb-ext:make-timer #'(lambda ()
									 (redisplay-frame-pane frame graph :force-p t))))
					    (sb-ext:schedule-timer (timer-on frame) (sampling frame) :repeat-interval (sampling frame)))
					   (t
					    (setf (gadget-label refresh) "Refresh")
					    (sb-ext:unschedule-timer (timer-on frame))
					    (setf (timer-on frame) nil)))
				     (print (timer-on *application-frame*)))))
   (exit :push-button
	 :label "Quit"
	 :activate-callback #'(lambda (gadget)
				(declare (ignore gadget))
				(frame-exit *application-frame*))))
  (:layouts 
   (:default (vertically ()
	       (4/6 graph)
	       (1/6 refresh)
	       (1/6 exit))))
  (:default-initargs :timer nil :sampling-rate 1/10))

(defmethod graph-display ((frame ct) stream)
  (present *lisp-mem*))

(defvar *lisp-mem* (make-instance 'lisp-mem))
(defun start ()
  (find-application-frame 'ct :pretty-name "SBCL Memory Graph"))
