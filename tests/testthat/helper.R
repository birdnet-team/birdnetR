
# Check that the required versions of Python and
# the Python 'birdnet' module are installed; if not,
# either print a message for the user instructing
# them to install those, or see if we can do it
# automatically. Can use .check_birdnet_version()

# make sure birdnet Python modules are installed
devtools::load_all()
birdnetR::install_birdnet()

# Make sure reticulate uses the 'r-birdnet'
# virtual environment when running tests.
library(reticulate)
reticulate::use_virtualenv("r-birdnet", required = TRUE)
