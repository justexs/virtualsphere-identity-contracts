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
