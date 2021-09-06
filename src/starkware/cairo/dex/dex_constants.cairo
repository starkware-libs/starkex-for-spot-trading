# The hash of an empty vault (i.e., with balance = 0) is defined to be h(h(0,0),0).
const ZERO_VAULT_HASH = 3051532127692517571387022095821932649971160144101372951378323654799587621206

# Balance should be in the range [0, 2**63).
const BALANCE_BOUND = %[ 2 ** 63 %]

# Nonce should be in the range [0, 2**31).
const NONCE_BOUND = %[ 2 ** 31 %]

# Expiration timestamp should be in the range [0, 2**22).
const EXPIRATION_TIMESTAMP_BOUND = %[ 2 ** 22 %]

# Order id should be in the range [0, 2**63).
const ORDER_ID_BOUND = %[ 2 ** 63 %]

# L1 vault index should be in the range [0, 2**64).
const L1_VAULT_INDEX_BOUND = %[ 2 ** 64 %]

# The result of a hash builtin should be in the range [0, 2**251).
const HASH_MESSAGE_BOUND = %[ 2 ** 251 %]

# The range-check builtin enables verifying that a value is within the range [0, 2**128).
const RANGE_CHECK_BOUND = %[ 2 ** 128 %]

# The bound for the token_id without the minting bit should be in the range [0, 2**250).
const TOKEN_ID_BOUND = %[ 2 ** 250 %]

# The minting bit.
const MINTING_BIT = TOKEN_ID_BOUND

# The length of an Ethereum address is 160 bits.
const ETH_ADDRESS_SHIFT = %[ 2 ** 160 %]

namespace PackedOrderMsg:
    const SETTLEMENT_ORDER_TYPE = 0
    const TRANSFER_ORDER_TYPE = 1
    const CONDITIONAL_TRANSFER_ORDER_TYPE = 2
    # Vault shift in packed order message is 2**31, regardless of the actual vault tree height.
    const VAULT_SHIFT = %[ 2 ** 31 %]
    const AMOUNT_SHIFT = BALANCE_BOUND
    const NONCE_SHIFT = NONCE_BOUND
    const EXPIRATION_TIMESTAMP_SHIFT = EXPIRATION_TIMESTAMP_BOUND
end
