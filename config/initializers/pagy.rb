# config/initializers/pagy.rb

# Pagy 9.x configuration
# See https://ddnexus.github.io/pagy/docs/api/pagy/

# Set default items per page
Pagy::DEFAULT[:limit] = 20

# Optional: Handle out-of-range pages gracefully
# When someone requests page 999 but there are only 10 pages, return empty results
Pagy::DEFAULT[:overflow] = :empty_page

# Optional: Set size of pagination bar
# Pagy::DEFAULT[:size] = 7

# Freeze defaults to prevent accidental changes
Pagy::DEFAULT.freeze