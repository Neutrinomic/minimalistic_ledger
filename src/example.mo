import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import SWB "mo:swb/Stable";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Chain "mo:rechain";
import Sha256 "mo:sha2/Sha256";
import Option "mo:base/Option";
actor {

    let balances = Map.new<Principal, Nat>();

    public type Action = {
        caller : Principal;
        payload : {
            #transfer : {
                to : Principal;
                from : Principal;
                amount : Nat;
            };
            #mint : {
                to : Principal;
                amount : Nat;
            };
        };
    };

    public type ActionError = {
        #SomethingWentWrong : Text;
        #Another : Nat;
    };

    public type ActionWithPhash = Action and { phash : Blob };

    private func reducerBalances(a : Action) : Chain.ReducerResponse<ActionError> {
        switch (a.payload) {
            case (#transfer(t)) {
                // Don't change state here, only inside the returned function
                let balanceFrom = Option.get(Map.get(balances, Map.phash, t.from), 0);
                if (balanceFrom < t.amount) return #Err(#SomethingWentWrong("Not enough balance"));
                let balanceTo = Option.get(Map.get(balances, Map.phash, t.from), 0);

                #Ok(
                    func(_) {
                        // Only if all reducers return #Ok, this function will be executed and the state will be changed
                        ignore Map.put(balances, Map.phash, t.from, balanceFrom - t.amount : Nat);
                        ignore Map.put(balances, Map.phash, t.to, balanceTo + t.amount);
                    }
                );

            };
            case (#mint(m)) {
                let balance = Option.get(Map.get(balances, Map.phash, m.to), 0);
                #Ok(func(_) { ignore Map.put(balances, Map.phash, m.to, balance + m.amount) });
            };
        };
    };

    // -- Chain
    let chain_mem = Chain.Mem();

    let chain = Chain.Chain<Action, ActionError, ActionWithPhash>({
        mem = chain_mem;
        encodeBlock = func(b) = ("myschemaid", to_candid (b));
        addPhash = func(a, phash) = { a with phash };
        hashBlock = func(b) = Sha256.fromBlob(#sha224, b.1);
        reducers = [reducerBalances];
    });

    public shared ({ caller }) func do_something(action : Action) : async {
        #Ok : Chain.BlockId;
        #Err : ActionError;
    } {
        chain.dispatch({ action with caller });
    };

    public query func get_transactions(req : Chain.GetBlocksRequest) : async Chain.GetTransactionsResponse {
        chain.get_transactions(req);
    };

};
