;; VirtualSphere Community Platform Smart Contract
;; This contract handles digital identity management within a virtual community
;; Created for distributed membership administration and profile interactions

;; ======================================================
;; DATABASE STRUCTURE AND PERSISTENCE LAYER
;; ======================================================

;; Core participant record repository
(define-map participant-registry
  { participant-uid: uint }
  {
    display-handle: (string-ascii 50),
    blockchain-identity: principal,
    enrollment-timestamp: uint,
    personal-description: (string-ascii 160),
    interest-tags: (list 5 (string-ascii 30))
  }
)

;; Participant authentication and visibility settings
(define-map participant-visibility-settings
  { participant-uid: uint, observer-identity: principal }
  { access-granted: bool }
)

;; Participant engagement metrics storage
(define-map participant-engagement-metrics
  { participant-uid: uint }
  {
    recent-session: uint,
    session-count: uint,
    recent-interaction: (string-ascii 50)
  }
)

;; ======================================================
;; GLOBAL STATE VARIABLES
;; ======================================================

;; Total participant counter - increments with each new registration
(define-data-var participant-counter uint u0)

;; ======================================================
;; SYSTEM CONSTANTS AND ERROR CODES
;; ======================================================

;; Response Codes (Error Handling System)
(define-constant ERROR-AUTHORIZATION-FAILED (err u500))
(define-constant ERROR-RECORD-NOT-FOUND (err u501))
(define-constant ERROR-DUPLICATE-RECORD (err u502))
(define-constant ERROR-VALIDATION-FAILED (err u503))
(define-constant ERROR-ACCESS-DENIED (err u504))

;; System Authority Settings
(define-constant PLATFORM-ADMINISTRATOR tx-sender)

;; ======================================================
;; UTILITY AND VALIDATION FUNCTIONS
;; ======================================================

;; Verify participant record existence
(define-private (participant-record-exists? (participant-uid uint))
  (is-some (map-get? participant-registry { participant-uid: participant-uid }))
)

;; Validate participant ownership credentials
(define-private (is-authorized-participant? (participant-uid uint) (identity principal))
  (match (map-get? participant-registry { participant-uid: participant-uid })
    profile-data (is-eq (get blockchain-identity profile-data) identity)
    false
  )
)

;; Single tag validation routine
(define-private (is-tag-format-valid? (tag (string-ascii 30)))
  (and
    (> (len tag) u0)
    (< (len tag) u31)
  )
)

;; Complete interest tags validation routine
(define-private (are-interest-tags-valid? (interest-tags (list 5 (string-ascii 30))))
  (and
    (> (len interest-tags) u0)
    (<= (len interest-tags) u5)
    (is-eq (len (filter is-tag-format-valid? interest-tags)) (len interest-tags))
  )
)

;; ======================================================
;; PUBLIC INTERFACE FUNCTIONS
;; ======================================================

;; Create new participant profile
(define-public (enroll-new-participant 
    (display-handle (string-ascii 50)) 
    (personal-description (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (new-uid (+ (var-get participant-counter) u1))
    )
    ;; Input validation process
    (asserts! (and (> (len display-handle) u0) (< (len display-handle) u51)) ERROR-VALIDATION-FAILED)
    (asserts! (and (> (len personal-description) u0) (< (len personal-description) u161)) ERROR-VALIDATION-FAILED)
    (asserts! (are-interest-tags-valid? interest-tags) ERROR-VALIDATION-FAILED)

    ;; Create participant record
    (map-insert participant-registry
      { participant-uid: new-uid }
      {
        display-handle: display-handle,
        blockchain-identity: tx-sender,
        enrollment-timestamp: block-height,
        personal-description: personal-description,
        interest-tags: interest-tags
      }
    )

    ;; Initialize default privacy configuration
    (map-insert participant-visibility-settings
      { participant-uid: new-uid, observer-identity: tx-sender }
      { access-granted: true }
    )

    ;; Update system record count
    (var-set participant-counter new-uid)
    (ok new-uid)
  )
)

;; Alternative enrollment function (maintains compatibility with legacy systems)
(define-public (register-platform-participant 
    (display-handle (string-ascii 50)) 
    (personal-description (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (new-uid (+ (var-get participant-counter) u1))
    )
    ;; Input validation process
    (asserts! (and (> (len display-handle) u0) (< (len display-handle) u51)) ERROR-VALIDATION-FAILED)
    (asserts! (and (> (len personal-description) u0) (< (len personal-description) u161)) ERROR-VALIDATION-FAILED)
    (asserts! (are-interest-tags-valid? interest-tags) ERROR-VALIDATION-FAILED)

    ;; Create participant record
    (map-insert participant-registry
      { participant-uid: new-uid }
      {
        display-handle: display-handle,
        blockchain-identity: tx-sender,
        enrollment-timestamp: block-height,
        personal-description: personal-description,
        interest-tags: interest-tags
      }
    )

    ;; Initialize default privacy configuration
    (map-insert participant-visibility-settings
      { participant-uid: new-uid, observer-identity: tx-sender }
      { access-granted: true }
    )

    ;; Update system record count
    (var-set participant-counter new-uid)
    (ok new-uid)
  )
)

;; Update participant interest tags
(define-public (modify-participant-interests (participant-uid uint) (updated-interests (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND))
    )
    ;; Security and validation checks
    (asserts! (participant-record-exists? participant-uid) ERROR-RECORD-NOT-FOUND)
    (asserts! (is-eq (get blockchain-identity profile-data) tx-sender) ERROR-ACCESS-DENIED)
    (asserts! (are-interest-tags-valid? updated-interests) ERROR-VALIDATION-FAILED)

    ;; Update participant interests
    (map-set participant-registry
      { participant-uid: participant-uid }
      (merge profile-data { interest-tags: updated-interests })
    )
    (ok true)
  )
)

;; Update participant display handle
(define-public (update-display-handle (participant-uid uint) (new-handle (string-ascii 50)))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND))
    )
    ;; Security and validation checks
    (asserts! (participant-record-exists? participant-uid) ERROR-RECORD-NOT-FOUND)
    (asserts! (is-eq (get blockchain-identity profile-data) tx-sender) ERROR-ACCESS-DENIED)

    ;; Update participant display handle
    (map-set participant-registry
      { participant-uid: participant-uid }
      (merge profile-data { display-handle: new-handle })
    )
    (ok true)
  )
)

