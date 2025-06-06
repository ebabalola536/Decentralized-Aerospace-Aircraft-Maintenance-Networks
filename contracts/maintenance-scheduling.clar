;; Maintenance Scheduling Contract
;; Manages aircraft maintenance scheduling and tracking

(define-map maintenance-schedules
  { schedule-id: uint }
  {
    aircraft-id: (string-ascii 50),
    airline-id: uint,
    maintenance-type: (string-ascii 50),
    scheduled-date: uint,
    estimated-duration: uint,
    technician-id: uint,
    status: (string-ascii 20),
    created-by: principal,
    created-at: uint
  }
)

(define-map aircraft-last-maintenance
  { aircraft-id: (string-ascii 50) }
  { last-maintenance-date: uint, next-due-date: uint }
)

(define-data-var next-schedule-id uint u1)

;; Schedule maintenance
(define-public (schedule-maintenance
  (aircraft-id (string-ascii 50))
  (airline-id uint)
  (maintenance-type (string-ascii 50))
  (scheduled-date uint)
  (estimated-duration uint)
  (technician-id uint)
)
  (let ((schedule-id (var-get next-schedule-id)))
    (map-set maintenance-schedules
      { schedule-id: schedule-id }
      {
        aircraft-id: aircraft-id,
        airline-id: airline-id,
        maintenance-type: maintenance-type,
        scheduled-date: scheduled-date,
        estimated-duration: estimated-duration,
        technician-id: technician-id,
        status: "scheduled",
        created-by: tx-sender,
        created-at: block-height
      }
    )
    (var-set next-schedule-id (+ schedule-id u1))
    (ok schedule-id)
  )
)

;; Update maintenance status
(define-public (update-maintenance-status (schedule-id uint) (new-status (string-ascii 20)))
  (let ((schedule (unwrap! (map-get? maintenance-schedules { schedule-id: schedule-id }) (err u200))))
    (asserts! (is-eq tx-sender (get created-by schedule)) (err u201))
    (map-set maintenance-schedules
      { schedule-id: schedule-id }
      (merge schedule { status: new-status })
    )
    (if (is-eq new-status "completed")
      (map-set aircraft-last-maintenance
        { aircraft-id: (get aircraft-id schedule) }
        {
          last-maintenance-date: block-height,
          next-due-date: (+ block-height u8760) ;; ~6 months in blocks
        }
      )
      true
    )
    (ok true)
  )
)

;; Get maintenance schedule
(define-read-only (get-maintenance-schedule (schedule-id uint))
  (map-get? maintenance-schedules { schedule-id: schedule-id })
)

;; Get aircraft maintenance status
(define-read-only (get-aircraft-maintenance-status (aircraft-id (string-ascii 50)))
  (map-get? aircraft-last-maintenance { aircraft-id: aircraft-id })
)
