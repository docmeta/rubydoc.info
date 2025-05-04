module LibraryRouter
  class StdlibRouter < YARD::Server::Router
    def docs_prefix; "stdlib" end
    def list_prefix; "list/stdlib" end
    def search_prefix; "search/stdlib" end
    def static_prefix; "static/stdlib" end
  end
end
