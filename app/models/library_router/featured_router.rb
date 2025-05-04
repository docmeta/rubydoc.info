module LibraryRouter
  class FeaturedRouter < YARD::Server::Router
    def docs_prefix; "docs" end
    def list_prefix; "list/docs" end
    def search_prefix; "search/docs" end
    def static_prefix; "static/docs" end
  end
end
