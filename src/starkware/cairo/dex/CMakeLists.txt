if (NOT DEFINED CAIRO_DEX_PROGRAM_LIB_ADDITIONAL_LIBS)
    set(CAIRO_DEX_PROGRAM_LIB_ADDITIONAL_LIBS pip_cairo_lang)
endif()
if (NOT DEFINED CAIRO_DEX_PROGRAM_HASH_TEST_ADDITIONAL_LIBS)
    set(CAIRO_DEX_PROGRAM_HASH_TEST_ADDITIONAL_LIBS pip_cairo_lang pip_setuptools)
endif()

cairo_compile(cairo_dex_program cairo_dex_compiled.json main.cairo "--debug_info_with_source")

python_lib(cairo_dex_program_lib
    PREFIX starkware/cairo/dex

    FILES
    dex_constants.cairo
    dex_context.cairo
    execute_batch.cairo
    execute_false_full_withdrawal.cairo
    execute_limit_order.cairo
    execute_modification.cairo
    execute_offchain_minting.cairo
    execute_settlement.cairo
    execute_transfer.cairo
    fee.cairo
    general_config.cairo
    hash_vault_ptr_dict.cairo
    l1_vault_update.cairo
    main.cairo
    main_hint_functions.py
    message_hashes.cairo
    message_l1_order.cairo
    settlement_hint_functions.py
    vault_update.cairo
    verify_order_id.cairo
    volition.cairo
    ${CAIRO_DEX_PROGRAM_LIB_ADDITIONAL_FILES}

    ARTIFACTS
    "${CMAKE_CURRENT_BINARY_DIR}/cairo_dex_compiled.json cairo_dex_compiled.json"

    LIBS
    exchange_cairo_definitions_lib
    exchange_cairo_lib
    ${CAIRO_DEX_PROGRAM_LIB_ADDITIONAL_LIBS}
)
add_dependencies(cairo_dex_program_lib cairo_dex_program)

# Program hash.
full_python_test(cairo_dex_program_hash_test
    PREFIX starkware/cairo/dex
    PYTHON python3.7
    TESTED_MODULES starkware/cairo/dex

    FILES
    generate_program_hash_test.py

    LIBS
    cairo_dex_program_lib
    program_hash_test_utils_lib
    pip_pytest
    ${CAIRO_DEX_PROGRAM_HASH_TEST_ADDITIONAL_LIBS}
)

python_exe(generate_cairo_dex_program_hash
    VENV cairo_dex_program_hash_test_venv
    MODULE starkware.cairo.dex.generate_program_hash_test
    ARGS "--fix"
)
