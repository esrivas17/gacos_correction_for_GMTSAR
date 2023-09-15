These software is intended to correct unwrapped phases using GACOS grids for GMTSAR.

They have been tested with: GMT v6.1.0 GMTSAR v6.0

On "Test_against_matlab" folder, I perform comparisons with matlab with consistent results.
To reproduce the output just use: source command.txt in each folder.
There is a small README file in each folder

SINGLE INTERFEROGRAM
single_GACOS_correction.csh is intented to correct a single interferogram at a time with certain parameters

STACK OF INTERFEROGRAMS
GACOS_correction.csh and operation.csh are used to correct a stack of interferograms in a time series process

Corrections are applied to the unwrap.grd files

Feel free to use and edit the code if needed

References:

Yu, C., Li, Z., Penna, N. T., & Crippa, P. (2018). Generic atmospheric correction model for Interferometric Synthetic Aperture Radar observations. Journal of Geophysical Research: Solid Earth, 123(10), 9202-9222.

Yu, C., Li, Z., & Penna, N. T. (2018). Interferometric synthetic aperture radar atmospheric correction using a GPS-based iterative tropospheric decomposition model. Remote Sensing of Environment, 204, 109-121.

Yu, C., Penna, N. T., & Li, Z. (2017). Generation of real‐time mode high‐resolution water vapor fields from GPS observations. Journal of Geophysical Research: Atmospheres, 122(3), 2008-2025.
