# @fixme should be able to use Object.extend(T('layout')).menu_lists but for
#        some reason it causes a crash.
def menu_lists
  [{:type => 'class', :title => 'Classes', :search_title => 'Class List'},
    {:type => 'method', :title => 'Methods', :search_title => 'Method List'},
    {:type => 'file', :title => 'Files', :search_title => 'File List'}]
end
