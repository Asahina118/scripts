#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s <project-directory>\n' "$0" >&2
    exit 1
fi

project_dir="$1"
mkdir -- "$project_dir"
cd -- "$project_dir"

mkdir build src tests

mkdir -p tests/extern

wget -O tests/extern/doctest.h \
    https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h

cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
get_filename_component(project_name "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
project("${project_name}" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(CTest)

add_executable("${project_name}"
    src/main.cpp
)

target_include_directories("${project_name}" PUBLIC
        ${PROJECT_SOURCE_DIR}
)

if(BUILD_TESTING)
    add_subdirectory(tests test)
endif()
EOF

cat > src/main.cpp <<'EOF'
#include <cstdlib>

int main()
{
    return EXIT_SUCCESS;
}
EOF

cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
EOF

cat > tests/CMakeLists.txt<<'EOF'
add_library(doctest INTERFACE)

target_include_directories(doctest INTERFACE
    ${PROJECT_SOURCE_DIR}
)

add_executable(example    
    ${PROJECT_SOURCE_DIR}/tests/example.cpp
)

target_link_libraries(example PRIVATE
    doctest
)

target_compile_definitions(example PRIVATE
    DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
)

set_target_properties(example PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
)

add_test(NAME example COMMAND example)
EOF

cat > run_test.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
./build.sh
ctest --test-dir build --verbose
EOF

chmod +x build.sh run_test.sh

cat > tests/example.cpp<<'EOF'
#include "tests/extern/doctest.h"

TEST_CASE("example")
{
    CHECK(2 + 2 == 4);
}
EOF

cat > .gitignore <<'EOF'
/build/
/.clangd
/notes/
EOF

cat > .clangd <<'EOF'
CompileFlags:
  CompilationDatabase: build
EOF

