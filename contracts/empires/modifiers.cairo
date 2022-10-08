%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from contracts.empires.storage import realms
from contracts.empires.structures import Realm

namespace Modifier {
    // @notice Asserts the target realm is not in the process of exiting the empire
    // @param realm_id The target realm id
    func assert_not_exiting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realm_id: felt
    ) {
        let (realm: Realm) = realms.read(realm_id);
        with_attr error_message("realm exiting the empire") {
            assert realm.exiting = 0;
        }
        return ();
    }

    // @notice Asserts the target realm is part of the empire
    // @param realm_id The target realm id
    func assert_part_of_empire{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realm_id: felt
    ) {
        let (realm: Realm) = realms.read(realm_id);
        with_attr error_message("realm not part of the empire") {
            assert_not_zero(realm.lord);
            assert_not_zero(realm.annexation_date);
        }
        return ();
    }
}
