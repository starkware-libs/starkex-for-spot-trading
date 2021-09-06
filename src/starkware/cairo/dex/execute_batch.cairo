from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.dex.dex_context import DexContext
from starkware.cairo.dex.execute_false_full_withdrawal import execute_false_full_withdrawal
from starkware.cairo.dex.execute_modification import ModificationOutput, execute_modification
from starkware.cairo.dex.execute_offchain_minting import execute_offchain_minting
from starkware.cairo.dex.execute_settlement import execute_settlement
from starkware.cairo.dex.execute_transfer import execute_transfer
from starkware.cairo.dex.message_l1_order import L1OrderMessageOutput

# Executes a batch of transactions (settlements, transfers, offchain-minting, modifications).
#
# Hint arguments:
# * transactions - a list of the remaining transactions in the batch.
# * transaction_witnesses - a list of the matching TransactionWitness objects.
func execute_batch(
        modification_ptr : ModificationOutput*, conditional_transfer_ptr : felt*,
        l1_order_message_ptr : L1OrderMessageOutput*,
        l1_order_message_start_ptr : L1OrderMessageOutput*, hash_ptr : HashBuiltin*,
        range_check_ptr, ecdsa_ptr : SignatureBuiltin*, vault_dict : DictAccess*,
        l1_vault_dict : DictAccess*, order_dict : DictAccess*, dex_context_ptr : DexContext*) -> (
        modification_ptr : ModificationOutput*, conditional_transfer_ptr : felt*,
        l1_order_message_ptr : L1OrderMessageOutput*, hash_ptr : HashBuiltin*, range_check_ptr,
        ecdsa_ptr : SignatureBuiltin*, vault_dict : DictAccess*, l1_vault_dict : DictAccess*,
        order_dict : DictAccess*):
    # Guess if the first transaction is a settlement.
    %{
        first_transaction = transactions[0] if len(transactions) > 0 else None
        from common.objects.transaction.raw_transaction import Settlement
        memory[ap] = 1 if isinstance(first_transaction, Settlement) else 0
    %}
    jmp handle_settlement if [ap] != 0; ap++

    # Guess if the first transaction is a transfer.
    %{
        from common.objects.transaction.raw_transaction import Transfer
        memory[ap] = 1 if isinstance(first_transaction, Transfer) else 0
    %}
    jmp handle_transfer if [ap] != 0; ap++

    # Guess if the first transaction is an offchain-minting transaction.
    %{
        from common.objects.transaction.raw_transaction import Mint
        memory[ap] = 1 if isinstance(first_transaction, Mint) else 0
    %}
    jmp handle_offchain_minting if [ap] != 0; ap++

    # Guess if the first transaction is a modification.
    %{
        memory[ap] = 1 if (first_transaction is not None) and \
            first_transaction.is_modification else 0
    %}
    jmp handle_modification if [ap] != 0; ap++

    # Otherwise, check that there are no other (undefined) transactions and return.
    %{ assert len(transactions) == 0, f'Could not handle transaction: {first_transaction}.' %}
    return (
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        hash_ptr=hash_ptr,
        range_check_ptr=range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        vault_dict=vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=order_dict)

    handle_settlement:
    # Call execute_settlement.
    %{
        settlement = transactions.pop(0)
        settlement_witness = transaction_witnesses.pop(0)
    %}
    let settlement_res = execute_settlement(
        hash_ptr=hash_ptr,
        range_check_ptr=range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        vault_dict=vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=order_dict,
        dex_context_ptr=dex_context_ptr)

    # Call execute_batch recursively.
    return execute_batch(
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        l1_order_message_ptr=settlement_res.l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        hash_ptr=settlement_res.hash_ptr,
        range_check_ptr=settlement_res.range_check_ptr,
        ecdsa_ptr=settlement_res.ecdsa_ptr,
        vault_dict=settlement_res.vault_dict,
        l1_vault_dict=settlement_res.l1_vault_dict,
        order_dict=settlement_res.order_dict,
        dex_context_ptr=dex_context_ptr)

    handle_transfer:
    # Call execute_transfer.
    %{
        transfer = transactions.pop(0)
        transfer_witness = transaction_witnesses.pop(0)
    %}
    let transfer_res = execute_transfer(
        hash_ptr=hash_ptr,
        range_check_ptr=range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        vault_dict=vault_dict,
        order_dict=order_dict,
        dex_context_ptr=dex_context_ptr)

    # Call execute_batch recursively.
    return execute_batch(
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=transfer_res.conditional_transfer_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        hash_ptr=transfer_res.hash_ptr,
        range_check_ptr=transfer_res.range_check_ptr,
        ecdsa_ptr=transfer_res.ecdsa_ptr,
        vault_dict=transfer_res.vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=transfer_res.order_dict,
        dex_context_ptr=dex_context_ptr)

    handle_offchain_minting:
    %{
        mint_tx = transactions.pop(0)
        mint_tx_witness = transaction_witnesses.pop(0)
    %}
    # Call execute_offchain_minting.
    let offchain_minting_res = execute_offchain_minting(
        range_check_ptr=range_check_ptr, dex_context_ptr=dex_context_ptr, vault_dict=vault_dict)

    # Call execute_batch recursively.
    return execute_batch(
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        hash_ptr=hash_ptr,
        range_check_ptr=offchain_minting_res.range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        vault_dict=offchain_minting_res.vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=order_dict,
        dex_context_ptr=dex_context_ptr)

    handle_modification:
    # Guess if the first modification is a false full withdrawal.
    %{
        modification = transactions.pop(0)
        modification_witness = transaction_witnesses.pop(0)

        from common.objects.transaction.raw_transaction import FalseFullWithdrawal
        memory[ap] = 1 if isinstance(modification, FalseFullWithdrawal) else 0
    %}
    jmp handle_false_full_withdrawal if [ap] != 0; ap++

    # Call execute_modification.
    let (range_check_ptr, modification_ptr, vault_dict) = execute_modification(
        range_check_ptr=range_check_ptr,
        modification_ptr=modification_ptr,
        dex_context_ptr=dex_context_ptr,
        vault_dict=vault_dict)

    # Call execute_batch recursively.
    return execute_batch(
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        hash_ptr=hash_ptr,
        range_check_ptr=range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        vault_dict=vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=order_dict,
        dex_context_ptr=dex_context_ptr)

    handle_false_full_withdrawal:
    # Call execute_false_full_withdrawal.
    let (vault_dict, modification_ptr) = execute_false_full_withdrawal(
        modification_ptr=modification_ptr, dex_context_ptr=dex_context_ptr, vault_dict=vault_dict)

    # Call execute_batch recursively.
    return execute_batch(
        modification_ptr=modification_ptr,
        conditional_transfer_ptr=conditional_transfer_ptr,
        l1_order_message_ptr=l1_order_message_ptr,
        l1_order_message_start_ptr=l1_order_message_start_ptr,
        hash_ptr=hash_ptr,
        range_check_ptr=range_check_ptr,
        ecdsa_ptr=ecdsa_ptr,
        vault_dict=vault_dict,
        l1_vault_dict=l1_vault_dict,
        order_dict=order_dict,
        dex_context_ptr=dex_context_ptr)
end
