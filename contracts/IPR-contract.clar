;; Intellectual Property Registry
;; A system for registering and licensing intellectual property

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ASSET-NOT-FOUND u2)
(define-constant ERR-LICENSE-NOT-FOUND u3)
(define-constant ERR-COLLABORATION-NOT-FOUND u4)
(define-constant ERR-TRANSFER-NOT-FOUND u5)
(define-constant ERR-ASSET-ALREADY-EXISTS u6)
(define-constant ERR-INVALID-PARAMETERS u7)
(define-constant ERR-ALREADY-LICENSED u8)
(define-constant ERR-LICENSE-EXPIRED u9)
(define-constant ERR-INSUFFICIENT-FUNDS u10)
(define-constant ERR-INVALID-LICENSE-TERMS u11)
(define-constant ERR-ALREADY-COLLABORATOR u12)
(define-constant ERR-NOT-COLLABORATOR u13)
(define-constant ERR-ROYALTY-EXCEEDS-MAX u14)
(define-constant ERR-INVALID-TRANSFER u15)
(define-constant ERR-LICENSE-ACTIVE u16)
(define-constant ERR-LICENSE-NOT-ACTIVE u17)
(define-constant ERR-ALREADY-CONFIRMED u18)
(define-constant ERR-DISPUTE-NOT-FOUND u19)
(define-constant ERR-DISPUTE-ALREADY-RESOLVED u20)
(define-constant ERR-NOT-IN-DISPUTE u21)
(define-constant ERR-INHERITANCE-ALREADY-SET u22)
(define-constant ERR-DISPUTE-PENDING u23)

;; Asset types
(define-constant ASSET-TYPE-MUSIC u1)
(define-constant ASSET-TYPE-ARTWORK u2)
(define-constant ASSET-TYPE-LITERATURE u3)
(define-constant ASSET-TYPE-SOFTWARE u4)
(define-constant ASSET-TYPE-PATENT u5)
(define-constant ASSET-TYPE-TRADEMARK u6)
(define-constant ASSET-TYPE-DESIGN u7)
(define-constant ASSET-TYPE-FILM u8)
(define-constant ASSET-TYPE-PHOTOGRAPHY u9)
(define-constant ASSET-TYPE-OTHER u10)

;; License types
(define-constant LICENSE-TYPE-EXCLUSIVE u1)
(define-constant LICENSE-TYPE-NON-EXCLUSIVE u2)
(define-constant LICENSE-TYPE-SINGLE-USE u3)
(define-constant LICENSE-TYPE-COMMERCIAL u4)
(define-constant LICENSE-TYPE-NON-COMMERCIAL u5)
(define-constant LICENSE-TYPE-ACADEMIC u6)
(define-constant LICENSE-TYPE-PERPETUAL u7)
(define-constant LICENSE-TYPE-TIMELIMITED u8)

;; License status
(define-constant LICENSE-STATUS-PENDING u1)
(define-constant LICENSE-STATUS-ACTIVE u2)
(define-constant LICENSE-STATUS-EXPIRED u3)
(define-constant LICENSE-STATUS-TERMINATED u4)
(define-constant LICENSE-STATUS-DISPUTE u5)

;; Transfer status
(define-constant TRANSFER-STATUS-PENDING u1)
(define-constant TRANSFER-STATUS-COMPLETED u2)
(define-constant TRANSFER-STATUS-REJECTED u3)
(define-constant TRANSFER-STATUS-DISPUTED u4)

;; Dispute status
(define-constant DISPUTE-STATUS-OPEN u1)
(define-constant DISPUTE-STATUS-RESOLVED u2)
(define-constant DISPUTE-STATUS-ARBITRATION u3)

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-asset-id uint u1)
(define-data-var next-license-id uint u1)
(define-data-var next-collaboration-id uint u1)
(define-data-var next-transfer-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var platform-fee-percent uint u200) ;; 2% as basis points
(define-data-var max-royalty-percent uint u5000) ;; 50% as basis points

;; IP Asset registration
(define-map ip-assets
  { asset-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 1000),
    asset-type: uint,
    creator-principal: principal,
    creation-date: uint,
    registration-date: uint,
    content-hash: (buff 32), ;; Hash of the actual content
    metadata-url: (string-utf8 256), ;; URL to additional metadata
    license-count: uint,
    is-transferable: bool,
    transfer-history: (list 10 uint),
    current-owner: principal,
    is-collaborative: bool,
    collaboration-id: (optional uint),
    in-dispute: bool,
    dispute-id: (optional uint),
    allowed-license-types: (list 10 uint),
    inheritance-beneficiary: (optional principal)
  }
)

;; Map to track assets by creator
(define-map creator-assets
  { creator: principal, index: uint }
  { asset-id: uint }
)

;; Map to track creator asset count
(define-map creator-asset-count
  { creator: principal }
  { count: uint }
)

