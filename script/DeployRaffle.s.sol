//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

// contract DeployRaffle is Script{
//     function run() external returns(Raffle){
//         vm.startBroadcast();
//         Raffle raffle = new Raffle(,,
//         0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
//         0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
//         ,40000);
//         vm.stopBroadcast();

//         return raffle;
//     }
// }