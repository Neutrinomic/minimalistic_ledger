import Map "mo:map/Map";
import Principal "mo:base/Principal";
import T "./icrc";
import U "./utils";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import SWB "mo:swb";

actor {

    let FEE = 1_0000;
  
    let TX_WINDOW : Nat64 = 86400_000_000_000;  // 24 hours in nanoseconds
    let PERMITTED_DRIFT : Nat64 = 60_000_000_000;

    let minting_account : T.Account = {owner= Principal.fromText("aaaaa-aa"); subaccount=null};

    stable let accounts = Map.new<Blob, Nat>();
    stable let dedup = Map.new<Blob, Nat>();

    let buf = SWB.SlidingWindowBuffer<T.StoredBlock>();

    public shared({caller}) func icrc1_transfer(req: T.TransferArg) : async T.Result {
        transfer(caller, req);
    };

    public shared({caller}) func batch_transfer(req: [T.TransferArg]) : async [T.Result] {
        Array.map<T.TransferArg, T.Result>(req, func (r) = transfer(caller, r));
    };

    private func transfer(caller: Principal, req: T.TransferArg) : T.Result {

        let from : T.Account = {owner=caller; subaccount=req.from_subaccount};
        let tx_kind = if (from == minting_account) { #mint } else if (req.to == minting_account) { #burn } else { #transfer };

        ignore do ? { if (U.now() < req.created_at_time!) return #Err(#CreatedInFuture({ledger_time = U.now()}))};
        ignore do ? { if (req.created_at_time! + TX_WINDOW + PERMITTED_DRIFT < U.now()) return #Err(#TooOld)};  
        ignore do ? { if (req.fee! != FEE) return #Err(#BadFee({expected_fee = FEE}))};

        let ?from_bacc = U.accountToBlob({owner=caller; subaccount=req.from_subaccount}) else return #Err(#GenericError({message = "Invalid From Subaccount"; error_code = 1}));
        let ?to_bacc = U.accountToBlob(req.to) else return #Err(#GenericError({message = "Invalid To Subaccount"; error_code = 1}));
        let dedupId = U.dedup(from_bacc, req);
        ignore do ? { return #Err(#Duplicate({duplicate_of=Map.get(dedup, Map.bhash, dedupId!)!})); };

        let kind : T.StoredKind = switch(tx_kind) {
            case (#transfer) {
                let bal = get_balance(from_bacc);
                let to_bal = get_balance(to_bacc);
                if (bal < req.amount + FEE) return #Err(#InsufficientFunds({balance = bal}));
                put_balance(from_bacc, bal - req.amount - FEE);
                put_balance(to_bacc, to_bal + req.amount);
                #transfer({req with from; spender=null});
            };
            case (#burn) {
                let bal = get_balance(from_bacc);
                if (bal < req.amount + FEE) return #Err(#InsufficientFunds({balance = bal}));
                let dedupId = U.dedup(from_bacc, req);
                ignore do ? { return #Err(#Duplicate({duplicate_of=Map.get(dedup, Map.bhash, dedupId!)!})); };
                put_balance(from_bacc, bal - req.amount - FEE);
                #burn({req with from; spender=null});
            };
            case (#mint) {
                let to_bal = get_balance(to_bacc);
                put_balance(to_bacc, to_bal - req.amount);
                let dedupId = U.dedup(from_bacc, req);
                ignore do ? { return #Err(#Duplicate({duplicate_of=Map.get(dedup, Map.bhash, dedupId!)!})); };
                #mint(req);
            };
        };

        let blockId = buf.add({kind; timestamp = U.now()}: T.StoredBlock);
        ignore do ? { Map.put(dedup, Map.bhash, dedupId!, blockId); };
        #Ok(blockId);

    };

    private func get_balance(bacc: Blob) : Nat {
        let ?bal = Map.get(accounts, Map.bhash, bacc) else return 0;
        bal;
    };

    private func put_balance(bacc : Blob, bal : Nat) : () {
      ignore Map.put<Blob, Nat>(accounts, Map.bhash, bacc, bal);
    };

    public query func icrc1_balance_of(acc: T.Account) : async Nat {
        let ?bacc = U.accountToBlob(acc) else return 0;
        get_balance(bacc)
    };
}