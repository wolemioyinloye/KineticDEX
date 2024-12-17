;; KineticDEX - Decentralized Exchange Smart Contract
;; Implements token swapping and liquidity pool functionality

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-balance (err u101))
(define-constant err-pool-not-found (err u102))

;; Data Variables
(define-data-var protocol-fee-rate uint u30) ;; 0.3% fee
(define-map liquidity-pools
  { pool-id: uint }
  {
    token-x: principal,
    token-y: principal,
    reserve-x: uint,
    reserve-y: uint,
    total-shares: uint
  }
)

(define-map pool-shares
  { pool-id: uint, owner: principal }
  { shares: uint }
)

;; Public Functions
(define-public (create-pool (token-x principal) (token-y principal) (amount-x uint) (amount-y uint))
  (let
    (
      (pool-id (get-next-pool-id))
    )
    (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender)))
    (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender)))
    
    (map-set liquidity-pools
      { pool-id: pool-id }
      {
        token-x: token-x,
        token-y: token-y,
        reserve-x: amount-x,
        reserve-y: amount-y,
        total-shares: amount-x
      }
    )
    
    (map-set pool-shares
      { pool-id: pool-id, owner: tx-sender }
      { shares: amount-x }
    )
    
    (ok pool-id)
  )
)

(define-public (swap-exact-tokens (pool-id uint) (token-in principal) (amount-in uint) (min-amount-out uint))
  (let
    (
      (pool (unwrap! (get-pool pool-id) err-pool-not-found))
      (reserve-in (get-reserve-in pool token-in))
      (reserve-out (get-reserve-out pool token-in))
      (amount-out (get-amount-out amount-in reserve-in reserve-out))
    )
    
    (asserts! (>= amount-out min-amount-out) err-not-enough-balance)
    (try! (contract-call? token-in transfer amount-in tx-sender (as-contract tx-sender)))
    
    (ok amount-out)
  )
)

;; Private Functions
(define-private (get-next-pool-id)
  (default-to u0 (get-last-pool-id))
)

(define-private (get-pool (pool-id uint))
  (map-get? liquidity-pools { pool-id: pool-id })
)

(define-private (get-reserve-in (pool { token-x: principal, token-y: principal, reserve-x: uint, reserve-y: uint, total-shares: uint }) (token-in principal))
  (if (is-eq token-in (get token-x pool))
    (get reserve-x pool)
    (get reserve-y pool)
  )
)

(define-private (get-reserve-out (pool { token-x: principal, token-y: principal, reserve-x: uint, reserve-y: uint, total-shares: uint }) (token-in principal))
  (if (is-eq token-in (get token-x pool))
    (get reserve-y pool)
    (get reserve-x pool)
  )
)

(define-private (get-amount-out (amount-in uint) (reserve-in uint) (reserve-out uint))
  (let
    (
      (amount-in-with-fee (mul amount-in u997))
      (numerator (mul amount-in-with-fee reserve-out))
      (denominator (add (mul reserve-in u1000) amount-in-with-fee))
    )
    (/ numerator denominator)
  )
)