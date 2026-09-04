# Stands in for a shop's line item: whatever a shop calls its columns, GA4
# wants the same handful of names, and the ecommerce helper maps them from
# an object like this one rather than from a hash.
LineItem = Struct.new(:sku, :name, :price, :quantity, :category, keyword_init: true)
