# Difference-in-Differences Package Comparison

Benchmarking R and Python packages for **staggered DiD** with **heterogeneous treatment effects**.

## Quick Start

```bash
# 1. Setup environments
make setup-all

# 2. Activate Python environment
conda activate did_comparison

# 3. Render the book
make render

# 4. View results
open _book/index.html
```

See [SETUP.md](SETUP.md) for detailed instructions and design decisions.

## Packages Tested

| Method | R Package | Python Package |
|--------|-----------|----------------|
| Callaway & Sant'Anna | `did` | `csdid`, `diff_diff` |
| de Chaisemartin & D'Haultfoeuille | `DIDmultiplegtDYN` | `did_multiplegt_dyn` |
| Sun & Abraham | `fixest::sunab` | `pyfixest` |
| Borusyak et al. (Imputation) | `didimputation` | **Not available** |

## Simulation Design

- **1,000,000 units** across **10 time periods**
- **Staggered treatment**: 2012, 2014, 2016, 2018, or never
- **Heterogeneous effects**: Vary by cohort and time since treatment

```
Y_it = α_i + λ_t + τ_gt × D_it + ε_it

τ_gt = 1.0 + δ_g + 0.1 × (t - g)
```

## Project Structure

```
diff_diff_test/
├── SETUP.md              # Full setup guide and design decisions
├── Makefile              # Convenience commands
├── environment.yml       # Conda environment specification
├── requirements.txt      # Python pip requirements
├── install_r_packages.R  # R package installation script
├── _quarto.yml           # Quarto book configuration
├── index.qmd             # Introduction
├── data_generation.qmd   # Synthetic data generation
├── r_analysis.qmd        # R package benchmarks
├── python_analysis.qmd   # Python package benchmarks
└── comparison.qmd        # Summary comparison
```

## Make Commands

| Command | Description |
|---------|-------------|
| `make setup-all` | Setup Python and R environments |
| `make render` | Render the Quarto book |
| `make check` | Verify all packages are installed |
| `make clean` | Remove generated files |

## Results Preview

| Package | Language | Time (1M obs) | Accurate? |
|---------|----------|---------------|-----------|
| `fixest::sunab` | R | ~10s | Yes |
| `diff_diff` | Python | ~5s | Yes |
| `csdid` | Python | ~90s | Yes |
| `did` | R | ~120s | Yes |
| TWFE | Both | ~2s | **No** (biased) |

## References

- Callaway & Sant'Anna (2021). *Journal of Econometrics*
- de Chaisemartin & D'Haultfoeuille (2020). *American Economic Review*
- Sun & Abraham (2021). *Journal of Econometrics*
- Borusyak, Jaravel & Spiess (2024). *Review of Economic Studies*

## License

MIT
