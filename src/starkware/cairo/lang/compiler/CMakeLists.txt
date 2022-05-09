python_venv(cairo_lang_compile_venv
    PYTHON python3.7

    LIBS
    pip_cairo_lang
    pip_setuptools
)

python_exe(cairo_compile_exe
    VENV cairo_lang_compile_venv
    MODULE starkware.cairo.lang.compiler.cairo_compile
)
