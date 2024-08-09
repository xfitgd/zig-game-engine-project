set ENGINE_DIR=%1

glslc %ENGINE_DIR%/shaders/shader.vert -o %ENGINE_DIR%/shaders/out/vert.spv
glslc %ENGINE_DIR%/shaders/shader.frag -o %ENGINE_DIR%/shaders/out/frag.spv