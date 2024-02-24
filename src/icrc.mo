
module {
  public type Account = { owner : Principal; subaccount : ?Blob };

  public type ArchivedRange = {
    callback : shared query GetBlocksRequest -> async BlockRange;
    start : Nat;
    length : Nat;
  };
  public type ArchivedRange_1 = {
    callback : shared query GetBlocksRequest -> async TransactionRange;
    start : Nat;
    length : Nat;
  };
  public type BlockRange = { blocks : [Value] };
  public type Burn = {
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
    spender : ?Account;
  };
  public type FeatureFlags = { icrc2 : Bool };
  public type GetBlocksRequest = { start : Nat; length : Nat };
  public type GetBlocksResponse = {
    certificate : ?Blob;
    first_index : Nat;
    blocks : [Value];
    chain_length : Nat64;
    archived_blocks : [ArchivedRange];
  };
  public type GetTransactionsResponse = {
    first_index : Nat;
    log_length : Nat;
    transactions : [Transaction];
    archived_transactions : [ArchivedRange_1];
  };
  public type DedupeId = Blob;
  public type StoredBlock = {
      timestamp : Nat64;
      kind : StoredKind
  };
  public type StoredKind = {
      #transfer: Transfer;
      #burn: Burn;
      #mint: Mint;
  };
  public type MetadataValue = {
    #Int : Int;
    #Nat : Nat;
    #Blob : Blob;
    #Text : Text;
  };
  public type Mint = {
    to : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };
  public type Result = { #Ok : Nat; #Err : TransferError };
  public type StandardRecord = { url : Text; name : Text };
  public type Transaction = {
    burn : ?Burn;
    kind : Text;
    mint : ?Mint;
    approve : ?Approve;
    timestamp : Nat64;
    transfer : ?Transfer;
  };
  public type Approve = {
    fee : ?Nat;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    spender : Account;
  };
  public type TransactionRange = { transactions : [Transaction] };
  public type Transfer = {
    to : Account;
    fee : ?Nat;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
    spender : ?Account;
  };

  public type TransferArg = {
    to : Account;
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };

  public type TransferFromArgs = {
    to : Account;
    fee : ?Nat;
    spender_subaccount : ?Blob;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };


  public type Value = {
    #Int : Int;
    #Map : [(Text, Value)];
    #Nat : Nat;
    #Nat64 : Nat64;
    #Blob : Blob;
    #Text : Text;
    #Array : Vec;
  };
  public type Vec = [
    {
      #Int : Int;
      #Map : [(Text, Value)];
      #Nat : Nat;
      #Nat64 : Nat64;
      #Blob : Blob;
      #Text : Text;
      #Array : Vec;
    }
  ];
  
  public type Self = actor {
    get_transactions : shared query GetBlocksRequest -> async GetTransactionsResponse;
    icrc1_balance_of : shared query Account -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, MetadataValue)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [StandardRecord];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Nat;
    icrc1_transfer : shared TransferArg -> async Result;
  };

}