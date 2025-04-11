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