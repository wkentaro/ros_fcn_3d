#!/usr/bin/env roseus
;; vim: set ft=lisp:

(require "models/room73b2-scene.l")


(defun setup ()
  (ros::roseus "room73b2-point-cloud-publisher" :anonymous nil)
  (ros::advertise (format nil "~a/output" (ros::get-name)) sensor_msgs::PointCloud2)

  (unless (boundp '*room73b2*)
    (room73b2)
    (send *room73b2* :remove-spots (send *room73b2* :spots))
    (objects (list *room73b2*))
    )

  (setq min-x -1000)
  (setq max-x 11000)
  (setq min-y -5000)
  (setq max-y 5000)
  (setq min-z 0)
  (setq max-z 3000)

  (unless (boundp '*camera-model*)
    (setq *camera-model*
          (make-camera-from-param :pwidth 640 :pheight 480
                                  :fx 400 :fy 400
                                  :cx 319.5 :cy 179.5 :name "camtest"
                                  :create-viewer t))
    )
  )


(defun spin-once ()
  (setq loc
        (float-vector
          (+ (random (- max-x min-x)) min-x)
          (+ (random (- max-y min-y)) min-y)
          (+ (random (- max-z min-z)) min-z)))

  (ros::ros-info "Camera loc: ~a" loc)
  ;; move camera
  (send *camera-model* :locate loc :world)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :x)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :y)
  (send *camera-model* :orient (* (random 36) (/ 2pi 36)) :z)

  (setq camera-cube
        (make-cube 500 500 500
                   :pos (send *camera-model* :worldpos)))
  (send camera-cube :set-color :red)
  (objects (list camera-cube *room73b2*))

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
          (setq points (cdr ret))
          )
        ;; publish
        (send points :convert-to-world :create nil)
        (setq msg
          (make-ros-msg-from-eus-pointcloud
            points
            :with-color :rgb
            :with-normal nil
            :frame "world"
            )
          )
        (ros::publish (format nil "~a/output" (ros::get-name)) msg)
        (unix::sleep 60)
        )
      )
    )
  )


(defun spin() (do-until-key (spin-once)))


;; __main__
(setup)
(spin)
