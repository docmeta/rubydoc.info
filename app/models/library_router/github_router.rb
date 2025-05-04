module LibraryRouter
  class GithubRouter < YARD::Server::Router
    def docs_prefix; "github" end
    def list_prefix; "list/github" end
    def search_prefix; "search/github" end
    def static_prefix; "static/github" end

    def parse_library_from_path(paths)
      library, paths = nil, paths.dup
      github_proj = paths[0, 2].join("/")
      if libs = adapter.libraries[github_proj]
        paths.shift; paths.shift
        if library = libs.find { |l| l.version == paths.first }
          request.version_supplied = true if request
          paths.shift
        else # use the last lib in the list
          request.version_supplied = false if request
          library = libs.last
        end
      end
      [ library, paths ]
    end
  end
end
