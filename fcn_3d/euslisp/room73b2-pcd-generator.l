#!/usr/bin/env roseus
;; vim: set ft=lisp:
(require "models/room73b2-scene.l")


(defun setup ()
  (unless (boundp '*room73b2*)
    (room73b2)
    (send *room73b2* :remove-spots (send *room73b2* :spots))
    (objects (list *room73b2*))
    )

  (unless (boundp '*points*)
    (setq *points* nil)
    )

  (unless (boundp '*camera-model*)
    (setq *camera-model*
          (make-camera-from-param :pwidth 640 :pheight 480
                                  :fx 400 :fy 400
                                  :cx 319.5 :cy 179.5 :name "camtest"
                                  :create-viewer t))
    )
  )


(defun spin-once ()
  (setq min-x -1000)
  (setq max-x 11000)
  (setq min-y -5000)
  (setq max-y 5000)
  (setq min-z 0)
  (setq max-z 3000)
  (setq loc
        (float-vector
          (+ (random (- max-x min-x)) min-x)
          (+ (random (- max-y min-y)) min-y)
          (+ (random (- max-z min-z)) min-z)))

  ;; move camera
  (ros::ros-info "Camera loc: ~a" loc)
  (send *camera-model* :locate loc :world)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :x)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :y)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :z)

  ;; draw objects
  (dotimes (r-step 2)
    (dotimes (p-step 2)
      (dotimes (y-step 2)
        ;; rotate camera
        (send *camera-model* :orient (* r-step (/ 2pi 2)) :x)
        (send *camera-model* :orient (* p-step (/ 2pi 2)) :y)
        (send *camera-model* :orient (* y-step (/ 2pi 2)) :z)
        ;; draw objects
        (send *camera-model* :draw-objects (list *room73b2*))
        ;; store points
        (let ((ret (send *camera-model* :get-image :with-points t :with-colors t)))
          (send (cdr ret) :transform (send *camera-model* :worldcoords))
          (push  (cdr ret) *points*))
        )
      )
    )
  )


(defun spin ()
  (ros::ros-info "Storing point cloud with random camera views.")
  (setq max-iter 3)
  (dotimes (i max-iter)
    (ros::ros-info "~a / ~a [~a%]" (+ i 1) max-iter (* (/ (* 1.0 (+ i 1)) max-iter) 100))
    (spin-once)
    )

  (mapcar #'(lambda (x) (send x :convert-to-world :create nil)) *points*)
  (setq points-all (send (car *points*) :append (cdr *points*)))
  (dump-pointcloud-to-pcd-file "room73b2.pcd" points-all)
  )


;; __main__
(setup)
(spin)
(exit)
