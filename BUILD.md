# Build Instructions

## Render the Book

```bash
make render
```

## Clean Build (Clear Cache and Re-render)

```bash
# Clear the cache
rm -rf _freeze
rm -f r_results.rds python_results.csv

# Render the book
make render
```

Or as a single command:

```bash
rm -rf _freeze && rm -f r_results.rds python_results.csv && make render
```