;; Collaboration agreements
(define-map collaborations
  { collaboration-id: uint }
  {
    asset-id: uint,
    creation-date: uint,
    last-modified: uint,
    collaborators: (list 10 principal),
    royalty-splits: (list 10 { collaborator: principal, split-percent: uint }),
    decision-threshold: uint, ;; Percentage required for decisions as basis points
    collaboration-terms: (string-utf8 1000),
    agreement-hash: (buff 32),
    administrator: principal,
    is-active: bool
  }
)

;; Licensing agreements
(define-map licenses
  { license-id: uint }
  {
    asset-id: uint,
    licensor: principal,
    licensee: principal,
    license-type: uint,
    license-terms: (string-utf8 1000),
    royalty-percent: uint, ;; Basis points
    upfront-payment: uint,
    start-date: uint,
    end-date: (optional uint),
    territory: (string-utf8 100),
    usage-limits: (optional uint),
    usage-count: uint,
    payment-schedule: (string-utf8 256),
    status: uint,
    creation-date: uint,
    last-modified: uint,
    license-hash: (buff 32),
    is-sublicensable: bool,
    sublicense-parent: (optional uint),
    termination-conditions: (string-utf8 500)
  }
)

;; Map of licenses by asset
(define-map asset-licenses
  { asset-id: uint, index: uint }
  { license-id: uint }
)

;; Map of licenses by licensee
(define-map licensee-licenses
  { licensee: principal, index: uint }
  { license-id: uint }
)

;; Map to track license counts for a licensee
(define-map licensee-license-count
  { licensee: principal }
  { count: uint }
)

;; Royalty payments
(define-map royalty-payments
  { license-id: uint, payment-index: uint }
  {
    amount: uint,
    payment-date: uint,
    payment-period-start: uint,
    payment-period-end: uint,
    paid-by: principal,
    received-by: principal,
    transaction-id: (buff 32)
  }
)

;; Map to track royalty payment counts
(define-map royalty-payment-count
  { license-id: uint }
  { count: uint }
)

;; IP Transfers
(define-map ip-transfers
  { transfer-id: uint }
  {
    asset-id: uint,
    from-principal: principal,
    to-principal: principal,
    transfer-price: uint,
    transfer-date: (optional uint),
    request-date: uint,
    status: uint,
    transfer-terms: (string-utf8 500),
    requires-approval: bool,
    approved-by: (list 10 principal), ;; For collaborative assets
    transfer-hash: (buff 32),
    retains-royalties: bool ;; If the original creator still receives royalties
  }
)

;; Dispute records
(define-map disputes
  { dispute-id: uint }
  {
    asset-id: uint,
    related-license-id: (optional uint),
    related-transfer-id: (optional uint),
    raised-by: principal,
    raised-against: principal,
    dispute-type: (string-utf8 50),
    dispute-description: (string-utf8 1000),
    evidence-hash: (buff 32),
    status: uint,
    creation-date: uint,
    resolution-date: (optional uint),
    resolution-notes: (optional (string-utf8 1000)),
    arbiter: (optional principal)
  }
)

;; Read-only functions

;; Get IP asset details
(define-read-only (get-ip-asset (asset-id uint))
  (map-get? ip-assets { asset-id: asset-id })
)

;; Get collaboration details
(define-read-only (get-collaboration (collaboration-id uint))
  (map-get? collaborations { collaboration-id: collaboration-id })
)

;; Get license details
(define-read-only (get-license (license-id uint))
  (map-get? licenses { license-id: license-id })
)

;; Get transfer details
(define-read-only (get-transfer (transfer-id uint))
  (map-get? ip-transfers { transfer-id: transfer-id })
)

;; Get dispute details
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

;; Check if license is active
(define-read-only (is-license-active (license-id uint))
  (match (get-license license-id)
    license
    (let
      (
        (status (get status license))
        (current-block block-height)
        (license-expired
          (match (get end-date license)
            end-date (>= current-block end-date)
            false
          )
        )
      )
      (and
        (is-eq status LICENSE-STATUS-ACTIVE)
        (not license-expired)
        (or
          (is-none (get usage-limits license))
          (< (get usage-count license) (default-to u0 (get usage-limits license)))
        )
      )
    )
    false
  )
)

;; Check if principal is a collaborator
(define-read-only (is-collaborator (asset-id uint) (user principal))
  (match (get-ip-asset asset-id)
    asset
    (match (get collaboration-id asset)
      collab-id
      (match (get-collaboration collab-id)
        collaboration
        (default-to false (some (is-some (index-of (get collaborators collaboration) user))))
        false
      )
      false
    )
    false
  )
)