;; Enhanced interests modification with simplified implementation
(define-public (quick-update-interests (participant-uid uint) (updated-interests (list 5 (string-ascii 30))))
  (begin
    (asserts! (participant-record-exists? participant-uid) ERROR-RECORD-NOT-FOUND)
    (asserts! (are-interest-tags-valid? updated-interests) ERROR-VALIDATION-FAILED)
    (map-set participant-registry
      { participant-uid: participant-uid }
      (merge (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND) 
             { interest-tags: updated-interests })
    )
    (ok "Interests successfully updated")
  )
)

;; Participant access control validation
(define-public (validate-participant-access (participant-uid uint) (identity principal))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND))
    )
    ;; Verify identity authorization
    (asserts! (is-eq (get blockchain-identity profile-data) identity) ERROR-ACCESS-DENIED)
    (ok true)
  )
)

;; Comprehensive participant profile update function
(define-public (complete-profile-update (participant-uid uint) 
                                      (new-handle (string-ascii 50)) 
                                      (new-description (string-ascii 160)) 
                                      (new-interests (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND))
    )
    ;; Extensive validation process
    (asserts! (participant-record-exists? participant-uid) ERROR-RECORD-NOT-FOUND)
    (asserts! (is-eq (get blockchain-identity profile-data) tx-sender) ERROR-ACCESS-DENIED)
    (asserts! (> (len new-handle) u0) ERROR-VALIDATION-FAILED)
    (asserts! (< (len new-handle) u51) ERROR-VALIDATION-FAILED)
    (asserts! (are-interest-tags-valid? new-interests) ERROR-VALIDATION-FAILED)

    ;; Comprehensive profile update
    (map-set participant-registry
      { participant-uid: participant-uid }
      (merge profile-data { 
        display-handle: new-handle, 
        personal-description: new-description, 
        interest-tags: new-interests 
      })
    )
    (ok true)
  )
)

;; Ownership verification function for external system integration
(define-public (authenticate-participant-ownership (participant-uid uint) (claimed-identity principal))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-uid: participant-uid }) ERROR-RECORD-NOT-FOUND))
    )
    (ok (is-eq claimed-identity (get blockchain-identity profile-data)))
  )
)

;; Record participant platform engagement
(define-public (log-participant-activity (participant-uid uint))
  (let
    (
      (current-metrics (default-to 
        { recent-session: u0, session-count: u0, recent-interaction: "None" }
        (map-get? participant-engagement-metrics { participant-uid: participant-uid })))
    )
    (asserts! (participant-record-exists? participant-uid) ERROR-RECORD-NOT-FOUND)
    (map-set participant-engagement-metrics
      { participant-uid: participant-uid }
      {
        recent-session: block-height,
        session-count: (+ (get session-count current-metrics) u1),
        recent-interaction: "platform_access"
      }
    )
    (ok true)
  )
)

