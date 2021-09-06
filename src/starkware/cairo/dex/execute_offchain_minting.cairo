from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import assert_nn, assert_nn_le
from starkware.cairo.dex.dex_constants import MINTING_BIT, RANGE_CHECK_BOUND, TOKEN_ID_BOUND
from starkware.cairo.dex.dex_context import DexContext
from starkware.cairo.dex.vault_update import l2_vault_update_diff

# Executes an offchain minting which adds to the balance in a single vault.
# Asserts that the corresponding token is mintable - the minting bit is on.
func execute_offchain_minting(
        range_check_ptr, dex_context_ptr : DexContext*, vault_dict : DictAccess*) -> (
        range_check_ptr, vault_dict : DictAccess*):
    # Bound for the high part of the token id.
    const HIGH_PART_BOUND = TOKEN_ID_BOUND / RANGE_CHECK_BOUND

    local high_part
    local low_part
    alloc_locals

    # Validate that the minting bit is on in the token_id.
    %{
        token_id = mint_tx.token_id

        # Write the token id as a 251 bit number (TOKEN_ID_BOUND=2^250 + 1 bit):
        # +-----------------+------------------+------------LSB--+
        # | mint_bit (1b)   | high_part (122b) | low_part (128b) |
        # +-----------------+------------------+-----------------+     .
        assert ids.TOKEN_ID_BOUND <= token_id < 2*ids.TOKEN_ID_BOUND, \
            'Token id must be a 251-bit integer with the 251-bit on.'
        # Remaining bit from msb and lsb.
        leftover = token_id - ids.TOKEN_ID_BOUND
        ids.high_part = leftover // ids.RANGE_CHECK_BOUND
        ids.low_part  = leftover % ids.RANGE_CHECK_BOUND
    %}

    # The following guarantees that: high_part * RANGE_CHECK_BOUND + low_part < 2^250.
    # Verify that 0 <= low_part < 2^128.
    assert_nn{range_check_ptr=range_check_ptr}(low_part)
    # Verify that 0 <= high_part < 2^(250-128).
    assert_nn_le{range_check_ptr=range_check_ptr}(high_part, HIGH_PART_BOUND - 1)

    # Difference must be nonnegative.
    local diff
    %{ ids.diff = mint_tx.diff %}
    assert_nn{range_check_ptr=range_check_ptr}(diff)

    # Validate the vault change.
    local vault_id
    local stark_key
    %{
        ids.vault_id = mint_tx.vault_id
        ids.stark_key = mint_tx.stark_key

        from starkware.cairo.dex.objects import L2VaultUpdateWitness
        vault_update_witness = L2VaultUpdateWitness(
            balance_before = mint_tx_witness.vault_diffs[0].prev.balance)
    %}

    let (range_check_ptr) = l2_vault_update_diff(
        range_check_ptr=range_check_ptr,
        diff=diff,
        stark_key=stark_key,
        token_id=MINTING_BIT + high_part * RANGE_CHECK_BOUND + low_part,
        vault_index=vault_id,
        vault_change_ptr=vault_dict)

    return (range_check_ptr=range_check_ptr, vault_dict=vault_dict + DictAccess.SIZE)
end