;; Calculate royalty distribution for a payment
(define-read-only (calculate-royalty-distribution (license-id uint) (payment-amount uint))
  (match (get-license license-id)
    license
    (let
      (
        (asset-id (get asset-id license))
        (asset (unwrap! (get-ip-asset asset-id) (err "Asset not found")))
      )
      (if (get is-collaborative asset)
        ;; Handle collaborative asset
        (match (get collaboration-id asset)
          collaboration-id
          (match (get-collaboration collaboration-id)
            collaboration
            (ok (get royalty-splits collaboration))
            (err "Collaboration not found")
          )
          (err "Collaboration ID not found")
        )
        ;; Single creator - return 100% to owner
        (ok (list { collaborator: (get current-owner asset), split-percent: u10000 }))
      )
    )
    (err "License not found")
  )
)

;; Public functions

;; Register a new IP asset
(define-public (register-ip-asset
  (title (string-utf8 100))
  (description (string-utf8 1000))
  (asset-type uint)
  (content-hash (buff 32))
  (metadata-url (string-utf8 256))
  (is-transferable bool)
  (allowed-license-types (list 10 uint))
)
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
    
    ;; Check if caller is current owner
    (asserts! (is-eq tx-sender (get current-owner asset)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if already has beneficiary
    (asserts! (is-none (get inheritance-beneficiary asset)) (err ERR-INHERITANCE-ALREADY-SET))
    
    ;; Update asset with beneficiary
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        inheritance-beneficiary: (some beneficiary)
      })
    )
    
    (ok true)
  )
)

;; Update inheritance beneficiary
(define-public (update-inheritance-beneficiary (asset-id uint) (beneficiary principal))
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
    
    ;; Check if caller is current owner
    (asserts! (is-eq tx-sender (get current-owner asset)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update asset with beneficiary
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        inheritance-beneficiary: (some beneficiary)
      })
    )
    
    (ok true)
  )
)

;; Execute inheritance transfer (would typically be triggered by a trusted oracle or authority)
(define-public (execute-inheritance-transfer (asset-id uint))
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (beneficiary (unwrap! (get inheritance-beneficiary asset) (err ERR-INVALID-TRANSFER)))
    )
    
    ;; Only contract owner can execute inheritance transfers
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Create a transfer record
    (let
      (
        (transfer-id (var-get next-transfer-id))
      )
      ;; Record the inheritance transfer
      (map-set ip-transfers
        { transfer-id: transfer-id }
        {
          asset-id: asset-id,
          from-principal: (get current-owner asset),
          to-principal: beneficiary,
          transfer-price: u0,
          transfer-date: (some block-height),
          request-date: block-height,
          status: TRANSFER-STATUS-COMPLETED,
          transfer-terms: "Inheritance transfer",
          requires-approval: false,
          approved-by: (list),
          transfer-hash: (sha256 (concat (unwrap-panic (to-consensus-buff? asset-id)) (unwrap-panic (to-consensus-buff? beneficiary)))),
          retains-royalties: true
        }
      )
      
      ;; Update asset ownership
      (map-set ip-assets
        { asset-id: asset-id }
        (merge asset {
          current-owner: beneficiary,
          transfer-history: (append (get transfer-history asset) transfer-id),
          inheritance-beneficiary: none
        })
      )
      
      ;; Add to new owner's assets
      (let
        (
          (new-owner-count (default-to { count: u0 } (map-get? creator-asset-count { creator: beneficiary })))
        )
        (map-set creator-assets
          { creator: beneficiary, index: (get count new-owner-count) }
          { asset-id: asset-id }
        )
        
        (map-set creator-asset-count
          { creator: beneficiary }
          { count: (+ (get count new-owner-count) u1) }
        )
      )
      
      ;; Increment transfer ID
      (var-set next-transfer-id (+ transfer-id u1))
      
      (ok transfer-id)
    )
  )
)

;; Raise a dispute
(define-public (raise-dispute
  (asset-id uint)
  (related-license-id (optional uint))
  (related-transfer-id (optional uint))
  (raised-against principal)
  (dispute-type (string-utf8 50))
  (dispute-description (string-utf8 1000))
  (evidence-hash (buff 32))
)
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (dispute-id (var-get next-dispute-id))
    )
    
    ;; Check if caller has a stake in the asset
    (asserts! (or
               (is-eq tx-sender (get current-owner asset))
               (is-eq tx-sender (get creator-principal asset))
               (is-collaborator asset-id tx-sender)
              )
              (err ERR-NOT-AUTHORIZED))
    
    ;; Create dispute
    (map-set disputes
      { dispute-id: dispute-id }
      {
        asset-id: asset-id,
        related-license-id: related-license-id,
        related-transfer-id: related-transfer-id,
        raised-by: tx-sender,
        raised-against: raised-against,
        dispute-type: dispute-type,
        dispute-description: dispute-description,
        evidence-hash: evidence-hash,
        status: DISPUTE-STATUS-OPEN,
        creation-date: block-height,
        resolution-date: none,
        resolution-notes: none,
        arbiter: none
      }
    )
    
    ;; Update asset to mark as in dispute
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        in-dispute: true,
        dispute-id: (some dispute-id)
      })
    )
    
    ;; If dispute is about a license, update license status
    (match related-license-id
      license-id
      (match (get-license license-id)
        license
        (map-set licenses
          { license-id: license-id }
          (merge license {
            status: LICENSE-STATUS-DISPUTE
          })
        )
        true
      )
      true
    )
    
    ;; If dispute is about a transfer, update transfer status
    (match related-transfer-id
      transfer-id
      (match (get-transfer transfer-id)
        transfer
        (map-set ip-transfers
          { transfer-id: transfer-id }
          (merge transfer {
            status: TRANSFER-STATUS-DISPUTED
          })
        )
        true
      )
      true
    )
    
    ;; Increment dispute ID
    (var-set next-dispute-id (+ dispute-id u1))
    
    (ok dispute-id)
  )
)

