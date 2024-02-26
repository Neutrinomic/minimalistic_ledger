import Map "mo:map/Map";
import Principal "mo:base/Principal";
import ICRC "./icrc";
import U "./utils";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import SWB "mo:swb/Stable";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Chain "mo:rechain";
import Deduplication "./reducers/deduplication";
import T "./types";
import Balances "reducers/balances";
import Sha256 "mo:sha2/Sha256";

actor {

    // -- Ledger configuration
    let config : T.Config = {
        var TX_WINDOW  = 86400_000_000_000;  // 24 hours in nanoseconds
        var PERMITTED_DRIFT = 60_000_000_000;
        var FEE = 1_000;
        var MINTING_ACCOUNT = {
            owner = Principal.fromText("aaaaa-aa");
            subaccount = null;
            }
    };

    // -- Reducer : Balances
    stable let balances_mem = Balances.Mem();
    let balances = Balances.Balances({
        config;
        mem = balances_mem;
    });

    // -- Reducer : Deduplication

    stable let dedup_mem = Deduplication.Mem();
    let dedup = Deduplication.Deduplication({
        config;
        mem = dedup_mem;
    });

    // -- Chain
    let chain_mem = Chain.Mem();

    let chain = Chain.Chain<T.Action, T.ActionError, T.ActionWithPhash>({
        mem = chain_mem;
        encodeBlock = func(b) = ("myschemaid", to_candid (b));
        addPhash = func(a, phash) = {a with phash};
        hashBlock = func(b) = Sha256.fromBlob(#sha224, b.1);
        reducers = [dedup.reducer, balances.reducer];
    });

    // --

    // ICRC-1
    public shared ({ caller }) func icrc1_transfer(req : ICRC.TransferArg) : async ICRC.Result {
        transfer(caller, req);
    };

    public query func icrc1_balance_of(acc: ICRC.Account) : async Nat {
        balances.get(acc)
    };

    // Oversimplified ICRC-4
    public shared({caller}) func batch_transfer(req: [ICRC.TransferArg]) : async [ICRC.Result] {
        Array.map<ICRC.TransferArg, ICRC.Result>(req, func (r) = transfer(caller, r));
    };

    // Alternative to ICRC-3 
    public query func get_transactions(req: Chain.GetBlocksRequest) : async Chain.GetTransactionsResponse {
        chain.get_transactions(req);
    };

    // --
  
    private func transfer(caller:Principal, req:ICRC.TransferArg) : ICRC.Result {
        let from : ICRC.Account = {
            owner = caller;
            subaccount = req.from_subaccount;
        };

        let payload : T.Payload = if (from == config.MINTING_ACCOUNT) {
            #mint({
                to = req.to;
                amount = req.amount;
            });
        } else if (req.to == config.MINTING_ACCOUNT) {
            #burn({
                from = from;
                amount = req.amount;
            });
        } else {
            #transfer({
                to = req.to;
                fee = req.fee;
                from = from;
                amount = req.amount;
            });
        };

        let action = {
            caller;
            created_at_time = req.created_at_time;
            memo = req.memo;
            timestamp = U.now();
            payload;
        };

        chain.dispatch(action);
    };

};
