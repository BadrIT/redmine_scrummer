module ScrumChartsHelper
  def scrummer_image_path path
    '../plugin_assets/redmine_scrummer/images/' + path
  end

  def values_sorted_by_keys(hash)
  	hash.keys.sort.map{|k| hash[k]}
  end
end