;; Assign arbiter to a dispute
(define-public (assign-arbiter (dispute-id uint) (arbiter-principal principal))
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
    )
    
    ;; Only contract owner can assign arbiters
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if dispute is open
    (asserts! (is-eq (get status dispute) DISPUTE-STATUS-OPEN) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Update dispute
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: DISPUTE-STATUS-ARBITRATION,
        arbiter: (some arbiter-principal)
      })
    )
    
    (ok true)
  )
)

;; Resolve a dispute
(define-public (resolve-dispute
  (dispute-id uint)
  (resolution-notes (string-utf8 1000))
)
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
      (asset-id (get asset-id dispute))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
    
    ;; Check if caller is assigned arbiter or contract owner
    (asserts! (or
               (is-eq tx-sender (var-get contract-owner))
               (is-eq (some tx-sender) (get arbiter dispute))
              )
              (err ERR-NOT-AUTHORIZED))
    
    ;; Check if dispute is not already resolved
    (asserts! (not (is-eq (get status dispute) DISPUTE-STATUS-RESOLVED)) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Update dispute status
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: DISPUTE-STATUS-RESOLVED,
        resolution-date: (some block-height),
        resolution-notes: (some resolution-notes)
      })
    )
    
    ;; Update asset to remove dispute flag
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        in-dispute: false,
        dispute-id: none
      })
    )
    
    ;; If dispute involved a license, update license status based on resolution
    (match (get related-license-id dispute)
      license-id
      (match (get-license license-id)
        license
        (map-set licenses
          { license-id: license-id }
          (merge license {
            status: LICENSE-STATUS-ACTIVE ;; Or other status based on resolution
          })
        )
        true
      )
      true
    )
    
    ;; If dispute involved a transfer, update transfer status based on resolution
    (match (get related-transfer-id dispute)
      transfer-id
      (match (get-transfer transfer-id)
        transfer
        (map-set ip-transfers
          { transfer-id: transfer-id }
          (merge transfer {
            status: TRANSFER-STATUS-PENDING ;; Or other status based on resolution
          })
        )
        true
      )
      true
    )
    
    (ok true)
  )
)

