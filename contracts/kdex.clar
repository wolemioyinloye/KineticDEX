;; KineticDEX Lending Contract with Dynamic Interest Calculations

(define-fungible-token lend-token)

;; Storage for contract data with enhanced interest tracking
(define-map lending-deposits 
  {user: principal} 
  {
    amount: uint, 
    interest-rate: uint, 
    last-updated-block: uint,
    total-accumulated-interest: uint
  }
)

(define-map borrowing-positions
  {user: principal}
  {
    borrowed-amount: uint, 
    collateral-amount: uint, 
    interest-rate: uint,
    last-updated-block: uint,
    total-accrued-interest: uint
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-collateral-ratio u150) ;; 150% collateralization required
(define-constant base-interest-rate u5) ;; 5% base annual interest rate
(define-constant max-loan-to-value u70) ;; 70% maximum loan-to-value ratio
(define-constant blocks-per-year u525600) ;; Approximate blocks per year

;; Errors
(define-constant err-insufficient-balance (err u1))
(define-constant err-insufficient-collateral (err u2))
(define-constant err-over-borrowed (err u3))
(define-constant err-unauthorized (err u4))
(define-constant err-interest-calculation (err u5))

;; Calculate Dynamic Interest
(define-private (calculate-interest 
  (principal uint) 
  (interest-rate uint) 
  (last-updated-block uint)
)
  (let 
    (
      ;; Calculate blocks elapsed since last update
      (blocks-elapsed (- block-height last-updated-block))
      
      ;; Calculate interest proportional to time passed
      ;; Annual rate divided by blocks per year, multiplied by blocks elapsed
      (interest-amount 
        (/ 
          (* principal interest-rate blocks-elapsed) 
          (* blocks-per-year u100)
        )
      )
    )
    
    ;; Return calculated interest
    interest-amount
  )
)

;; Update Lending Position with Accrued Interest
(define-public (update-lending-position (user principal))
  (let 
    ((current-deposit (unwrap! (map-get? lending-deposits {user: user}) err-insufficient-balance))
     (current-amount (get amount current-deposit))
     (current-interest-rate (get interest-rate current-deposit))
     (last-updated-block (get last-updated-block current-deposit))
     
     ;; Calculate new interest
     (accrued-interest 
       (calculate-interest 
         current-amount 
         current-interest-rate 
         last-updated-block
       )
     )
    )
    
    ;; Update deposit with new interest and current block
    (map-set lending-deposits 
      {user: user}
      {
        amount: (+ current-amount accrued-interest),
        interest-rate: current-interest-rate,
        last-updated-block: block-height,
        total-accumulated-interest: 
          (+ 
            (get total-accumulated-interest current-deposit) 
            accrued-interest
          )
      }
    )
    
    (ok true)
  )
)

;; Update Borrowing Position with Accrued Interest
(define-public (update-borrowing-position (user principal))
  (let 
    ((current-position (unwrap! (map-get? borrowing-positions {user: user}) err-unauthorized))
     (current-borrowed (get borrowed-amount current-position))
     (current-interest-rate (get interest-rate current-position))
     (last-updated-block (get last-updated-block current-position))
     
     ;; Calculate new interest
     (accrued-interest 
       (calculate-interest 
         current-borrowed 
         current-interest-rate 
         last-updated-block
       )
     )
    )
    
    ;; Update borrowing position with new interest
    (map-set borrowing-positions 
      {user: user}
      {
        borrowed-amount: (+ current-borrowed accrued-interest),
        collateral-amount: (get collateral-amount current-position),
        interest-rate: current-interest-rate,
        last-updated-block: block-height,
        total-accrued-interest: 
          (+ 
            (get total-accrued-interest current-position) 
            accrued-interest
          )
      }
    )
    
    (ok true)
  )
)

;; Existing deposit function - now updates interest before deposit
(define-public (deposit (amount uint))
  (begin
    ;; Update any existing position first
    (try! (update-lending-position tx-sender))
    
    ;; Transfer tokens to contract
    (try! (ft-transfer? lend-token amount tx-sender (as-contract tx-sender)))
    
    ;; Update lending deposits with current block
    (map-set lending-deposits 
      {user: tx-sender} 
      {
        amount: amount, 
        interest-rate: base-interest-rate,
        last-updated-block: block-height,
        total-accumulated-interest: u0
      }
    )
    
    (ok true)
  )
)

