
;; title: DigitalTherapy
;; version: 1.0.0
;; summary: A synthetic assets smart contract for tracking digital therapeutics and app-based medical treatments
;; description: This contract manages digital therapeutic assets, tracks treatment efficacy, and enables
;;              synthetic asset creation for digital health interventions

;; traits
(define-trait digital-therapy-trait
  (
    ;; Get therapy information
    (get-therapy-info (uint) (response (tuple (name (string-ascii 64)) (category (string-ascii 32)) (efficacy-rate uint) (active bool)) uint))
    ;; Update therapy efficacy
    (update-efficacy (uint uint) (response bool uint))
  )
)

;; token definitions
;; SIP-010 compliant fungible token for therapy credits
(define-fungible-token therapy-credits)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PARAMS (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_THERAPY_INACTIVE (err u105))

;; Maximum values for validation
(define-constant MAX_EFFICACY_RATE u10000) ;; 100.00% = 10000 basis points
(define-constant MIN_EFFICACY_RATE u0)
(define-constant MAX_NAME_LENGTH u64)
(define-constant MAX_CATEGORY_LENGTH u32)

;; data vars
(define-data-var next-therapy-id uint u1)
(define-data-var total-therapies uint u0)
(define-data-var contract-active bool true)

;; data maps
;; Digital therapy registry
(define-map digital-therapies
  { therapy-id: uint }
  {
    name: (string-ascii 64),
    category: (string-ascii 32),
    creator: principal,
    efficacy-rate: uint, ;; in basis points (10000 = 100%)
    total-treatments: uint,
    successful-treatments: uint,
    created-at: uint,
    active: bool
  }
)

;; Treatment records
(define-map treatment-records
  { patient: principal, therapy-id: uint, treatment-id: uint }
  {
    start-date: uint,
    end-date: (optional uint),
    status: (string-ascii 16), ;; "active", "completed", "abandoned"
    outcome: (optional bool), ;; true = successful, false = unsuccessful
    notes: (optional (string-ascii 256))
  }
)

;; Patient treatment counters
(define-map patient-treatment-counter
  { patient: principal }
  { next-treatment-id: uint }
)

;; Synthetic asset positions
(define-map synthetic-positions
  { holder: principal, therapy-id: uint }
  {
    position-size: uint,
    entry-efficacy: uint,
    created-at: uint
  }
)

;; Therapy creators (authorized to create therapies)
(define-map authorized-creators
  { creator: principal }
  { authorized: bool }
)

;; public functions

;; Initialize contract - only owner can call
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    ;; Authorize the contract owner as a creator
    (map-set authorized-creators { creator: CONTRACT_OWNER } { authorized: true })
    ;; Mint initial therapy credits to owner
    (try! (ft-mint? therapy-credits u1000000 CONTRACT_OWNER))
    (ok true)
  )
)

;; Authorize a new therapy creator
(define-public (authorize-creator (creator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-creators { creator: creator } { authorized: true })
    (ok true)
  )
)

;; Create a new digital therapy
(define-public (create-therapy (name (string-ascii 64)) (category (string-ascii 32)) (initial-efficacy uint))
  (let (
    (therapy-id (var-get next-therapy-id))
    (creator-authorized (default-to false (get authorized (map-get? authorized-creators { creator: tx-sender }))))
  )
    (asserts! creator-authorized ERR_UNAUTHORIZED)
    (asserts! (and (> (len name) u0) (<= (len name) MAX_NAME_LENGTH)) ERR_INVALID_PARAMS)
    (asserts! (and (> (len category) u0) (<= (len category) MAX_CATEGORY_LENGTH)) ERR_INVALID_PARAMS)
    (asserts! (and (>= initial-efficacy MIN_EFFICACY_RATE) (<= initial-efficacy MAX_EFFICACY_RATE)) ERR_INVALID_PARAMS)
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    ;; Therapy ID is auto-incremented, so no need to check for duplicates

    ;; Create the therapy
    (map-set digital-therapies
      { therapy-id: therapy-id }
      {
        name: name,
        category: category,
        creator: tx-sender,
        efficacy-rate: initial-efficacy,
        total-treatments: u0,
        successful-treatments: u0,
        created-at: block-height,
        active: true
      }
    )

    ;; Update counters
    (var-set next-therapy-id (+ therapy-id u1))
    (var-set total-therapies (+ (var-get total-therapies) u1))

    ;; Mint therapy credits to creator as reward
    (try! (ft-mint? therapy-credits u1000 tx-sender))

    (ok therapy-id)
  )
)

;; Start a treatment for a patient
(define-public (start-treatment (therapy-id uint))
  (let (
    (therapy (unwrap! (map-get? digital-therapies { therapy-id: therapy-id }) ERR_NOT_FOUND))
    (patient tx-sender)
    (treatment-counter (default-to { next-treatment-id: u1 } (map-get? patient-treatment-counter { patient: patient })))
    (treatment-id (get next-treatment-id treatment-counter))
  )
    (asserts! (get active therapy) ERR_THERAPY_INACTIVE)
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    ;; Record the treatment
    (map-set treatment-records
      { patient: patient, therapy-id: therapy-id, treatment-id: treatment-id }
      {
        start-date: block-height,
        end-date: none,
        status: "active",
        outcome: none,
        notes: none
      }
    )

    ;; Update patient treatment counter
    (map-set patient-treatment-counter
      { patient: patient }
      { next-treatment-id: (+ treatment-id u1) }
    )

    ;; Update therapy total treatments
    (map-set digital-therapies
      { therapy-id: therapy-id }
      (merge therapy { total-treatments: (+ (get total-treatments therapy) u1) })
    )

    (ok treatment-id)
  )
)