;; Use a license (increment usage count and verify license is valid)
(define-public (use-license (license-id uint))
  (let
    (
      (license (unwrap! (get-license license-id) (err ERR-LICENSE-NOT-FOUND)))
    )
    
    ;; Check if caller is the licensee
    (asserts! (is-eq tx-sender (get licensee license)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if license is active
    (asserts! (is-license-active license-id) (err ERR-LICENSE-NOT-ACTIVE))
    
    ;; Check if usage is within limits
    (match (get usage-limits license)
      limits (asserts! (< (get usage-count license) limits) (err ERR-LICENSE-EXPIRED))
      true
    )
    
    ;; Update usage count
    (map-set licenses
      { license-id: license-id }
      (merge license {
        usage-count: (+ (get usage-count license) u1),
        last-modified: block-height
      })
    )
    
    (ok true)
  )
)

;; Terminate a license
(define-public (terminate-license (license-id uint))
  (let
    (
      (license (unwrap! (get-license license-id) (err ERR-LICENSE-NOT-FOUND)))
      (asset-id (get asset-id license))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
 ;; Check if caller is licensor or contract owner
    (asserts! (or 
               (is-eq tx-sender (get licensor license))
               (is-eq tx-sender (var-get contract-owner))
              ) 
              (err ERR-NOT-AUTHORIZED))
    
    ;; Check if license is not already terminated
    (asserts! (not (is-eq (get status license) LICENSE-STATUS-TERMINATED)) (err ERR-INVALID-PARAMETERS))
    
    ;; Update license status
    (map-set licenses
      { license-id: license-id }
      (merge license {
        status: LICENSE-STATUS-TERMINATED,
        last-modified: block-height
      })
    )
    
    (ok true)
  )
)

;; Create a sublicense (if allowed by parent license)
(define-public (create-sublicense
  (parent-license-id uint)
  (sublicensee principal)
  (license-type uint)
  (license-terms (string-utf8 1000))
  (royalty-percent uint)
  (upfront-payment uint)
  (start-date uint)
  (end-date (optional uint))
  (territory (string-utf8 100))
  (usage-limits (optional uint))
  (payment-schedule (string-utf8 256))
  (license-hash (buff 32))
  (termination-conditions (string-utf8 500))
)
  (let
    (
      (parent-license (unwrap! (get-license parent-license-id) (err ERR-LICENSE-NOT-FOUND)))
      (asset-id (get asset-id parent-license))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (license-id (var-get next-license-id))
    )
    
    ;; Check if caller is the licensee of the parent license
    (asserts! (is-eq tx-sender (get licensee parent-license)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if sublicensing is allowed
    (asserts! (get is-sublicensable parent-license) (err ERR-INVALID-LICENSE-TERMS))
    
    ;; Check if parent license is active
    (asserts! (is-license-active parent-license-id) (err ERR-LICENSE-NOT-ACTIVE))
    
    ;; Check if license type is allowed
    (asserts! (is-some (index-of (get allowed-license-types asset) license-type)) (err ERR-INVALID-LICENSE-TERMS))
    
    ;; Check if royalty percentage is within limits and not lower than parent
    (asserts! (and
               (<= royalty-percent (var-get max-royalty-percent))
               (>= royalty-percent (get royalty-percent parent-license))
              ) 
              (err ERR-ROYALTY-EXCEEDS-MAX))
    
    ;; Check if end date is not later than parent license end date
    (match (get end-date parent-license)
      parent-end
      (match end-date
        sub-end (asserts! (<= sub-end parent-end) (err ERR-INVALID-LICENSE-TERMS))
        true
      )
      true
    )
    
    ;; Process upfront payment if any
    (when (> upfront-payment u0)
      (try! (stx-transfer? upfront-payment sublicensee tx-sender))
    )
    
    ;; Create the sublicense
    (map-set licenses
      { license-id: license-id }
      {
        asset-id: asset-id,
        licensor: tx-sender,
        licensee: sublicensee,
        license-type: license-type,
        license-terms: license-terms,
        royalty-percent: royalty-percent,
        upfront-payment: upfront-payment,
        start-date: start-date,
        end-date: end-date,
        territory: territory,
        usage-limits: usage-limits,
        usage-count: u0,
        payment-schedule: payment-schedule,
        status: LICENSE-STATUS-ACTIVE,
        creation-date: block-height,
        last-modified: block-height,
        license-hash: license-hash,
        is-sublicensable: false, ;; Typically sublicenses cannot be further sublicensed
        sublicense-parent: (some parent-license-id),
        termination-conditions: termination-conditions
      }
    )
    
    ;; Add to asset's licenses
    (map-set asset-licenses
      { asset-id: asset-id, index: (get license-count asset) }
      { license-id: license-id }
    )
    
    ;; Update asset license count
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        license-count: (+ (get license-count asset) u1)
      })
    )
    
    ;; Add to sublicensee's licenses
    (let
      (
        (licensee-count (default-to { count: u0 } (map-get? licensee-license-count { licensee: sublicensee })))
      )
      (map-set licensee-licenses
        { licensee: sublicensee, index: (get count licensee-count) }
        { license-id: license-id }
      )
      
      (map-set licensee-license-count
        { licensee: sublicensee }
        { count: (+ (get count licensee-count) u1) }
      )
    )
    
    ;; Initialize royalty payment count
    (map-set royalty-payment-count
      { license-id: license-id }
      { count: u0 }
    )
    
    ;; Increment license ID
    (var-set next-license-id (+ license-id u1))
    
    (ok license-id)
  )
)

;; Update platform fee percentage
(define-public (update-platform-fee (new-fee-percent uint))
  (begin
    ;; Only contract owner can update fee
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if fee is reasonable (max 10%)
    (asserts! (<= new-fee-percent u1000) (err ERR-INVALID-PARAMETERS))
    
    ;; Update fee
    (var-set platform-fee-percent new-fee-percent)
    
    (ok true)
  )
)

;; Update max royalty percentage
(define-public (update-max-royalty (new-max-percent uint))
  (begin
    ;; Only contract owner can update
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if max is reasonable (max 80%)
    (asserts! (<= new-max-percent u8000) (err ERR-INVALID-PARAMETERS))
    
    ;; Update max royalty
    (var-set max-royalty-percent new-max-percent)
    
    (ok true)
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    ;; Only current owner can transfer
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update owner
    (var-set contract-owner new-owner)
    
    (ok true)
  )
)

      (asset-id (var-get next-asset-id))
      (creator-count (default-to { count: u0 } (map-get? creator-asset-count { creator: tx-sender })))
    )
    
    ;; Validate asset type
    (asserts! (<= asset-type ASSET-TYPE-OTHER) (err ERR-INVALID-PARAMETERS))
    
    ;; Create the asset
    (map-set ip-assets
      { asset-id: asset-id }
      {
        title: title,
        description: description,
        asset-type: asset-type,
        creator-principal: tx-sender,
        creation-date: block-height,
        registration-date: block-height,
        content-hash: content-hash,
        metadata-url: metadata-url,
        license-count: u0,
        is-transferable: is-transferable,
        transfer-history: (list),
        current-owner: tx-sender,
        is-collaborative: false,
        collaboration-id: none,
        in-dispute: false,
        dispute-id: none,
        allowed-license-types: allowed-license-types,
        inheritance-beneficiary: none
      }
    )
    
    ;; Add to creator's assets
    (map-set creator-assets
      { creator: tx-sender, index: (get count creator-count) }
      { asset-id: asset-id }
    )
    
    ;; Update creator's asset count
    (map-set creator-asset-count
      { creator: tx-sender }
      { count: (+ (get count creator-count) u1) }
    )
    
    ;; Increment asset ID
    (var-set next-asset-id (+ asset-id u1))
    
    (ok asset-id)
  )
)
;; Create a collaboration for an IP asset
(define-public (create-collaboration
  (asset-id uint)
  (collaborators (list 10 principal))
  (royalty-splits (list 10 { collaborator: principal, split-percent: uint }))
  (decision-threshold uint)
  (collaboration-terms (string-utf8 1000))
  (agreement-hash (buff 32))
)
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (collaboration-id (var-get next-collaboration-id))
    )
    
    ;; Check if caller is owner or original creator
    (asserts! (is-eq tx-sender (get current-owner asset)) (err ERR-NOT-AUTHORIZED))
    
    ;; Ensure asset is not already collaborative
    (asserts! (not (get is-collaborative asset)) (err ERR-ALREADY-COLLABORATOR))
    
    ;; Validate collaborator list includes the creator
    (asserts! (is-some (index-of collaborators tx-sender)) (err ERR-INVALID-PARAMETERS))
    
    ;; Validate royalty splits add up to 100%
    (asserts! (is-eq (fold add-royalty-percent royalty-splits u0) u10000) (err ERR-INVALID-PARAMETERS))
    
    ;; Create collaboration
    (map-set collaborations
      { collaboration-id: collaboration-id }
      {
        asset-id: asset-id,
        creation-date: block-height,
        last-modified: block-height,
        collaborators: collaborators,
        royalty-splits: royalty-splits,
        decision-threshold: decision-threshold,
        collaboration-terms: collaboration-terms,
        agreement-hash: agreement-hash,
        administrator: tx-sender,
        is-active: true
      }
    )
    
    ;; Update asset to mark as collaborative
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        is-collaborative: true,
        collaboration-id: (some collaboration-id)
      })
    )
    
    ;; Increment collaboration ID
    (var-set next-collaboration-id (+ collaboration-id u1))
    
    (ok collaboration-id)
  )
)

