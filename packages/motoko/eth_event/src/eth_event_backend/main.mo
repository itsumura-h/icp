import EvmRpc "canister:evm_rpc";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Nat64 "mo:base/Nat64";

actor {
  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public func getLatestEthereumBlock() : async EvmRpc.Block {

    // Select RPC services
    // let services : EvmRpc.RpcServices = #Custom({
    //   chainId = 31337 : Nat64;
    //   services = [
    //     {
    //       url = "http://localhost:8545";
    //       headers = null;
    //     },
    //   ];
    // });
    let services : EvmRpc.RpcServices = #EthSepolia(?[#Sepolia]);

    // Call `eth_getBlockByNumber` RPC method (unused cycles will be refunded)
    Cycles.add<system>(100000000000);
    let result = await EvmRpc.eth_getBlockByNumber(services, null, #Latest);

    switch result {
      // Consistent, successful results
      case (#Consistent(#Ok block)) {
        return block;
      };
      // Consistent error message
      case (#Consistent(#Err error)) {
        Debug.trap("Error: " # debug_show error);
      };
      // Inconsistent results between RPC providers
      case (#Inconsistent(results)) {
        Debug.trap("Inconsistent results");
      };
    };
  };
};
