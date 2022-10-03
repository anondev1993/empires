%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.empires.storage import realms

namespace Modifier {
    // @notice Asserts the target realm is not in the process of exiting the empire
    // @param realm_id The target realm id
    func assert_not_exiting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realm_id: felt
    ) {
        let (realm: Realm) = realms.read(realm_id);
        assert realm.exiting = 0;
        return ();
    }
}
