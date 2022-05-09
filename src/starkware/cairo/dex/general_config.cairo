struct GeneralConfig:
    member validium_tree_height : felt
    member rollup_tree_height : felt
    member orders_tree_height : felt
    member unique_minting_enforced : felt
end

# Computes the encoded general config.
func encode_general_config(general_config : GeneralConfig*) -> (encoded_config : felt):
    # Verify the unique minting enforcement bit is indeed a single bit.
    let unique_minting = general_config.unique_minting_enforced
    assert unique_minting * unique_minting = unique_minting
    return (encoded_config=unique_minting)
end