;; Helper function to add royalty percentages
(define-private (add-royalty-percent (royalty-split { collaborator: principal, split-percent: uint }) (total uint))
  (+ total (get split-percent royalty-split))
)

;; Create a new license
(define-public (create-license
  (asset-id uint)
  (licensee principal)
  (license-type uint)
  (license-terms (string-utf8 1000))
  (royalty-percent uint)
  (upfront-payment uint)
  (start-date uint)
  (end-date (optional uint))
  (territory (string-utf8 100))
  (usage-limits (optional uint))
  (payment-schedule (string-utf8 256))
  (license-hash (buff 32))
  (is-sublicensable bool)
  (termination-conditions (string-utf8 500))
)
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (license-id (var-get next-license-id))
    )
    
    ;; Check if caller is current owner
    (asserts! (is-eq tx-sender (get current-owner asset)) (err ERR-NOT-AUTHORIZED))
    
    ;; If collaborative, check if caller is a collaborator
    (when (get is-collaborative asset)
      (asserts! (is-collaborator asset-id tx-sender) (err ERR-NOT-AUTHORIZED))
    )
    
    ;; Check if license type is allowed
    (asserts! (is-some (index-of (get allowed-license-types asset) license-type)) (err ERR-INVALID-LICENSE-TERMS))
    
    ;; Check if royalty percentage is within limits
    (asserts! (<= royalty-percent (var-get max-royalty-percent)) (err ERR-ROYALTY-EXCEEDS-MAX))
    
    ;; Process upfront payment if any
    (when (> upfront-payment u0)
      (try! (stx-transfer? upfront-payment licensee tx-sender))
    )
    
    ;; Create the license
    (map-set licenses
      { license-id: license-id }
      {
        asset-id: asset-id,
        licensor: tx-sender,
        licensee: licensee,
        license-type: license-type,
        license-terms: license-terms,
        royalty-percent: royalty-percent,
        upfront-payment: upfront-payment,
        start-date: start-date,
        end-date: end-date,
        territory: territory,
        usage-limits: usage-limits,
        usage-count: u0,
        payment-schedule: payment-schedule,
        status: LICENSE-STATUS-ACTIVE,
        creation-date: block-height,
        last-modified: block-height,
        license-hash: license-hash,
        is-sublicensable: is-sublicensable,
        sublicense-parent: none,
        termination-conditions: termination-conditions
      }
    )
    
    ;; Add to asset's licenses
    (map-set asset-licenses
      { asset-id: asset-id, index: (get license-count asset) }
      { license-id: license-id }
    )
    
    ;; Update asset license count
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        license-count: (+ (get license-count asset) u1)
      })
    )
    
    ;; Add to licensee's licenses
    (let
      (
        (licensee-count (default-to { count: u0 } (map-get? licensee-license-count { licensee: licensee })))
      )
      (map-set licensee-licenses
        { licensee: licensee, index: (get count licensee-count) }
        { license-id: license-id }
      )
      
      (map-set licensee-license-count
        { licensee: licensee }
        { count: (+ (get count licensee-count) u1) }
      )
    )
    
    ;; Initialize royalty payment count
    (map-set royalty-payment-count
      { license-id: license-id }
      { count: u0 }
    )
    
    ;; Increment license ID
    (var-set next-license-id (+ license-id u1))
    
    (ok license-id)
  )
)

