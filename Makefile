# DiD Package Comparison - Makefile
# Usage: make <target>

.PHONY: help setup-python setup-r setup-all render clean

# Default target
help:
	@echo "DiD Package Comparison - Available Commands"
	@echo "============================================"
	@echo ""
	@echo "Setup:"
	@echo "  make setup-python    Create conda environment and install Python packages"
	@echo "  make setup-r         Install R packages"
	@echo "  make setup-all       Setup both Python and R environments"
	@echo ""
	@echo "Build:"
	@echo "  make render          Render the Quarto book"
	@echo "  make render-fast     Render without re-running cached code"
	@echo ""
	@echo "Clean:"
	@echo "  make clean           Remove generated files"
	@echo "  make clean-all       Remove everything including environments"
	@echo ""
	@echo "Individual chapters:"
	@echo "  make data            Render data generation chapter"
	@echo "  make r-analysis      Render R analysis chapter"
	@echo "  make python-analysis Render Python analysis chapter"
	@echo "  make comparison      Render comparison chapter"

# Setup Python environment using conda
setup-python:
	@echo "Creating conda environment..."
	conda env create -f environment.yml || conda env update -f environment.yml
	@echo ""
	@echo "Python environment 'did_comparison' created!"
	@echo "Activate with: conda activate did_comparison"

# Setup Python environment using venv (alternative)
setup-python-venv:
	@echo "Creating Python virtual environment..."
	python3 -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements.txt
	.venv/bin/python -m ipykernel install --user --name did_comparison
	@echo ""
	@echo "Python environment created!"
	@echo "Activate with: source .venv/bin/activate"

# Setup R packages
setup-r:
	@echo "Installing R packages..."
	Rscript install_r_packages.R
	@echo ""
	@echo "R packages installed!"

# Setup everything
setup-all: setup-python setup-r
	@echo ""
	@echo "============================================"
	@echo "All environments set up successfully!"
	@echo "============================================"
	@echo ""
	@echo "Next steps:"
	@echo "  1. conda activate did_comparison"
	@echo "  2. make render"
	@echo "  3. open _book/index.html"

# Render the complete book
render:
	@echo "Rendering Quarto book..."
	quarto render
	@echo ""
	@echo "Book rendered! Open _book/index.html"

# Render without re-executing code (uses cache)
render-fast:
	@echo "Rendering Quarto book (using cache)..."
	quarto render --no-execute
	@echo ""
	@echo "Book rendered! Open _book/index.html"

# Individual chapter targets
data:
	quarto render data_generation.qmd

r-analysis:
	quarto render r_analysis.qmd

python-analysis:
	quarto render python_analysis.qmd

comparison:
	quarto render comparison.qmd

# Preview (live reload)
preview:
	quarto preview

# Clean generated files
clean:
	rm -rf _book/
	rm -rf _freeze/
	rm -rf *_cache/
	rm -rf *_files/
	rm -f sim_data.rds sim_data.csv
	rm -f r_results.rds python_results.csv
	@echo "Cleaned generated files"

# Clean everything including environments
clean-all: clean
	rm -rf .venv/
	conda env remove -n did_comparison -y 2>/dev/null || true
	@echo "Cleaned all files and environments"

# Check setup
check:
	@echo "Checking setup..."
	@echo ""
	@echo "Quarto:"
	@quarto --version || echo "  NOT INSTALLED"
	@echo ""
	@echo "Python packages:"
	@python -c "import csdid; print('  csdid: OK')" 2>/dev/null || echo "  csdid: NOT INSTALLED"
	@python -c "from did_multiplegt_dyn import did_multiplegt_dyn; print('  did_multiplegt_dyn: OK')" 2>/dev/null || echo "  did_multiplegt_dyn: NOT INSTALLED"
	@python -c "import pyfixest; print('  pyfixest: OK')" 2>/dev/null || echo "  pyfixest: NOT INSTALLED"
	@echo ""
	@echo "R packages:"
	@Rscript -e "library(did); cat('  did: OK\n')" 2>/dev/null || echo "  did: NOT INSTALLED"
	@Rscript -e "library(fixest); cat('  fixest: OK\n')" 2>/dev/null || echo "  fixest: NOT INSTALLED"
	@Rscript -e "library(DIDmultiplegtDYN); cat('  DIDmultiplegtDYN: OK\n')" 2>/dev/null || echo "  DIDmultiplegtDYN: NOT INSTALLED"
	@Rscript -e "library(didimputation); cat('  didimputation: OK\n')" 2>/dev/null || echo "  didimputation: NOT INSTALLED"
