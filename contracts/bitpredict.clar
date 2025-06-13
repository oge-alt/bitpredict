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

;; PUBLIC FUNCTIONS - MARKET MANAGEMENT

;; Creates a new prediction market with enhanced validation
(define-public (create-market 
    (asset-name (string-ascii 32))
    (start-price uint) 
    (start-block uint) 
    (end-block uint))
    (let
        (
            (market-id (var-get market-counter))
            (current-block stacks-block-height)
        )
        ;; Authorization & validation checks
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
        (asserts! (not (var-get protocol-paused)) ERR_UNAUTHORIZED)
        (asserts! (> end-block start-block) ERR_INVALID_TIMEFRAME)
        (asserts! (>= (- end-block start-block) MINIMUM_MARKET_DURATION) ERR_INVALID_TIMEFRAME)
        (asserts! (>= start-block current-block) ERR_INVALID_TIMEFRAME)
        (asserts! (> start-price u0) ERR_INVALID_PRICE)
        (asserts! (> (len asset-name) u0) ERR_INVALID_PARAMETER)
        
        ;; Create market
        (map-set markets market-id
            {
                creator: tx-sender,
                asset-name: asset-name,
                start-price: start-price,
                end-price: u0,
                total-up-stake: u0,
                total-down-stake: u0,
                start-block: start-block,
                end-block: end-block,
                resolution-block: u0,
                resolved: false,
                total-participants: u0
            }
        )
        
        ;; Update counter
        (var-set market-counter (+ market-id u1))
        (ok market-id)
    )
)

;; Enhanced prediction function with better validation and tracking
(define-public (make-prediction 
    (market-id uint) 
    (prediction (string-ascii 4)) 
    (stake uint))
    (let
        (
            (market (unwrap! (map-get? markets market-id) ERR_MARKET_NOT_FOUND))
            (current-block stacks-block-height)
            (existing-prediction (map-get? user-predictions {market-id: market-id, user: tx-sender}))
        )
        ;; Validation checks
        (asserts! (not (var-get protocol-paused)) ERR_UNAUTHORIZED)
        (asserts! (and (>= current-block (get start-block market)) 
                      (< current-block (get end-block market))) 
                 ERR_MARKET_CLOSED)
        (asserts! (or (is-eq prediction PREDICTION_UP) (is-eq prediction PREDICTION_DOWN)) 
                 ERR_INVALID_PREDICTION)
        (asserts! (>= stake (var-get minimum-stake)) 
                 ERR_INSUFFICIENT_STAKE)
        (asserts! (>= (stx-get-balance tx-sender) stake) 
                 ERR_INSUFFICIENT_BALANCE)
        (asserts! (not (get resolved market)) ERR_MARKET_CLOSED)

        ;; Handle existing predictions (update stake)
        (let
            (
                (final-stake (if (is-some existing-prediction)
                               (+ stake (get stake (unwrap-panic existing-prediction)))
                               stake))
                (is-new-participant (is-none existing-prediction))
            )
            
            ;; Transfer stake to contract
            (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
            
            ;; Update prediction record
            (map-set user-predictions 
                {market-id: market-id, user: tx-sender}
                {
                    prediction: prediction, 
                    stake: final-stake, 
                    claimed: false,
                    timestamp: current-block
                }
            )
            
            ;; Update market totals
            (map-set markets market-id
                (merge market
                    {
                        total-up-stake: (if (is-eq prediction PREDICTION_UP)
                                        (+ (get total-up-stake market) stake)
                                        (get total-up-stake market)),
                        total-down-stake: (if (is-eq prediction PREDICTION_DOWN)
                                          (+ (get total-down-stake market) stake)
                                          (get total-down-stake market)),
                        total-participants: (if is-new-participant
                                           (+ (get total-participants market) u1)
                                           (get total-participants market))
                    }
                )
            )
            
            ;; Update global volume
            (var-set total-volume (+ (var-get total-volume) stake))
            
            (ok {market-id: market-id, total-stake: final-stake})
        )
    )
)