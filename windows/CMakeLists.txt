# List of absolute paths to all plugin C/C++ files.
list(APPEND PLUGIN_SOURCES
  "clipboard_plugin.cpp"
  "clipboard_plugin.h"
)

# List of absolute paths to all plugin Windows-specific C/C++ files.
list(APPEND PLUGIN_WINDOWS_SOURCES
)

# List of libraries to link against.
list(APPEND PLUGIN_LIBRARIES
  gdiplus
  shlwapi
)

