%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.uint256 import Uint256

from contracts.empires.storage import (
    realms,
    realm_contract,
    producer_taxes,
    attacker_taxes,
    goblin_taxes,
)
from contracts.empires.structures import Realm
from src.openzeppelin.token.erc721.IERC721 import IERC721
from src.openzeppelin.access.ownable.library import Ownable

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    emperor: felt,
    realm_contract_address: felt,
    producer_taxes_: felt,
    attacker_taxes_: felt,
    goblin_taxes_: felt,
) {
    Ownable.initializer(emperor);
    realm_contract.write(realm_contract_address);
    producer_taxes.write(producer_taxes_);
    attacker_taxes.write(attacker_taxes_);
    goblin_taxes.write(goblin_taxes_);
    return ();
}

@external
func delegate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(realm_id: felt) {
    let (caller) = get_caller_address();
    let (empire) = get_contract_address();
    let (realm_contract_address) = realm_contract.read();

    IERC721.transferFrom(
        contract_address=realm_contract_address,
        from_=caller,
        to=empire,
        tokenId=Uint256(realm_id, 0),
    );

    let (ts) = get_block_timestamp();
    realms.write(realm_id, Realm(caller, ts));
    return ();
}
