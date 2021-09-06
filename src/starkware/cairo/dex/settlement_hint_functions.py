from typing import Optional, Tuple

from common.objects.prover_input.prover_input import TransactionWitness
from common.objects.transaction.common_transaction import (
    FeeInfoExchange, Order, OrderL1, OrderL2, Party)
from starkware.cairo.dex.objects import FeeWitness, L2VaultUpdateWitness, OrderWitness
from starkware.cairo.lang.vm.relocatable import MaybeRelocatable


def get_order_witness(
        order: Order, settlement_witness: TransactionWitness, party: Party,
        vault_diff_idx: int) -> Tuple[OrderWitness, int]:
    """
    Returns an OrderWitness and an updated vault_diff index, for the given order.
    vault_diff_idx is an index to the L2 vault changes list in the wrapping settlement
    (settlement_witness.vault_diffs). The list holds the changes for both parties, and the given
    index should point to where the current party (the owner of the given order) vault changes
    start.
    Note that the vault updates in OrderWitness are only used in L2 Orders.
    """
    order_party_id = 0 if party is Party.A else 1
    prev_fulfilled_amount = settlement_witness.order_diffs[order_party_id].prev.fulfilled_amount

    # Set vaults witnesses (only for L2 vaults).
    if isinstance(order, OrderL1):
        sell_witness = buy_witness = None
    else:
        assert isinstance(order, OrderL2)
        sell_witness = L2VaultUpdateWitness(
            balance_before=settlement_witness.vault_diffs[vault_diff_idx].prev.balance)
        buy_witness = L2VaultUpdateWitness(
            balance_before=settlement_witness.vault_diffs[vault_diff_idx + 1].prev.balance)
        vault_diff_idx += 2

    return OrderWitness(
        sell_witness=sell_witness, buy_witness=buy_witness,
        prev_fulfilled_amount=prev_fulfilled_amount), vault_diff_idx


def get_fee_witness(
        order: Order, settlement_witness: TransactionWitness, fee_info_exchange: FeeInfoExchange,
        vault_diff_idx: int) -> Tuple[Optional[FeeWitness], int]:
    """
    Returns a FeeWitness and an updated vault_diff index, for the given order.
    vault_diff_idx is an index to the L2 vault changes list in the wrapping settlement
    (settlement_witness.vault_diffs). The list holds the changes for both parties, and the given
    index should point to where the current party (the owner of the given order) vault changes
    start.
    If order has no fees, returns None as the FeeWitness.
    Note that the vaults in FeeWitness are L2 vaults.
    """
    if fee_info_exchange is None:
        # OrderL2 with no fees.
        assert not isinstance(order, OrderL1), 'OrderL1 must have fee objects.'
        return None, vault_diff_idx
    # Set source fee witness (may be an L1 or L2 vault).
    elif isinstance(order, OrderL1):
        source_fee_witness = None
    else:
        assert isinstance(order, OrderL2)
        source_fee_witness = L2VaultUpdateWitness(
            balance_before=settlement_witness.vault_diffs[vault_diff_idx].prev.balance)
        vault_diff_idx += 1

    # Both order L1 and L2 (with fee) have an L2 vault as the fee destination vault, and thus,
    # a corresponding L2VaultUpdateWitness.
    destination_fee_witness = L2VaultUpdateWitness(
        balance_before=settlement_witness.vault_diffs[vault_diff_idx].prev.balance)
    return FeeWitness(
        source_fee_witness=source_fee_witness,
        destination_fee_witness=destination_fee_witness), vault_diff_idx + 1


def get_fee_info_struct(fee_info_exchange: FeeInfoExchange, segments) -> MaybeRelocatable:
    """
    Returns an address with the values of the given 'fee_info_exchange'.
    """
    return 0 if fee_info_exchange is None else segments.gen_arg([
        fee_info_exchange.fee_taken,
        fee_info_exchange.destination_vault_id,
        fee_info_exchange.destination_stark_key])