;; Record a royalty payment
(define-public (record-royalty-payment
  (license-id uint)
  (amount uint)
  (payment-period-start uint)
  (payment-period-end uint)
  (transaction-id (buff 32))
)
  (let
    (
      (license (unwrap! (get-license license-id) (err ERR-LICENSE-NOT-FOUND)))
      (payment-count (default-to { count: u0 } (map-get? royalty-payment-count { license-id: license-id })))
      (asset-id (get asset-id license))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
    
    ;; Check if license is active
    (asserts! (is-license-active license-id) (err ERR-LICENSE-NOT-ACTIVE))
    
    ;; Check if caller is the licensee
    (asserts! (is-eq tx-sender (get licensee license)) (err ERR-NOT-AUTHORIZED))
    
    ;; Calculate platform fee
    (let
      (
        (platform-fee (/ (* amount (var-get platform-fee-percent)) u10000))
        (royalty-amount (- amount platform-fee))
        (owner (get current-owner asset))
      )
      
      ;; Pay platform fee to contract owner
      (try! (stx-transfer? platform-fee tx-sender (var-get contract-owner)))
      
      ;; Handle royalty payment to owner(s)
      (if (get is-collaborative asset)
        ;; Handle collaborative asset royalties
        (try! (distribute-collaborative-royalties license-id royalty-amount))
        
        ;; Pay single owner
        (try! (stx-transfer? royalty-amount tx-sender owner))
      )
      
      ;; Record the payment
      (map-set royalty-payments
        { license-id: license-id, payment-index: (get count payment-count) }
        {
          amount: amount,
          payment-date: block-height,
          payment-period-start: payment-period-start,
          payment-period-end: payment-period-end,
          paid-by: tx-sender,
          received-by: owner,
          transaction-id: transaction-id
        }
      )
      
      ;; Update payment count
      (map-set royalty-payment-count
        { license-id: license-id }
        { count: (+ (get count payment-count) u1) }
      )
      
      (ok true)
    )
  )
)

;; Helper to distribute royalties for collaborative assets
(define-private (distribute-collaborative-royalties (license-id uint) (amount uint))
  (let
    (
      (license (unwrap! (get-license license-id) (err ERR-LICENSE-NOT-FOUND)))
      (asset-id (get asset-id license))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (royalty-distribution (unwrap! (calculate-royalty-distribution license-id amount) (err ERR-INVALID-PARAMETERS)))
    )
    
    ;; Distribute to each collaborator
    (map distribute-royalty-share (merge-lists royalty-distribution (list amount tx-sender)))
    
    (ok true)
  )
)

;; Helper to distribute royalty share
(define-private (distribute-royalty-share (distribution { collaborator: principal, split-percent: uint, amount: uint, sender: principal }))
  (let
    (
      (share-amount (/ (* (get amount distribution) (get split-percent distribution)) u10000))
    )
    (stx-transfer? share-amount (get sender distribution) (get collaborator distribution))
  )
)

;; Helper to merge royalty splits with amount and sender
(define-private (merge-lists (splits (list 10 { collaborator: principal, split-percent: uint })) (values (list amount uint, sender principal)))
  (map merge-with-values splits (get amount values) (get sender values))
)

;; Helper to merge royalty split with amount and sender
(define-private (merge-with-values (split { collaborator: principal, split-percent: uint }) (amount uint) (sender principal))
  (merge split { amount: amount, sender: sender })
)

;; Request IP transfer
(define-public (request-ip-transfer
  (asset-id uint)
  (to-principal principal)
  (transfer-price uint)
  (transfer-terms (string-utf8 500))
  (transfer-hash (buff 32))
  (retains-royalties bool)
)
  (let
    (
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (transfer-id (var-get next-transfer-id))
    )
    
    ;; Check if caller is current owner
    (asserts! (is-eq tx-sender (get current-owner asset)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if asset is transferable
    (asserts! (get is-transferable asset) (err ERR-INVALID-TRANSFER))
    
    ;; Check if asset is in dispute
    (asserts! (not (get in-dispute asset)) (err ERR-DISPUTE-PENDING))
    
    ;; Create transfer request
    (map-set ip-transfers
      { transfer-id: transfer-id }
      {
        asset-id: asset-id,
        from-principal: tx-sender,
        to-principal: to-principal,
        transfer-price: transfer-price,
        transfer-date: none,
        request-date: block-height,
        status: TRANSFER-STATUS-PENDING,
        transfer-terms: transfer-terms,
        requires-approval: (get is-collaborative asset),
        approved-by: (if (get is-collaborative asset) (list tx-sender) (list)),
        transfer-hash: transfer-hash,
        retains-royalties: retains-royalties
      }
    )
    
    ;; Increment transfer ID
    (var-set next-transfer-id (+ transfer-id u1))
    
    (ok transfer-id)
  )
)

;; Approve collaborative transfer
(define-public (approve-transfer (transfer-id uint))
  (let
    (
      (transfer (unwrap! (get-transfer transfer-id) (err ERR-TRANSFER-NOT-FOUND)))
      (asset-id (get asset-id transfer))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
    )
    
    ;; Check if asset is collaborative
    (asserts! (get is-collaborative asset) (err ERR-NOT-COLLABORATIVE))
    
    ;; Check if caller is a collaborator
    (asserts! (is-collaborator asset-id tx-sender) (err ERR-NOT-COLLABORATOR))
    
    ;; Check if transfer is pending
    (asserts! (is-eq (get status transfer) TRANSFER-STATUS-PENDING) (err ERR-INVALID-TRANSFER))
    
    ;; Check if caller hasn't already approved
    (asserts! (is-none (index-of (get approved-by transfer) tx-sender)) (err ERR-ALREADY-CONFIRMED))
    
    ;; Add caller to approved list
    (map-set ip-transfers
      { transfer-id: transfer-id }
      (merge transfer {
        approved-by: (append (get approved-by transfer) tx-sender)
      })
    )
    
    (ok true)
  )
)

;; Complete IP transfer
(define-public (complete-ip-transfer (transfer-id uint))
  (let
    (
      (transfer (unwrap! (get-transfer transfer-id) (err ERR-TRANSFER-NOT-FOUND)))
      (asset-id (get asset-id transfer))
      (asset (unwrap! (get-ip-asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (from-principal (get from-principal transfer))
      (to-principal (get to-principal transfer))
      (transfer-price (get transfer-price transfer))
    )
    
    ;; Check if transfer is pending
    (asserts! (is-eq (get status transfer) TRANSFER-STATUS-PENDING) (err ERR-INVALID-TRANSFER))
    
    ;; If collaborative, check if enough approvals
    (when (get is-collaborative asset)
      (match (get collaboration-id asset)
        collaboration-id
        (let
          (
            (collaboration (unwrap! (get-collaboration collaboration-id) (err ERR-COLLABORATION-NOT-FOUND)))
            (approval-count (len (get approved-by transfer)))
            (total-collaborators (len (get collaborators collaboration)))
            (required-approvals (/ (* total-collaborators (get decision-threshold collaboration)) u10000))
          )
          ;; Check if enough approvals
          (asserts! (>= approval-count required-approvals) (err ERR-NOT-AUTHORIZED))
        )
        (err ERR-COLLABORATION-NOT-FOUND)
      )
    )
    
    ;; Process payment
    (when (> transfer-price u0)
      (try! (stx-transfer? transfer-price to-principal from-principal))
    )
    
    ;; Update transfer status
    (map-set ip-transfers
      { transfer-id: transfer-id }
      (merge transfer {
        status: TRANSFER-STATUS-COMPLETED,
        transfer-date: (some block-height)
      })
    )
    
    ;; Update asset ownership
    (map-set ip-assets
      { asset-id: asset-id }
      (merge asset {
        current-owner: to-principal,
        transfer-history: (append (get transfer-history asset) transfer-id)
      })
    )
    
    ;; Add to new owner's assets
    (let
      (
        (new-owner-count (default-to { count: u0 } (map-get? creator-asset-count { creator: to-principal })))
      )
      (map-set creator-assets
        { creator: to-principal, index: (get count new-owner-count) }
        { asset-id: asset-id }
      )
      
      (map-set creator-asset-count
        { creator: to-principal }
        { count: (+ (get count new-owner-count) u1) }
      )
    )
    
    (ok true)
  )
)
