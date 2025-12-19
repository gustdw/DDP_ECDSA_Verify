To get to the results we achieved, some minor changes need to be made:
1. Synthesis: Run strategy was changed to Flow_RuntimeOptimized (Vivado Synthesis 2023)
2. Implementation: Run strategy was changed to Performance_ExplorePostRoutePhysOpt (Vivado Implementation 2023)
3. Due to new testgenerationscripts, testvector.c cannot co-exist in the same folder as the sw_project.