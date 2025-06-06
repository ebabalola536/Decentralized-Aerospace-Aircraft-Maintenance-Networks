;; Airline Verification Contract
;; Manages verification and registration of commercial airlines

(define-map airlines
  { airline-id: uint }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    country: (string-ascii 50),
    verified: bool,
    verification-date: uint,
    verifier: principal
  }
)

(define-map airline-by-principal
  { airline: principal }
  { airline-id: uint }
)

(define-data-var next-airline-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Register a new airline
(define-public (register-airline (name (string-ascii 100)) (license-number (string-ascii 50)) (country (string-ascii 50)))
  (let ((airline-id (var-get next-airline-id)))
    (asserts! (is-none (map-get? airline-by-principal { airline: tx-sender })) (err u100))
    (map-set airlines
      { airline-id: airline-id }
      {
        name: name,
        license-number: license-number,
        country: country,
        verified: false,
        verification-date: u0,
        verifier: tx-sender
      }
    )
    (map-set airline-by-principal { airline: tx-sender } { airline-id: airline-id })
    (var-set next-airline-id (+ airline-id u1))
    (ok airline-id)
  )
)

;; Verify an airline (only contract owner)
(define-public (verify-airline (airline-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
    (asserts! (is-some (map-get? airlines { airline-id: airline-id })) (err u102))
    (map-set airlines
      { airline-id: airline-id }
      (merge (unwrap-panic (map-get? airlines { airline-id: airline-id }))
        { verified: true, verification-date: block-height, verifier: tx-sender }
      )
    )
    (ok true)
  )
)

;; Get airline information
(define-read-only (get-airline (airline-id uint))
  (map-get? airlines { airline-id: airline-id })
)

;; Check if airline is verified
(define-read-only (is-airline-verified (airline-id uint))
  (match (map-get? airlines { airline-id: airline-id })
    airline (get verified airline)
    false
  )
)
