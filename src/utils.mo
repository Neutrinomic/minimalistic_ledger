import Blob "mo:base/Blob";
import T "./icrc";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Sha256 "mo:sha2/Sha256";
import Option "mo:base/Option";

module {

    public func accountToBlob(acc: T.Account) : ?Blob {
        ignore do ? { if (acc.subaccount!.size() != 32) return null; };
        ?Principal.toLedgerAccount(acc.owner, acc.subaccount);
    };

    public func now() : Nat64 {
        Nat64.fromNat(Int.abs(Time.now()));
    };

    public func dedup(bacc:Blob, t: T.TransferArg) : ?Blob {
        do ? {
            let memo = t.memo!;
            let created_at = t.created_at_time!;
            let digest = Sha256.Digest(#sha224);
            digest.writeBlob(bacc);
            digest.writeArray(ENat64(created_at));
            digest.writeBlob(memo);
            digest.sum();
        }
    };

    public func ENat64(value : Nat64) : [Nat8] {
        return [
            Nat8.fromNat(Nat64.toNat(value >> 56)),
            Nat8.fromNat(Nat64.toNat((value >> 48) & 255)),
            Nat8.fromNat(Nat64.toNat((value >> 40) & 255)),
            Nat8.fromNat(Nat64.toNat((value >> 32) & 255)),
            Nat8.fromNat(Nat64.toNat((value >> 24) & 255)),
            Nat8.fromNat(Nat64.toNat((value >> 16) & 255)),
            Nat8.fromNat(Nat64.toNat((value >> 8) & 255)),
            Nat8.fromNat(Nat64.toNat(value & 255)),
        ];
    };
}