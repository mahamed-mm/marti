---
description: Build, install, and launch the app on iOS Simulator.
---

Build and run the app end-to-end using XcodeBuildMCP.

1. List simulators: `mcp__xcodebuildmcp__list_simulators`
2. Boot the default simulator (iPhone 16) if not already booted: `mcp__xcodebuildmcp__boot_simulator`
3. Build for simulator: `mcp__xcodebuildmcp__build_sim_name_proj`
4. Install the app: `mcp__xcodebuildmcp__install_app`
5. Launch the app: `mcp__xcodebuildmcp__launch_app`
6. Capture initial logs: `mcp__xcodebuildmcp__capture_logs`
7. Report the launch state and any runtime errors visible in the logs.
