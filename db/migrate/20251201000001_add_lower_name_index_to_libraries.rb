class AddLowerNameIndexToLibraries < ActiveRecord::Migration[8.0]
  def change
    # Add a functional index for efficient alphabetical filtering
    # This improves the LIKE 'a%' queries used in AlphaIndexable concern
    add_index :libraries, "lower(name) varchar_pattern_ops", name: "index_libraries_on_lower_name_pattern"
  end
end
