;; Simple Lending and Borrowing Contract
;; Features:
;; - Users can deposit tokens to lend
;; - Users can borrow tokens against collateral
;; - Tracks lending and borrowing balances
;; - Calculates interest

(define-fungible-token lend-token)

;; Storage for contract data
(define-map lending-deposits 
  {user: principal} 
  {amount: uint, interest-rate: uint}
)

(define-map borrowing-positions
  {user: principal}
  {borrowed-amount: uint, collateral-amount: uint, interest-rate: uint}
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-collateral-ratio u150) ;; 150% collateralization required
(define-constant base-interest-rate u5) ;; 5% base interest rate
(define-constant max-loan-to-value u70) ;; 70% maximum loan-to-value ratio

;; Errors
(define-constant err-insufficient-balance (err u1))
(define-constant err-insufficient-collateral (err u2))
(define-constant err-over-borrowed (err u3))
(define-constant err-unauthorized (err u4))

;; Deposit tokens to lending pool
(define-public (deposit (amount uint))
  (begin
    ;; Transfer tokens to contract
    (try! (ft-transfer? lend-token amount tx-sender (as-contract tx-sender)))
    
    ;; Update lending deposits
    (map-set lending-deposits 
      {user: tx-sender} 
      {amount: amount, interest-rate: base-interest-rate}
    )
    
    (ok true)
  )
)

;; Withdraw tokens from lending pool
(define-public (withdraw (amount uint))
  (let 
    ((user-deposit (unwrap! (map-get? lending-deposits {user: tx-sender}) err-insufficient-balance))
     (current-deposit (get amount user-deposit)))
    
    ;; Check if enough balance
    (asserts! (>= current-deposit amount) err-insufficient-balance)
    
    ;; Transfer tokens back to user
    (try! (as-contract (ft-transfer? lend-token amount (as-contract tx-sender) tx-sender)))
    
    ;; Update lending deposits
    (map-set lending-deposits 
      {user: tx-sender} 
      {amount: (- current-deposit amount), interest-rate: base-interest-rate}
    )
    
    (ok true)
  )
)

;; Repay borrowed tokens
(define-public (repay (amount uint))
  (let 
    ((borrow-position (unwrap! (map-get? borrowing-positions {user: tx-sender}) err-unauthorized))
     (current-borrowed (get borrowed-amount borrow-position))
     (current-collateral (get collateral-amount borrow-position))
    )
    
    ;; Validate repayment amount
    (asserts! (<= amount current-borrowed) err-over-borrowed)
    
    ;; Transfer repayment back to contract
    (try! (ft-transfer? lend-token amount tx-sender (as-contract tx-sender)))
    
    ;; Update or clear borrowing position
    (if (is-eq amount current-borrowed)
      ;; If fully repaid, return collateral and remove position
      (begin
        (try! (as-contract (ft-transfer? lend-token current-collateral (as-contract tx-sender) tx-sender)))
        (map-delete borrowing-positions {user: tx-sender})
      )
      ;; Otherwise update remaining borrowed amount
      (map-set borrowing-positions 
        {user: tx-sender}
        {
          borrowed-amount: (- current-borrowed amount), 
          collateral-amount: current-collateral, 
          interest-rate: base-interest-rate
        }
      )
    )
    
    (ok true)
  )
)

;; View functions to check positions
(define-read-only (get-deposit-balance (user principal))
  (map-get? lending-deposits {user: user})
)

(define-read-only (get-borrow-position (user principal))
  (map-get? borrowing-positions {user: user})
)