;; Complete a treatment with outcome
(define-public (complete-treatment (therapy-id uint) (treatment-id uint) (successful bool) (notes (optional (string-ascii 256))))
  (let (
    (patient tx-sender)
    (treatment-key { patient: patient, therapy-id: therapy-id, treatment-id: treatment-id })
    (treatment (unwrap! (map-get? treatment-records treatment-key) ERR_NOT_FOUND))
    (therapy (unwrap! (map-get? digital-therapies { therapy-id: therapy-id }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq (get status treatment) "active") ERR_INVALID_PARAMS)
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    ;; Update treatment record
    (map-set treatment-records
      treatment-key
      (merge treatment {
        end-date: (some block-height),
        status: "completed",
        outcome: (some successful),
        notes: notes
      })
    )

    ;; Update therapy statistics if successful
    (if successful
      (map-set digital-therapies
        { therapy-id: therapy-id }
        (merge therapy {
          successful-treatments: (+ (get successful-treatments therapy) u1),
          efficacy-rate: (calculate-efficacy-rate
            (+ (get successful-treatments therapy) u1)
            (get total-treatments therapy))
        })
      )
      true ;; No therapy update needed for unsuccessful treatment
    )

    ;; Reward patient with therapy credits for completion
    (try! (ft-mint? therapy-credits (if successful u100 u50) patient))

    (ok true)
  )
)

;; Create synthetic position based on therapy efficacy
(define-public (create-synthetic-position (therapy-id uint) (position-size uint))
  (let (
    (therapy (unwrap! (map-get? digital-therapies { therapy-id: therapy-id }) ERR_NOT_FOUND))
    (holder tx-sender)
    (current-efficacy (get efficacy-rate therapy))
    (cost (* position-size u10)) ;; 10 credits per unit position
  )
    (asserts! (get active therapy) ERR_THERAPY_INACTIVE)
    (asserts! (> position-size u0) ERR_INVALID_PARAMS)
    (asserts! (>= (ft-get-balance therapy-credits holder) cost) ERR_INSUFFICIENT_BALANCE)
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    ;; Burn therapy credits as collateral
    (try! (ft-burn? therapy-credits cost holder))

    ;; Create or update synthetic position
    (match (map-get? synthetic-positions { holder: holder, therapy-id: therapy-id })
      existing-position
        ;; Update existing position
        (map-set synthetic-positions
          { holder: holder, therapy-id: therapy-id }
          (merge existing-position {
            position-size: (+ (get position-size existing-position) position-size)
          })
        )
      ;; Create new position
      (map-set synthetic-positions
        { holder: holder, therapy-id: therapy-id }
        {
          position-size: position-size,
          entry-efficacy: current-efficacy,
          created-at: block-height
        }
      )
    )

    (ok true)
  )
)

;; Close synthetic position and settle based on efficacy change
(define-public (close-synthetic-position (therapy-id uint))
  (let (
    (holder tx-sender)
    (position (unwrap! (map-get? synthetic-positions { holder: holder, therapy-id: therapy-id }) ERR_NOT_FOUND))
    (therapy (unwrap! (map-get? digital-therapies { therapy-id: therapy-id }) ERR_NOT_FOUND))
    (entry-efficacy (get entry-efficacy position))
    (current-efficacy (get efficacy-rate therapy))
    (position-size (get position-size position))
    (efficacy-change (if (> current-efficacy entry-efficacy)
                        (- current-efficacy entry-efficacy)
                        (- entry-efficacy current-efficacy)))
    (payout (+ (* position-size u10) ;; Return collateral
               (/ (* position-size efficacy-change) u100))) ;; Plus/minus efficacy change
  )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    ;; Remove position
    (map-delete synthetic-positions { holder: holder, therapy-id: therapy-id })

    ;; Mint payout to holder
    (try! (ft-mint? therapy-credits payout holder))

    (ok payout)
  )
)

;; read only functions

;; Get therapy information
(define-read-only (get-therapy (therapy-id uint))
  (map-get? digital-therapies { therapy-id: therapy-id })
)

;; Get treatment record
(define-read-only (get-treatment (patient principal) (therapy-id uint) (treatment-id uint))
  (map-get? treatment-records { patient: patient, therapy-id: therapy-id, treatment-id: treatment-id })
)

;; Get synthetic position
(define-read-only (get-synthetic-position (holder principal) (therapy-id uint))
  (map-get? synthetic-positions { holder: holder, therapy-id: therapy-id })
)

;; Get therapy credits balance
(define-read-only (get-therapy-credits-balance (account principal))
  (ft-get-balance therapy-credits account)
)

;; Get contract stats
(define-read-only (get-contract-stats)
  {
    total-therapies: (var-get total-therapies),
    next-therapy-id: (var-get next-therapy-id),
    contract-active: (var-get contract-active)
  }
)

;; Check if creator is authorized
(define-read-only (is-authorized-creator (creator principal))
  (default-to false (get authorized (map-get? authorized-creators { creator: creator })))
)

;; Get therapy efficacy rate
(define-read-only (get-therapy-efficacy (therapy-id uint))
  (match (map-get? digital-therapies { therapy-id: therapy-id })
    therapy (some (get efficacy-rate therapy))
    none
  )
)

;; private functions

;; Calculate efficacy rate based on successful vs total treatments
(define-private (calculate-efficacy-rate (successful uint) (total uint))
  (if (is-eq total u0)
    u0
    (/ (* successful u10000) total) ;; Return in basis points
  )
)

;; Validate string length
(define-private (is-valid-string-length (str (string-ascii 256)) (max-length uint))
  (and (> (len str) u0) (<= (len str) max-length))
)
