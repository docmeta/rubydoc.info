class LibraryVersionSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(library_version)
    super("marshal" => Marshal.dump(library_version))
  end

  def deserialize(data)
    Marshal.load(data["marshal"])
  end

  private

  def klass
    YARD::Server::LibraryVersion
  end
end
