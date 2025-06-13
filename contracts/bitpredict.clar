;; BitPredict - Decentralized Price Prediction Market
;;
;; Title: BitPredict Protocol
;;
;; Summary: A trustless prediction market protocol built on Stacks, enabling users
;; to stake STX tokens on price movements and earn rewards for accurate predictions.
;;
;; Description: BitPredict leverages Stacks' secure smart contract capabilities to
;; create transparent, automated prediction markets. Users can participate in
;; time-bounded prediction rounds by staking STX on whether asset prices will
;; move up or down. Winners share the total prize pool proportionally to their
;; stake, while the protocol collects a small fee for sustainability.
;;
;; Features:
;; - Permissionless market creation with customizable parameters
;; - Oracle-based price resolution for transparency
;; - Proportional reward distribution based on stake weight
;; - Built-in fee mechanism for protocol sustainability
;; - Comprehensive admin controls for decentralized governance

;; CONSTANTS & ERROR CODES

;; Administrative Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant PROTOCOL_NAME "BitPredict")

;; Error Codes - Administrative
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_OWNER_ONLY (err u101))

;; Error Codes - Market Operations
(define-constant ERR_MARKET_NOT_FOUND (err u200))
(define-constant ERR_INVALID_PREDICTION (err u201))
(define-constant ERR_MARKET_CLOSED (err u202))
(define-constant ERR_MARKET_NOT_RESOLVED (err u203))
(define-constant ERR_ALREADY_CLAIMED (err u204))
(define-constant ERR_ALREADY_RESOLVED (err u205))

;; Error Codes - Financial
(define-constant ERR_INSUFFICIENT_BALANCE (err u300))
(define-constant ERR_INSUFFICIENT_STAKE (err u301))
(define-constant ERR_TRANSFER_FAILED (err u302))

;; Error Codes - Validation
(define-constant ERR_INVALID_PARAMETER (err u400))
(define-constant ERR_INVALID_TIMEFRAME (err u401))
(define-constant ERR_INVALID_PRICE (err u402))

;; Business Logic Constants
(define-constant PREDICTION_UP "up")
(define-constant PREDICTION_DOWN "down")
(define-constant MAX_FEE_PERCENTAGE u10) ;; Maximum 10% fee cap
(define-constant MINIMUM_MARKET_DURATION u144) ;; ~24 hours in blocks

;; STATE VARIABLES

;; Platform Configuration
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum stake
(define-data-var platform-fee-percentage uint u2) ;; 2% platform fee
(define-data-var market-counter uint u0)
(define-data-var protocol-paused bool false)

;; Statistics Tracking
(define-data-var total-volume uint u0)
(define-data-var total-fees-collected uint u0)

;; DATA STRUCTURES

;; Enhanced Market Structure
(define-map markets
    uint
    {
        creator: principal,
        asset-name: (string-ascii 32),
        start-price: uint,
        end-price: uint,
        total-up-stake: uint,
        total-down-stake: uint,
        start-block: uint,
        end-block: uint,
        resolution-block: uint,
        resolved: bool,
        total-participants: uint
    }
)

;; Enhanced User Prediction Structure
(define-map user-predictions
    {market-id: uint, user: principal}
    {
        prediction: (string-ascii 4),
        stake: uint,
        claimed: bool,
        timestamp: uint
    }
)

;; User Statistics
(define-map user-stats
    principal
    {
        total-predictions: uint,
        total-winnings: uint,
        total-losses: uint
    }
)