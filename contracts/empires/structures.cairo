%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

struct Realm {
    lord: felt,
    annexation_date: felt,
    exiting: felt,
    release_date: felt,
}

struct Votes {
    yes: felt,
    no: felt,
}

struct Acquisition {
    token_id: felt,
    eth_amount: felt,
    passed: felt,
}
