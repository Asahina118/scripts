#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]] then
    printf 'Usage: %s <project-directory>\n' "$0" >&2
    exit 1
fi

project_dir="$1"
mkdir -- "$project_dir"
cd -- "$project_dir"

mkdir build src test

mkdir -p test/extern

wget -O test/extern/doctest.h \
    https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h

cat > CMakeLists.txt<<'EOF'
add_library(doctest INTERFACE)

target_include_directories(doctest INTERFACE
    ${PROJECT_SOURCE_DIR}/tests/extern/doctest
)
EOF


cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
get_filename_component(project_name "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
project("${project_name}" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

enable_testing()
include(CTest)

if(BUILD_TESTING)
    add_subdirectory(tests test)
endif()
EOF

cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
EOF

cat > run_test.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
./build.sh
ctest --test-dir build --verbose
EOF

chmod +x build.sh run_test.sh

cat > .gitignore <<'EOF'
/build/
/.clangd
/notes/
EOF

cat > .clangd <<'EOF'
CompileFlags:
  CompilationDatabase: build
EOF

